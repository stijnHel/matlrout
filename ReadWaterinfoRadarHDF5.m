function [IMGs,I,Prec] = ReadWaterinfoRadarHDF5(fName,varargin)
%ReadWaterinfoRadarHDF5 - Read HDF5 file from WATERINFO.be (radar images)
%     [IMGs,I] = ReadWaterinfoRadarHDF5(fName)
%            IMGs: images with precipitation values [mm/hr]
%            I: info
%     ... ReadWaterinfoRadarHDF5('web')
%            a file is created (in current directory)
%     ... ReadWaterinfoRadarHDF5('last')
%            reads the last file on the default location
%
% Further possibilities:
%      * Keypress-functionality - see "F1"
%      * ReadWaterinfoRadarHDF5('set','pos',<position>) (name or coordinates)
%                set position (rather than user pointed)
%              ReadWaterinfoRadarHDF5 set pos (without position)
%                delete position
%      * started using cGeography, but a lot is done internally!!!

[bPlot] = nargout==0;
[bAnim] = false;
nRepeat = 3;
tPause = 0.2;
tPeriod = 3;	% for downloading data
pth = [];
pos = [];
tEnd = [];
n = [];

if ischar(fName)	% some extra possibilities - not wanting the use of setoptions
	if strcmpi(fName,'list')
		if nargin>1
			n = varargin{1};
		end
		[~,d] = DefaultPath();
		iOffset = 0;
		if ~isempty(n)
			if ischar(n)
				n = sscanf(n,'%d',1);
			end
			if isscalar(n)
				iOffset = length(d)-n;
				d = d(max(1,iOffset+1):length(d));
			else
				iOffset = n(1)-1;
				d = d(n(1):min(n(2),length(d)));
			end
		end
		if nargout==0
			for i=1:length(d)
				fprintf('%3d: %-40s - %6.1f MB - %s\n',i+iOffset,d(i).name,d(i).bytes/1048576,d(i).date)
			end
		else
			IMGs = d;
		end
		return
	elseif strcmpi(fName,'set')
		f = gcf;
		if ~strcmp(f.Tag,'WaterinfoRadarPlot')
			f = getmakefig('WaterinfoRadarPlot',false,false);
			if isempty(f)
				error('Can''t find the right figure!')
			end
		end
		D = getappdata(f,'D');
		ax = D.hI.Parent;
		switch varargin{1}
			case 'pos'
				if isscalar(varargin)
					if isappdata(ax,'Range')
						rmappdata(ax,'Range')
					end
					return
				end
				if ischar(varargin{2})
					posE = geogcoor(varargin{2});
				else
					posE = varargin{2};
				end
				if all(abs(posE)<6.28)
					posE = posE*180/pi;
				end
				if posE(1)<10 && posE(2)>40
					posE = posE([2 1]);
				end
				pos = ProjGPS2XY(posE,'Z1',D.I.Z1,'Req',D.I.projDef.a,'Rpol',D.I.projDef.b)/1000;
				Irange = round([(pos(1,2)-D.hI.XData(1))/diff(D.hI.XData)*size(D.Xs,2)+1	...
					, (pos(1,1)-D.hI.YData(1))/diff(D.hI.YData)*size(D.Xs,1)+1]);
				setappdata(ax,'Range',Irange)
				UpdateXlabel(ax)
		end
		return
	end
end

if nargin>1
	setoptions({'bPlot','bAnim','nRepeat','tPause','tPeriod','pth','pos','tEnd','nLast'},varargin{:})
end

if ischar(fName)
	if strcmpi(fName,'web')
		tNow = now;
		if ischar(tPeriod)
			if startsWith(tPeriod,'cont','IgnoreCase',true)
				[~,I] = ReadWaterinfoRadarHDF5('last','--bPlot');
				tPeriod = ceil((tNow-I.tE)*24-1);
				if isDST(tNow)
					tPeriod = tPeriod-1;
				end
				fprintf('Reading data for a period of %d hours\n',tPeriod)
			else
				error('Wrong input')
			end
		end
		if isempty(tEnd)
			tEnd = tNow;
		end
		tEnd = floor(tEnd*288-3)/288;	% previous 5 minute rounded time
		%tStart = tEnd-tPeriod/24;
		%dt = 1+isDST(tStart);
		%tStart = tStart - dt/24;
		%tVec = datevec(tStart);
		%URLformat = 'https://hydro.vmm.be/grid/kiwis/KiWIS?datasource=10&service=kisters&type=queryServices&request=getrastertimeseriesvalues&ts_path=COMP_VMM/Vlaanderen_VMM/N/5m.Cmd.Raster.O.PAC_1h_1km_cappi_adj&period=PT%dH&from=%04d-%02d-%02dT%02d:%02d:%02d.000+%02d:0000&format=hdf5';
		%          PAC: Precipitation Accumulation (?)
		%urlString = sprintf(URLformat,tPeriod,tVec,dt);
		if isDST(tEnd)
			tVec = datevec(tEnd-1/24);
		else
			tVec = datevec(tEnd);
		end
		URLformat = 'https://hydro.vmm.be/grid/kiwis/KiWIS?datasource=10&service=kisters&type=queryServices&request=getrastertimeseriesvalues&ts_path=COMP_VMM/Vlaanderen_VMM/Ni/5m.Cmd.Raster.O.SRI_1km_cappi&period=PT%dH&to=%04d-%02d-%02dT%02d:%02d:%02d&format=hdf5';
		%          DPSRI: Surface Rainfall Intensity
		urlString = sprintf(URLformat,tPeriod,tVec);
		H5 = urlbinread(urlString);
		tv = datevec(tEnd-tPeriod/24);
		%fName = sprintf('rastervalues_%04d%02d%02d_%02d%02d%02.0f.hdf5',clock);
		fName = sprintf('rastervalues_%04d%02d%02d_%02d%02d%02.0f_%02.0fhr.hdf5',tv,tPeriod);
		if isempty(pth)
			pth = DefaultPath();
		end
		fName = fullfile(pth,fName);
		fid = fopen(fName,'w');
		if fid<3
			error('Can''t open the file for writing?! (%d)',fName)
		end
		fwrite(fid,H5);
		fclose(fid);
	elseif startsWith(fName,'last','IgnoreCase',true)	...
			|| startsWith(fName,'first','IgnoreCase',true)
		bFirst = fName(1)=='f';
		[~,d] = DefaultPath();
		n = sscanf(fName(5+bFirst+(fName(5+bFirst)=='_'):end),'%d_%d',[1 2]);
		if isempty(n)
			n = 1;
		end
		if bFirst
			if isscalar(n)
				d = d(1:n);
			else
				d = d(n(1):n(2));
			end
		elseif isscalar(n)
			d = d(end-n+1:end);
		else
			d = d(end-max(n)+1:end-min(n));
		end
		fName = {d.name};
		fprintf('Reading:\n')
		fprintf('    %s\n',fName{:})
	end
end
if iscell(fName)
	if isscalar(fName)
		fName = fName{1};
	end
elseif isstruct(fName) && isfield(fName,'datenum')
	if isscalar(fName)
		fName = fName.name;
	else
		fName = {fName.name};
	end
end
if ~ischar(fName) && length(fName)>1
	X = cell(length(fName),2);
	t = 0;
	for i=1:length(fName)
		[X{i,:}] = ReadWaterinfoRadarHDF5(fName{i});
		if X{i,2}.t(1)<t
			B = X{i,2}.t>t;
			X{i,2}.t = X{i,2}.t(B);
			X{i} = X{i}(:,:,B);
		end
		if ~isempty(X{i,2}.t)
			t = X{i,2}.t(end);
		end
	end
	IMGs = cat(3,X{:,1});
	I = X{1,2};
	X = [X{:,2}];
	I.t = [X.t];
	if bPlot
		handles = Plot(IMGs,I);
		I.handles = handles;
	end		% if bPlot
	if nargout==0
		clear IMGs
	end
	return
end
fFull = fFullPath(fName,false,'.hdf5',false);
if isempty(fFull)
	fFull = fullfile(DefaultPath(),fName);
	if ~exist(fFull,'file')
		if ~any(fName=='.')
			fFull = [fFull,'.hdf5'];
			if ~exist(fFull,'file')
				error('File not found!')
			end
		end
	end
end
[D,Dinfo,H5]=ReadHDFdata(fFull,{'Name','data'});
nIMGs = length(D);
nrs=zeros(1,nIMGs);
for i=1:nIMGs
	Di=subsref(H5,Dinfo{i}.refToOrig(1:end-2));
	name=Di.Name;
	j=length(name);
	while name(j)>='0'&&name(j)<='9'
		j=j-1;
	end
	nrs(i)=sscanf(name(j+1:end),'%d');
	D{i}=D{i}';
end
[~,ii]=sort(nrs);
IMGs=cat(3,D{ii});

sL = {'UL','LL','LR','UR'};
sC = {'lon','lat'};
Pborder = zeros(length(sL),length(sC));
for i=1:length(sL)
	for j = 1:length(sC)
		Pborder(i,j) = h5readatt(fFull,'/where',[sL{i},'_',sC{j}]);
	end
end
Z0 = mean(Pborder);
if Z0(1)<Z0(2)
	Pborder = Pborder(:,[2 1]);	% definition was corrected (between 2022-02 and 2022-04)
end
sProjDef = h5readatt(fFull,'/where','projdef');
if iscell(sProjDef)
	sProjDef = sProjDef{1};
end
projDef = struct();

c = h5readatt(fFull,'/dataset1/what','startdate');
if iscell(c)
	c = c{1};	% (problem with old Matlab release?)
end
dS = sscanf(c,'%04d%02d%02d',[1 3]);
c = h5readatt(fFull,'/dataset1/what','starttime');
if iscell(c)
	c = c{1};	% (problem with old Matlab release?)
end
tS = sscanf(c,'%02d%02d%02d',[1 3]);
c = h5readatt(fFull,'/dataset1/what','enddate');
if iscell(c)
	c = c{1};	% (problem with old Matlab release?)
end
dE = sscanf(c,'%04d%02d%02d',[1 3]);
c = h5readatt(fFull,'/dataset1/what','endtime');
if iscell(c)
	c = c{1};	% (problem with old Matlab release?)
end
tE = sscanf(c,'%02d%02d%02d',[1 3]);
tS = datenum([dS tS]);
tE = datenum([dE tE]);
t = tS + (0:nIMGs-1)/(nIMGs-1)*(tE-tS);

i=1;
while i<length(sProjDef)
	switch sProjDef(i)
		case ' '
			while sProjDef(i)==' '
				i=i+1;
			end
		case '+'
			i1 = i+1;
			while i1<=length(sProjDef)&&sProjDef(i1)~='='&&sProjDef(i1)~=' '
				i1 = i1+1;
			end
			if i1-i<2
				warning('Something wrong with name of projection definition element?')
				break
			end
			elName = sProjDef(i+1:i1-1);
			i = i1;
			if i>length(sProjDef)||sProjDef(i)==' '	% no value
				val = [];
			elseif sProjDef(i)=='='
				i1 = i+1;
				bNr = (sProjDef(i1)>='0'&&sProjDef(i1)<='9') || any(sProjDef(i1)=='+-');
				while i1<=length(sProjDef)&&sProjDef(i1)~=' '
					bNr = (sProjDef(i1)>='0'&&sProjDef(i1)<='9') || sProjDef(i1)=='.';
					i1 = i1+1;
				end
				val = sProjDef(i+1:i1-1);
				if bNr
					val = sscanf(val,'%g');	% not completely robust!!!
				end
				i = i1;
			else
				warning('Something wrong with value of projection definition element (%s)?',elName)
				break
			end
			projDef.(elName) = val;
		otherwise
			warning('Unexpected character in projection definition!')
			break
	end
end
xScale = h5readatt(fFull,'/where','xscale');
yScale = h5readatt(fFull,'/where','yscale');
Z1 = [projDef.lat_0,projDef.lon_0];
cGEO = CreateGeography('country','Belgium','-bStoreCoors');
PborderXY = ProjGPS2XY(Pborder,'Z1',Z1,'Req',projDef.a,'Rpol',projDef.b);
[Pbel,Pother] = ReadRegion(Pborder);
PbelXY = ProjGPS2XY(Pbel(:,[2 1]),'Z1',Z1,'Req',projDef.a,'Rpol',projDef.b);
PotherXY = ProjGPS2XY(Pother(:,[2 1]),'Z1',Z1,'Req',projDef.a,'Rpol',projDef.b);

if ~isempty(pos)&&~exist('geogcoor','file')
	addstdir
end
if ischar(pos)
	pos = {pos};
end
if iscell(pos)
	nPos = length(pos);
	POS = pos;
	pos = zeros(nPos,2);
	for i=1:nPos
		p = geogcoor(POS{i})*180/pi;
		pos(i,:) = ProjGPS2XY(p([2 1]),'Z1',Z1,'Req',projDef.a,'Rpol',projDef.b);
	end
else
	nPos = size(pos,2);
end
Prec = zeros(length(ii),nPos);
if nPos
	x = (0:size(IMGs,2)-1)/size(IMGs,2)*(PborderXY(3,2)-PborderXY(2,2))+PborderXY(2,2);
	y = (0:size(IMGs,1)-1)/size(IMGs,1)*(PborderXY(2,1)-PborderXY(1,1))+PborderXY(1,1);
	for i=1:length(ii)	% (!!)niet het meest efficiente....!
		Prec(i,:) = interp2(x,y,IMGs(:,:,i),pos(:,1),pos(:,2));
	end
end

I = var2struct(projDef,Z1,cGEO,Pborder,PborderXY,xScale,yScale,Pbel,PbelXY,Pother,PotherXY	...
	,tS,tE,t);

if bPlot
	[handles,Xs] = Plot(IMGs,I);
	I.handles = handles;
	if bAnim
		for k=1:nRepeat
			for i=1:nIMGs
				Update(handles.hI,Xs,i,I)
				pause(tPause)
			end		% for i
		end		% for k
	end		% if bAnim
end		% if bPlot
if nargout==0
	clear IMGs
end

function [Pbel,Pother] = ReadRegion(Pborder)
persistent Xworld Xbel

if isempty(Xworld)
	%Xworld = ReadESRI('C:\Users\stijn.helsen\Documents\temp\gps\borders\ne_10m_admin_0_countries\ne_10m_admin_0_countries');
	Xworld = ReadWorld();
end

if isempty(Xbel)
	pth = FindFolder('borders',0,'-bAppend');
	Xbel = ReadESRI(fullfile(pth,'BEL_adm\BEL_adm2'));
end
Pbel = ReadESRI(Xbel,'getCoor','all','-bFlatten');
Prange = [min(Pborder(:,[2 1]));max(Pborder(:,[2 1]))];
CC = {'Netherlands','France','Germany','United Kingdom'};
for i=1:length(CC)
	P = ReadESRI(Xworld,'getCoor',CC{i},'-bFlatten','Plimit',Prange);
	%P = P((P(:,1)>=Prange(1)&P(:,1)<=Prange(2)&P(:,2)>=Prange(1,2)&P(:,2)<=Prange(2,2)) | isnan(P(:,1)),:);
	CC{i} = P;
end
Pother = cat(1,CC{:});

function [handles,Xs] = Plot(X,I)
[f,bN] = getmakefig('WaterinfoRadarPlot');
if bN
	set(f,'KeyPressFcn',@KeyPressed)
end
hCountry = plot(I.PotherXY(:,2)/1000,I.PotherXY(:,1)/1000,'--k'	...
	,I.PbelXY(:,2)/1000,I.PbelXY(:,1)/1000,'-b');grid
set(hCountry(2),'LineWidth',2)
Xs=X;
Xs(X<=0)=NaN;
hold on
Xs(X>0)=log(X(X>0));
hI = imagesc(I.PborderXY([2,3],2)/1000,I.PborderXY([1 2],1)/1000,Xs(:,:,1)	...
	,'ButtonDownFcn',@PtClicked		...
	);
hold off
if all(isnan(X(:)))
	xlabel('No rain in this period?!')
else
	cLim = [min(Xs(:)),max(Xs(:))];
	set(gca,'CLim',cLim)
	axis equal
	pLim = exp(cLim);
	rPrange = pLim(2)/pLim(1);
	pMin = 10^ceil(log10(pLim(1)));
	pMax = 10^floor(log10(pLim(2)));
	if rPrange>1e5	% possible?
		cTicks = pMin*10.^(0:round(log10(pMax)-log10(pMin)));
	else	% normal case
		if pMin/5>=pLim(1)
			pMin = pMin/5;
			cStart = pMin*[0.2 0.5];
		elseif pMin/2>=pLim(1)
			pMin = pMin/2;
			cStart = pMin/2;
		else
			cStart = [];
		end
		if pMax*5<=pLim(2)
			cEnd = pMax*[2 5];
		elseif pMax*2<=pLim(2)
			cEnd = pMax*2;
		else
			cEnd = [];
		end
		cTicks = [cStart,reshape([1;2;5].*pMin.*10.^(0:round(log10(pMax)-log10(pMin))-1),1,[]),pMax,cEnd];
	end
	sTicks = cell(1,length(cTicks));
	for i=1:length(cTicks)
		if cTicks(i)>=1e-2&&cTicks(i)<1
			sTicks{i} = sprintf('%6.2f mm/hr',cTicks(i));
		elseif cTicks(i)>=1e-2&&cTicks(i)<1000
			sTicks{i} = sprintf('%1.0f mm/hr',cTicks(i));
		else
			sTicks{i} = sprintf('%5.0e mm/hr',cTicks(i));
		end
	end
	colorbar('Ticks',log(cTicks),'TickLabels',sTicks);
end
handles = var2struct(hI,hCountry);
I.handles = handles;
D = var2struct(hI,hCountry,Xs,X,I);
setappdata(f,'D',D)
Update(hI,Xs,1,I)

function [Irange,name] = GetRange(ax)
Range = getappdata(ax,'Range');
name = [];
if isnumeric(Range)
	Irange = Range;
elseif isstruct(Range)
	Irange = Range.Irange;
	name = Range.name;
else
	Irange = [];
end

function KeyPressed(f,ev)
D = getappdata(f,'D');
nr = getappdata(f,'nr');
ax = D.hI.Parent;
bUpdate = false;
switch ev.Character
	case {' ','n'}
		nr = nr+1;
		bUpdate = nr<=size(D.Xs,3);
	case {'N','p'}
		nr = nr-1;
		bUpdate = nr>=1;
	case '0'
		nr = 1;
		bUpdate = true;
	case '9'
		nr = size(D.Xs,3);
		bUpdate = true;
	otherwise
		switch ev.Key
			case 'leftarrow'
				nr = nr-1;
				bUpdate = nr>0;
			case 'rightarrow'
				nr = nr+1;
				bUpdate = nr<=size(D.Xs,3);
			case 'uparrow'
				if nr>1
					bUpdate = true;
					nr = max(1,nr-10);
				end
			case 'downarrow'
				if nr<size(D.Xs,3)
					bUpdate = true;
					nr = min(size(D.Xs,3),nr+10);
				end
			case 'home'
				nr = 1;
				bUpdate = true;
			case 'end'
				nr = size(D.Xs,3);
				bUpdate = true;
			case 'f1'
				helpS=['Rainfall-plot commands:',newline,	...
					'"<-", "->" : previous/next frame (also ("p","n")/"n"',newline,	...
					'"up", "down" : steps of 10 frames (previous/next)',newline,	...
					'"home" : first frame (also "0")',newline,	...
					'"end" : last frame (also "9")',newline,	...
					'"C" : Clear position',newline,	...
					'"P" : Plot rain rate of last selected point',newline,	...
					'"Q" : Select a range (for calculating averaged rainfall)',newline,	...
					'"S" : Show/hide current position / position range',newline,	...
					'"f1" : this help window',newline,	...
					];
				helpdlg(helpS,'ReadWaterinfoRadar-help')
			otherwise
				if ~isempty(ev.Character)
					switch ev.Character
						case 'P'
							PlotTime(ax,D)
						case 'C'	% clear position
							ReadWaterinfoRadarHDF5 set pos
						case 'Q'
							range = GetBox(ax);
							if ~isempty(range)
								Irange = round([(range(1:2)-D.hI.XData(1))/diff(D.hI.XData)*size(D.Xs,2)+1;	...
									(range([4 3])-D.hI.YData(1))/diff(D.hI.YData)*size(D.Xs,1)+1]);
								setappdata(ax,'Range',Irange);
							end
							PlotTime(ax,D)
						case 'S'
							h = findobj(ax,'Tag','range');
							if isempty(h)
								[Irange,name] = GetRange(ax);
								if isempty(Irange)
									% do nothing
								elseif isvector(Irange)
									range = [D.hI.XData(1)+(Irange(1)-1)*diff(D.hI.XData)/size(D.Xs,2);	...
										D.hI.YData(1)+(Irange(2)-1)*diff(D.hI.YData)/size(D.Xs,1)];
									line(range(1),range(2),'Marker','x','Tag','range')
								else
									range = [D.hI.XData(1)+(Irange(1,:)-1)*diff(D.hI.XData)/size(D.Xs,2);	...
										D.hI.YData(1)+(Irange(2,:)-1)*diff(D.hI.YData)/size(D.Xs,1)];
									line(range(1,[1 2 2 1 1]),range(2,[1 1 2 2 1]),'linewidth',2,'Tag','range')
								end
								if ~isempty(name)
									xlabel(name)
								end
							else
								delete(h)
							end
					end
				end
		end
end
if bUpdate
	Update(D.hI,D.Xs,nr,D.I)
end

function Update(hI,X,nr,I)
set(hI,'cdata',X(:,:,nr),'AlphaData',~isnan(X(:,:,nr))*0.6)
t = I.t(nr);
if isDST(t)
	t = t+1/12;	% add 2 hours
else
	t = t+1/24;
end
ax = ancestor(hI,'axes');
set(get(ax,'Title'),'String',sprintf('%s (%d/%d)',datestr(t),nr,size(X,3)))
UpdateXlabel(ax,X(:,:,nr))
setappdata(ancestor(hI,'figure'),'nr',nr)

function UpdateXlabel(ax,X)
f = ax.Parent;
D = getappdata(f,'D');
nr = getappdata(f,'nr');
if nargin<2 || isempty(X)
	X = D.X(:,:,nr);
end
Irange = GetRange(ax);
v = [];
if isempty(Irange)
	pt = ax.CurrentPoint;
	if pt(1)>=ax.XLim(1)
		Irange = round([(pt(1,1)-D.hI.XData(1))/diff(D.hI.XData)*size(D.Xs,2)+1	...
			, (pt(1,2)-D.hI.YData(1))/diff(D.hI.YData)*size(D.Xs,1)+1]);
	end
end
if isvector(Irange)
	ix = Irange(1);
	iy = Irange(1,2);
	if ix<1 || iy<1 || ix>size(D.Xs,2) || iy>size(D.Xs,1)
		return
	end
	v = exp(D.Xs(iy,ix,nr));
	v(isnan(v)) = 0;
elseif length(Irange)>1
	ix = Irange(1,1):Irange(1,2);
	iy = Irange(2,1):Irange(2,2);
	v = exp(D.Xs(iy,ix,nr));
	v(isnan(v)) = 0;
	v = mean(v,'all');
end
if isempty(v)
	ax.XLabel.String = sprintf('max %8.3f mm/hr',exp(max(X,[],'all')));
else
	ax.XLabel.String = sprintf('%8.3f mm/hr (max %8.3f mm/hr)',v,exp(max(X,[],'all')));
end

function PlotTime(ax,D)
[Irange,name] = GetRange(ax);
R = [];
if isempty(Irange)
	pt = ax.CurrentPoint;
	if pt(1)>=ax.XLim(1)
		Irange = round([(pt(1,1)-D.hI.XData(1))/diff(D.hI.XData)*size(D.Xs,2)+1	...
			, (pt(1,2)-D.hI.YData(1))/diff(D.hI.YData)*size(D.Xs,1)+1]);
	end
end
if isvector(Irange)	&& all(Irange>=1)	...
		&& Irange(1)<=size(D.Xs,2) && Irange(2)<=size(D.Xs,1)
	ix = Irange(1);
	iy = Irange(1,2);
	if ix<1 || iy<1 || ix>size(D.Xs,2) || iy>size(D.Xs,1)
		warning('Point out of range! (%d,%d)',ix,iy)
		return
	end
	R = squeeze(exp(D.Xs(iy,ix,:)));
	R(isnan(R)) = 0;
elseif length(Irange)>1
	ix = Irange(1,1):Irange(1,2);
	iy = Irange(2,1):Irange(2,2);
	R = D.Xs(iy,ix,:);
	R = squeeze(mean(mean(exp(R),1),2));
	R(isnan(R)) = 0;
else
	return
end
CR = cumsum([0,middlepoints(R(:)').*min(0.01,diff(D.I.t))*24]);
[~,bN] = getmakefig('RRate');
subplot 211
plot(D.I.t,R);grid
title 'rain rate'
ylabel [mm/hr]
subplot 212
plot(D.I.t,CR);grid
title 'cumulative amount'
if ~isempty(name)
	xlabel(name)
end
ylabel [mm]
if bN
	navfig
	navfig(char(4))
end
navfig X

function [pth,d] = DefaultPath()
pth = fileparts(fileparts(which(mfilename)));
pth1 = fullfile(pth,'weer');
if exist(pth1,'dir')
	pth = pth1;
end
if nargout>1
	d = dir(fullfile(pth,'*.hdf5'));
	%[~,ii] = sort([d.datenum]);
	[~,ii] = sort({d.name});
	d = d(ii);
end

function range = GetBox(ax)
f = ax.Parent;
xlabel(ax,'Give range')
ptr = get(f,'Pointer');
f.Pointer = 'crosshair';
ud = ax.UserData;
ax.UserData = 'box';
k = waitforbuttonpress;
if k
	range = [];
else
	pt1=get(ax,'CurrentPoint');
	rbbox;
	set(f,'Pointer',ptr)
	drawnow		% does this help for updating the position?  It seems to be.
	pt2=get(ax,'CurrentPoint');
	xMin=min(pt1(1),pt2(1));
	xMax=max(pt1(1),pt2(1));
	yMin=min(pt1(1,2),pt2(1,2));
	yMax=max(pt1(1,2),pt2(1,2));
	range = [xMin,xMax,yMin,yMax];
end
xlabel(ax,'')
ax.UserData = ud;

function PtClicked(h,ev)
ax = ancestor(h,'axes');
if ischar(ax.UserData)
	return	% neglect point
end
f = ancestor(ax,'figure');
D = getappdata(f,'D');
pt = ev.IntersectionPoint;
p = ProjGPS2XY(pt([2 1])*1000,'Z1',D.I.Z1,'-bInverse');
[name,cntry] = D.I.cGEO.FindCommunity(p);
Irange = round([(pt(1)-D.hI.XData(1))/diff(D.hI.XData)*size(D.Xs,2)+1	...
	, (pt(2)-D.hI.YData(1))/diff(D.hI.YData)*size(D.Xs,1)+1]);
if isempty(name)
	Range = Irange;
else
	Range = struct('name',name,'country',cntry,'pt',pt,'pGeo',p,'Irange',Irange);
end
setappdata(ax,'Range',Range)
PlotTime(ax,D)
