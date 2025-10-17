function [Dgpx,Z1,varargout]=ReadGPX(fn,varargin)
%ReadGPX  - Reads GPX format (GPS-exchange)
%   D=ReadGPX(fn)

% add option to remove "starting and ending singles"
%          (couple of points that are related to previous use, or "saving
%          time")

if isstruct(fn) && isfield(fn,'trk')
	Plot(fn)
	return
end

bPlot = nargout==0;
Z1 = [];
[bStdOut] = false;	% output arguments compatible with "lees-routines"
[bAnalyse] = false;
[bCombineTracks] = false;
if nargin>1
	[~,~,Oextra] = setoptions([2,0],{'bPlot','Z1','bStdOut','bAnalyse','bCombineTracks'}	...
		,varargin{:});
else
	Oextra = cell(2,0);
end

fn = fFullPath(fn,false,'.gpx');
Dxml=readxml(fn,false);
Dgpx=[];
for i=1:length(Dxml.children)
	if strcmpi(Dxml.children(i).tag,'gpx')
		[D1,Z1] = GetGPX(Dxml.children(i),Z1);
		if isempty(Dgpx)
			Dgpx=D1;
		else
			Dgpx(1,end+1)=D1; %#ok<AGROW>
		end
	end
end
bTrack = ~isempty(Dgpx.trk);
S = [];
if bAnalyse && bTrack
	S = CombineTracks(Dgpx.trk);
	if all(S.t==0)
		v = 10;
		S.t = datenum(2001,1,1)+S.dCum/v/86400;
		S.V = zeros(size(S.V))+v;
	end
	Dana = AnalyseGPSdata([S.t,S.coor(:,[2 1])],'Altitude',S.H,'bPlot',bPlot,Oextra{1:2,:});
	flds = fieldnames(Dana);
	for i=1:length(flds)
		Dgpx.(flds{i}) = Dana.(flds{i});
	end
elseif bPlot && bTrack
	Plot(Dgpx)
end
if bStdOut
	if bTrack
		Dgpx = [];
		varargout = cell(1,max(0,nargout-2));
		return
	end
	if isempty(S)
		S = CombineTracks(Dgpx.trk);
	end
	gegs = Dgpx;
	Dgpx = [S.t,S.coor(:,[2 1]),S.NE,S.dCum,S.H];
	gegs.Z1 = Z1;
	Z1 = {'t','latitude','longitude','north','east','dCum','H'};	% ne
	de = {'d','deg','deg','m','m','m','m'};
	e2 = S.tV;
	varargout = {de,e2,gegs};
elseif bCombineTracks
	if isempty(S)
		S = CombineTracks(Dgpx.trk);
	end
	Dgpx = S;
end

function [D,Z1] = GetGPX(Dgpx,Z1)
D=struct('trk',[],'wpt',[],'rte',[]);
for i=1:length(Dgpx.children)
	switch lower(Dgpx.children(i).tag)
		case 'trk'
			[D1,Z1] = GetTRK(Dgpx.children(i),Z1);
			D.trk=Combine(D.trk,D1);
		case 'wpt'
			D1=GetWPT(Dgpx.children(i));
			D.wpt=Combine(D.wpt,D1);
		case 'rte'
			D1=GetRTE(Dgpx.children(i));
			D.rte=Combine(D.rte,D1);
		case 'metadata'
			D.metadata=Dgpx.children(i);
		case 'extensions'
			D.extensions=Dgpx.children(i);
		otherwise
			error('Unwanted data in gpxType')
	end
end

function [D,Z1] = GetTRK(Dtrk,Z1)
D=struct('trkseg',[]);
for i=1:length(Dtrk.children)
	Dchild=Dtrk.children(i);
	switch lower(Dchild.tag)
		case 'name'
			D.name=Dchild.data;
		case 'cmt'
			D.cmt=Dchild.data;
		case 'desc'
			D.desc=Dchild.data;
		case 'src'
			D.src=Dchild.data;
		case 'link'
			if isfield(D,'link')
				D.link=Combine(D.link,Dchild);
			else
				D.link=Dchild;
			end
		case 'number'
			D.number=Dchild.data;	% convert to number?
		case 'type'
			D.type=Dchild;
		case 'extensions'
			D.extensions=Dchild;
		case 'trkseg'
			D1=GetTrkSeg(Dchild);
			D.trkseg=Combine(D.trkseg,D1);
		otherwise
			error('Unwanted data in trkType')
	end
end
if isempty(Z1)
	mx=-inf(1,2);
	mn=inf(1,2);
	for i=1:length(D.trkseg)
		mx=max(mx,max(D.trkseg(i).coor));
		mn=min(mn,min(D.trkseg(i).coor));
	end
	Z1 = (mx+mn)/2;	% middle point (of extremes)
end
for i=1:length(D.trkseg)
	D.trkseg(i).Z1 = Z1;
	[D.trkseg(i).NE,D.trkseg(i).V]=ProjGPS2XY([D.trkseg(i).t D.trkseg(i).coor(:,[2 1])]	...
		,'Z1',Z1([2,1]));
	dPt=sqrt(sum(diff(D.trkseg(i).NE).^2,2));
	D.trkseg(i).dCum=cumsum([0;dPt]);
	D.trkseg(i).dTot=sum(dPt);
end

function D=GetWPT(Dwpt)
f = Dwpt.fields';
for i=1:size(f,2)
	f{2,i} = sscanf(f{2,i},'%g');
end
D = struct(f{:});
for i=1:length(Dwpt.children)
	v = Dwpt.children(i).data;
	if iscell(v) && isscalar(v)
		v = v{1};
	end
	D.(Dwpt.children(i).tag) = v;
end

function D=GetRTE(Drte)
persistent UNKNOWN
D=struct('name',[],'desc',[],'rtept',struct('lat',cell(1,0),'lon',[]));
DrteC = Drte.children;
for i=1:length(DrteC)
	switch DrteC(i).tag
		case 'name'
			name = DrteC(i).data;
			if length(name)>1
				warning('Multiple names?!')
			end
			name = name{1};
			if ~isempty(D.name)
				if ischar(D.name)
					warning('Multiple names in route?!')
					D.name = {D.name,name};
				else
					D.name{end+1} = name;
				end
			else
				D.name = name;
			end
		case 'desc'
			desc = DrteC(i).data;
			if isscalar(name)
				desc = desc{1};
			end
			if isempty(D.desc)	% normally always
				D.desc = desc;
			else
				D.Desc = [D.desc,desc];	% OK? (will not be tested since it doesn't happen...
			end
		case 'rtept'
			f = DrteC(i).fields;
			if size(f,1)>2
				warning('more info in rtept than expected?!')
			end
			B = strcmp(f(:,1),'lat');
			if isempty(B)
				warning('No latitude in rtept?!')
				lat = NaN;
			else
				lat = sscanf(f{B,2},'%g');
			end
			B = strcmp(f(:,1),'lon');
			if isempty(B)
				warning('No longitude in rtept?!')
				lon = NaN;
			else
				lon = sscanf(f{B,2},'%g');
			end
			D.rtept(1,end+1).lat = lat;
			D.rtept(end).lon = lon;
			
			c = DrteC(i).children;
			if ~isempty(c)
				for j=1:length(c)
					if ~isempty(c(j).data)
						d = c(j).data{1};
						switch c(j).tag
							case 'ele'
								d = sscanf(d,'%g');
							case 'time'
								nd = sscanf(d,'%04d-%02d-%02dT%02d:%02d:%02d',[1 6]);
								if length(nd)<6
									warning('Error handling time (%s)',d)
								else
									d = datenum(nd);
								end
						end
						D.rtept(end).(c(j).tag) = d;
					end
				end
			end
		otherwise
			if isempty(UNKNOWN)
				bNew = true;
				UNKNOWN = {DrteC(i).tag};
			else
				bNew = ~any(strcmp(DrteC(i).tag,UNKNOWN));
				if bNew
					UNKNOWN{1,end+1} = DrteC(i).tag; %#ok<AGROW>
				end
			end
			if bNew
				warning('Unknown tag in DrteC (%s)!',DrteC(i).tag)
			end
	end
end

function D=GetTrkSeg(Dtrk)
Tchild={Dtrk.children.tag};
Btrkpt=strcmpi('trkpt',Tchild);
nTrkpt=sum(Btrkpt);
D=struct('trkpt',[]	...
	,'t',zeros(nTrkpt,1)	...
	,'coor',zeros(nTrkpt,2)	...
	,'NE',[],'V',[],'dCum',[],'dTot',[]	...
	,'H',nan(nTrkpt,1));	% temporarily
iTrkpt=0;
for i=1:length(Dtrk.children)
	Dchild=Dtrk.children(i);
	if Btrkpt
		iTrkpt=iTrkpt+1;
		C=Dchild.fields';
		D1=GetTrkPt(Dchild);
		D1.pt=struct(C{:});
		coor=[sscanf(D1.pt.lon,'%g') sscanf(D1.pt.lat,'%g')];	% !!without check for existence!!
		if iTrkpt
			D.trkpt=D1;
			D.trkpt(1,nTrkpt)=D1;
		else
			D.trkpt(iTrkpt)=D1;
		end
		D.coor(iTrkpt,:)=coor;
		if isfield(D1,'time')&&~isempty(D1.time)
			D.t(iTrkpt)=D1.time;
		end
		if isfield(D1,'ele')&&~isempty(D1.ele)
			D.H(iTrkpt)=D1.ele;
		end
	else
		switch lower(Dchild.tag)
			case 'extensions'
				if isfield(D,'extension')
					warning('Overwriting extensions!')
				end
				D.extension=Dchild;
			otherwise
				error('Unwanted data in TrkSeg')
		end
	end
end

function D=GetTrkPt(Dpt)
persistent UnknownTags
D=struct;
for i=1:length(Dpt.children)
	Dchild=Dpt.children(i);
	switch lower(Dchild.tag)
		case 'ele'
			s=Dchild.data{1};
			if iscell(s)&&~isempty(s)
				s=s{1};
			end
			D.ele=sscanf(s,'%g');
		case 'time'
			s=Dchild.data{1};
			if iscell(s)&&~isempty(s)
				s=s{1};
			end
			nD=sscanf(s,'%04d-%02d-%02dT%02d:%02d:%02d',[1 6]);
			D.time=datenum(nD);
			%D.time=datenum(s,'yyyy-mm-ddTHH:MM:SS');
		case 'extensions'
			Dchild_i = Dchild.children;
			for j=1:length(Dchild_i)
				Dchild_ij = Dchild_i(j);
				for k=1:length(Dchild_ij.children)
					d = Dchild_ij.children(k).data;
					if ~isempty(d)
						dV = str2double(d{1});
						if isnan(dV)
							dV = d{1};
						end
						D.(MakeVarNames(Dchild_ij.children(k).tag)) = dV;
					end
				end
			end
		otherwise
			if isempty(UnknownTags)
				UnknownTags = {Dchild.tag};
				bUnknown = true;
			elseif any(strcmp(UnknownTags,Dchild.tag))
				bUnknown = false;
			else
				UnknownTags{1,end+1} = Dchild.tag; %#ok<AGROW> 
				bUnknown = true;
			end
			if bUnknown
				fprintf('Unknown field in TrkPt "%s"\n',Dchild.tag)
			end
	end
end

function D=Combine(D,D1)
nD=length(D)+1;
if nD==1
	D=D1;
else
	fnD=fieldnames(D);
	fnD1=fieldnames(D1);
	if isequal(fnD,fnD1)
		D(1,nD)=D1;
	else
		for i=1:length(fnD1)
			D(nD).(fnD1{i})=D1.(fnD1{i});
		end
	end
end

function Plot(X)
ccc = get(gca,'ColorOrder');
for i=1:length(X.trk)
	col = ccc(rem(i-1,size(ccc,1))+1,:);
	trk=X.trk(i);
	for j=1:length(trk.trkseg)
		trkseg = trk.trkseg(j).NE;
		line(trkseg(:,2),trkseg(:,1),'color',col)
	end
end

function S = CombineTracks(T)
T = [T.trkseg];
if length(T)>1
	for i=1:length(T)
		if ~isnan(T(i).coor(end)) && i<length(T)
			T(i).t(end+1,1) = NaN;
			T(i).coor(end+1,:) = [NaN,NaN];
			T(i).NE(end+1,:) = [NaN,NaN];
			T(i).V(end+1,1) = NaN;
			T(i).dCum(end+1) = T(i).dCum(end);
			T(i).H(end+1,1) = NaN;
		end
		T(i).tV = [middlepoints(T(i).t),T(i).V];
	end
	flds = {'t','coor','NE','V','dCum','H','tV'};
	S = struct();
	for i=1:length(flds)
		S.(flds{i}) = cat(1,T.(flds{i}));
	end
else
	S = T;
	S.tV = [middlepoints(T.t),T.V];
end
