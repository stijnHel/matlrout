function [assen,lijnen,ngevonden,kols,x]=plotmat(e,kols,x,naame,de,varargin)
% PLOTMAT - plot gegevens uit matrix
%    plotmat(e,kols,x,ne,de,opties)
%        e : matrix met gegevens, 1 kolom per kanaal
%        kols : rijen met te plotten kanalen
%           (als leeg of niet gegeven : elk kanaal in een aparte grafiek)
%        x : geeft x-kanaal (of x-kanalen)
%           (als leeg of niet gegeven, eerste kolom wordt als x-kanaal beschouwd)
%        ne : geeft de namen van de kanalen
%        de : geeft de dimensies
%        opties : cell-array of aparte argumenten (paren van naam en
%             inhoud)
%          lijntype : geeft de mogelijkheid om verschillende lijntypes te gebruiken
%            1 : maakt verschillende lijn-types aan
%            string : geeft de volgorde van de lijntypes (wordt circulair doorlopen)
%                mogelijke lijntypes : - (vol), : (stippel), -- (streep), -. (punt-streep)
%                vb : '-;:;--' : eerst volle lijn, dan stippellijn, dan streeplijn
%          punttype : geeft de mogelijkheid voor punten
%            1 : verchillende punttypes
%            string : geeft de volgorde van de punten (.ox+-*)
%          fignr : nummer van te gebruiken figuur (kan ook figure-tag zijn
%               als negatief wordt de data toegevoegd.
%               zie ook bAddPlot
%          bPlotLong : use function plotlong (for faster, less memory using
%                 plots of long data), zie ook fignr
%          doyyplot : een dubbele y-as voor plots met meerdere dimensies
%                 (is default)
%          autoconf : automatische groepering van kanalen op basis van dimensie
%              0 : geen groepering,
%              1 : gelijke dimensies,
%              2 : gelijke dimensies en gelijkaardige bereiken (eenvoudig uitgevoerd)
%          cstates : namen van states (bit-data)
%          usetex : gebruik tex-interpreter of niet
%          fx   : factor for x-data
%          dx   : offset to x-data
%          bAddPlot : -1/0/1, false/true, 'all' (uses hold all, same as -1)
%                 add plots without clearing the figure
%          bXdata : calls axtick2date
%          bNavfig : calls navfig (if bXdata sets updateAxes)
%          bTNavfig : combination of bXdata and bNavfig
%         !!! ook bij doyyplot, ... moet een waarde gegeven worden (0 of 1
%            of false of true).  dit zou aangepast kunnen worden
%          bCMenu  : adds context menus to lines (if channel names are given)
%
%    [assen,LIJNEN,NGevonden,kols,x]=plotmat(...) - the same with output
%          arguments (handles to axes and lines - and others)

% !!!
% titleFig and sfTitle ---> same meaning!!!!
if nargin==0
	help plotmat
	return
end

% defaults
lijntype = [];
punttype = [];
[doyyplot] = true;
[bPlotLong] = false;
autoconf = 0;
cstates = ['bbbbbbbb';char(48:55)]';	% b0,b1,...
[usetex] = false;
[bNavFig] = false;
fignr = [];
nrij = [];
nkol = [];
fx = 1;
dx = 0;
titleFig = [];
[bAddPlot] = [];
[bPlotCarr] = true;
[bXdata] = false;
[bNavfig] = false;
[bTNavfig] = [];
[bCMenu] = false;
[bAbsTime] = false;
[bPlotEnum] = true;	% plot Simulink enum as PlotDiscrete
sfTitle = [];
[bRemoveRootName] = [];
cPathDelim = '/';
[bDefMultiChan] = false;
if nargin>5
	opties=varargin;
	if nargin==6&&iscell(opties{1})
		opties=opties{1};
	end
	setoptions({'lijntype','punttype','doyyplot','autoconf','cstates'	...
			,'fignr','usetex','nrij','nkol','fx','dx','titleFig','bPlotLong'	...
			,'bAddPlot','bPlotCarr','bXdata','bNavfig','bTNavfig'	...
			,'bCMenu','sfTitle','bAbsTime','bPlotEnum','bRemoveRootName'	...
			,'cPathDelim','bDefMultiChan'}	...
		,opties{:})
	if ~isempty(bTNavfig)
		bXdata=bTNavfig;
		bNavfig=bTNavfig;
	end
end

if ~exist('kols','var');kols=[];end
if ~exist('x','var');x=[];end
if ~exist('naame','var');naame='';end
istates=0:2:length(cstates)*2-1;
if ~exist('de','var');de='';end
if ~iscell(naame)&&~isempty(naame)
	naame=cellstr(naame);
end
if ~iscell(de)&&~isempty(de)
	de=cellstr(de);
end

specType = 0;
nChannels = size(e,2);
if iscell(e)	% call plotmat for each e,
		% supposing naame containing all data and no time(!) (and cell array!)
	K=kols;
	X=x;
	i1=1;
	options=varargin;
	out = cell(length(e),nargout);
	for i=1:length(e)
		ei=e{i};
		i2=i1+size(ei,2)-1;
		if isnumeric(kols)
			K(:)=kols(:);
			K(kols<i1|kols>i2)=0;
		end
		if i==2
			options=[varargin,'bAddPlot','all'];
		end
		if iscell(x)
			X=x{i};
		end
		if i2<=length(naame)
			Ne=naame(i1:i2);
		else
			Ne=[];
		end
		[out{i,:}] = plotmat(ei,K,X,Ne,de,options{:});
		i1=i2+1;
	end
	if nargout
		SetOut(out);
	end
	return
elseif isstruct(e)
	%!!!!!!!!!!!!!!! this needs rework !!!!!!!!!!!!!!!
	Sout=cell(1,nargout);
	S=e;
	bCommon=false;
	if isfield(S,'e')
		meetveld='e';
		bCommon=true;
	elseif isfield(S,'meting')
		meetveld='meting';
		bCommon=true;
	elseif isfield(S,'X')&&isfield(S,'Y')
		[Sout{:}]=plotmat(S.Y,kols,S.X,varargin{:});
	elseif isfield(S,'msgID')	% from MapCANDBC
		X = S.X;
		nX = {S.signals.signal};
		dX = {S.signals.unit};
		if isempty(x)
			x = S.t;
		end
		[Sout{:}]=plotmat(X,kols,x,nX,dX,varargin{:});
	elseif isfield(S,'signals')	% Simulink output
		if (nargin<3||isempty(x))&&isfield(S,'time')
			x=S.time;
		end
		X = {S.signals.values};
		Xtype = cellfun(@class,X,'uniformoutput',false);
		if all(strcmp(Xtype,Xtype{1}))
			X = [X{:}];
		else
			N = cellfun('size',X,2);
			Xarray = zeros(length(X{1}),sum(N));
			iX = 0;
			for i=1:length(X)
				Xarray(:,iX+1:iX+N(i)) = X{i};
				iX = iX+N(i);
			end
			X = Xarray;
		end
		nX=CombineSimSignals(S,'-bOnlyStateNames');
		dX=[];
		if isfield(S.signals,'unit')	% (normally not supplied)
			dX={S.signals.unit};
			if ~all(cellfun(@ischar,dX))
				dX=[];
			end
		end
		[Sout{:}]=plotmat(X,kols,x,nX,dX,varargin{:});
	elseif isfield(S,'channel')&&isfield(S,'properties')	% TDMS-channel group
		X=[S.channel.data];
		nX={S.channel.name};
		[Sout{:}]=plotmat(X,kols,x,nX,varargin{:});
	elseif length(intersect(fieldnames(S),{'group','properties','version'}))==3
		% leesTDMS-struct-output
		if length(S.group)>1
			warning('Only the first group is plotted!')
		end
		X=[S.group(1).channel.data];
		nX={S.group(1).channel.name};
		[Sout{:}]=plotmat(X,kols,x,nX,varargin{:});
	elseif isfield(S,'Data')&&isfield(S,'Time')	% (?)converted TimeSeries to struct
		[Sout{:}]=plotmat(S.Data,kols,S.Time,varargin{:});
	else
		C = struct2cell(S);
		B = cellfun(@(x) isa(x,'timeseries'),C);
		if all(B)
			TS = [C{:}];
			if isempty(kols)
				kols = (1:length(TS))';
			end
			out = cell(1,nargout);
			[out{:}] = plotmat(TS,kols,x,naame,de,varargin{:});
			if nargout
				SetOut(out)
			end
			return
		else
			error('no measurement matrix found!')
		end
	end
	if bCommon
		if isfield(S,'naam')
			naamveld='naam';
		elseif isfield(S,'ne')
			naamveld='ne';
		else
			error('no signal names found!')
		end

		%error 'not working!!!!'

		[meetveld,naamveld,dimveld]=metingvelden(S);
		e_nKan=zeros(length(S),1);
		it=isfield(S,'t');
		idt=isfield(S,'dt');
		ne=cell(length(S),1);
		[ne{:}]=subsref(S,substruct('.',naamveld));
		e=zeros(length(S),2);
		for i=1:length(S)
			e(i,:)=size(subsref(S,substruct('()',{i},'.',meetveld)));
		end
		[Sout{:}]=plotmat(e,kols,x,ne,de,varargin{:});
	end
	if nargout
		SetOut(Sout);
	end
	return
elseif isa(e,'Simulink.SimulationData.Dataset')
	if isempty(bRemoveRootName)
		bRemoveRootName = true;
	end
	specType = 1;
	nChannels = e.numElements;
	naame=cell(1,nChannels);
	for i=1:nChannels
		naame{i}=e{i}.Name;
		if isempty(naame{i})
			naame{i} = e{i}.BlockPath.getBlock(1);
		end
	end
	if isempty(kols)
		kols=(1:nChannels)';
	end		% iscell(kols)
elseif istable(e)
	naame = e.Properties.VariableNames;
	%e = table2array(e);
elseif istabular(e)
	naame = e.Properties.VariableNames;
	% does this work???
end
bXvector = length(x)>1 && length(x)==size(e,1);

if isempty(bRemoveRootName)
	bRemoveRootName = false;
end
if bRemoveRootName
	for i=1:nChannels
		s = naame{i};
		j=find(s==cPathDelim);
		if ~isempty(j)
			s=s(j(1)+1:end);
		end
		naame{i}=s;
	end
end

bXfirstColumn = false;
bXcommon = true;
if isa(e,'timeseries')
	if isempty(naame)
		naame={e.Name};
	end
	bXcommon = false;
end

if ischar(x)
	i=FindString(naame,x);
	if isempty(i)
		error('Kan geen x-kanaal vinden')
	elseif length(i)>1
		warning('PLOTMAT:multiXchannel','meer dan 1 mogelijkheid voor x-kanaal, de eerste wordt genomen')
		i=i(1);
	end
	bXfirstColumn = i==1;
	x=i;
elseif isa(x,'lvtime')
	if length(x)~=size(e,1)
		error('Wrong length of (lvtime-)timestamps!')
	end
	x = double(x);
	if isempty(bTNavfig)
		bXdata = true;
		bNavfig = true;
	end
elseif isstruct(x)
	x = timevec(x,e,bAbsTime&&isfield(x,'t0')&&~isempty(x.t0));
	bXvector=true;
elseif isscalar(x)&&(x>0)&&(x~=floor(x))
	x=-x;
elseif isempty(x)
	if isnumeric(e)
		x = 1;
		bXfirstColumn = true;
	end
elseif islogical(x) || (isnumeric(x) && all(x==0 | x==1))
	bXfirstColumn = true;
	bXcommon = true;
end
if ~ismatrix(e)
	e=squeeze(e);
	if ~ismatrix(e)
		warning('PLOTMAT:multiDim','!only two-dimensional arrays are possible, data is reduced to first element of third dimension')
		e=e(:,:,1);
	end
end
if ischar(kols)
	kols={kols};
elseif isnumeric(kols)
	if isequal(kols,0)
		kols=1:nChannels;
	elseif isequal(kols,-1)
		if bXfirstColumn
			kols = 2:nChannels;
		else
			kols = 1:nChannels;
		end
	end
end

if autoconf
	% !!!autoconf zou moeten afhangen van x-kanaal (kolom of niet)
	%   vermits dit verder gebruikt wordt, maar ondertussen kols ook werd
	%   dit nu (snelsnel) niet gedaan!!!!
	%   er wordt uitgegaan van kolom 1 voor x-data (maw kolom 1 wordt
	%     genegeerd).
	if ~isempty(kols) %#ok<UNRCH>
		warning('PLOTMAT:autoconf','bij gebruik van autoconf wordt de gegeven configuratie (kols) niet gebruikt!')
	end
	if isempty(de)
		warning('PLOTMAT:autoconfNoDim','Ik kan geen auto-configuratie doen zonder gegeven dimensies')
	else
		if ~isempty(x)&&(bXvector||all(x<0))
			iChan=1:nChannels;
		else
			iChan=2:nChannels;
		end
		deunique=unique(de(iChan));
		kols=cell(1,length(deunique));
		for i=1:length(deunique)
			kols{i}=strmatch(deunique{i},de(iChan),'exact')+iChan(1)-1;
			if autoconf>1
				bereik=[min(e(:,kols{i}));max(e(:,kols{i}))];
				bereiken=bereik(:,1)+[-1;+1]*diff(bereik(:,1))*3;
				j=2;
				% !!deze manier is volgorde afhankelijk :
				%    eerste kanaal met grote variatie, gevolgd door kleine
				%    zal kanalen samenbrengen, terwijl de omgekeerde
				%    volgorde geeft aparte grafieken
				%       toch al wat verbeterd ondertussen
				while j<=length(kols{i})
					d=diff(bereik(:,j));
					if d==0
						d=1;
					end
					d=diff(bereiken)/d;
					ok=bereik(1,j)>=bereiken(1,:)&bereik(2,j)<=bereiken(2,:)&d>.1&d<10;
					if ok(1)
						j=j+1;
					elseif any(ok)
						k=find(ok);
						k=k(1);	% voor alle zekerheid, normaal is k al lengte 1
						kols{end-(length(ok)-k)}(end+1)=kols{i}(j);
						kols{i}(j)=[];
						% ?evt aanpassen van bereiken
					else
						kols{end+1}=kols{i}(j);
						kols{i}(j)=[];
						bereiken(:,end+1)=bereik(:,j)+[-1;+1]*diff(bereik(:,j))*3;
					end
				end	% while j
			end	% autoconf>1
		end
	end
end

if ~isempty(lijntype)&&isnumeric(lijntype)&&isscalar(lijntype)&&(lijntype==1) %#ok<BDSCI>
	lijntype=['- ';': ';'-.';'--'];
elseif ischar(lijntype) && size(lijntype,1)==1 && any(lijntype==';')
	i=find(';'==[lijntype ';']);
	s=zeros(length(i),2);
	for j=1:length(i)
		s(j,i(j+1)-i(j)-1)=lijntype(i(j)+1:i(j+1)-1);
	end
	s=lijntype;
end
if ~isempty(punttype)&&(punttype==1)
	punttype='ox+-*.';
end

ngevonden=cell(0,3);
if iscell(kols)
	if min(size(kols))>1
		if isempty(nrij)
			nrij=size(kols,1);
		end
		if isempty(nkol)
			nkol=size(kols,2);
		end
		kols=kols';
		kols=kols(:);
	end
	nkolsmax=10;
	if ischar(kols{1})||iscell(kols{1})||isnumeric(kols{1})
		k=zeros(length(kols),nkolsmax);
		for i=1:length(kols)
			kolsi=kols{i};
			if ischar(kolsi)
				kolsi={kolsi};
			end
			if iscell(kolsi)
				j_k=0;
				for j=1:length(kolsi)
					kolsij=kolsi{j};
					if isempty(kolsij)
						warning('PLOTMAT:emptyChannel','???leeg gegeven voor kanaal???')
					elseif ischar(kolsij)
						if ~isempty(kolsij)&&kolsij(end)=='*'
							bMultiChan=true;
							kolsij(end)=[];
						else
							bMultiChan=false;
						end
						k1=FindString(naame,kolsij);
						if ~bMultiChan && length(k1)>1
							bMultiChan = bDefMultiChan;
						end
						if isempty(k1)
							if isempty(ngevonden)
								ngevonden{1,1}=i;
								ngevonden{1,3}={};
							elseif ngevonden{end,1}~=i
								ngevonden{end+1,1}=i; %#ok<AGROW>
								ngevonden{end,3}={};
							end
							ngevonden{end,2}(end+1)=j;
							ngevonden{end,3}{end+1}=kolsij;
						else	% found
							if length(k1)>1
								if bMultiChan
									k(i,j_k+1:j_k+length(k1))=k1;
									j_k=j_k+length(k1);
								else
									warning('PLOTMAT:multiKolsPos','meer dan 1 mogelijkheid in kols{%d,%d}, de eerste wordt genomen',i,j)
									j_k=j_k+1;
									k(i,j_k)=k1(1);
								end
							else
								j_k=j_k+1;
								k(i,j_k)=k1;
							end
						end	% found
					else	% numeric
						if length(kolsij)>1
							warning('PLOTMAT:NumChanCell','!!!bij numerieke ingave binnen cell moeten kanalen een voor een gegeven worden!!!')
						end
						j_k=j_k+1;
						k(i,j_k)=kolsij(1);
					end	% numeric
				end	% for kolsi
			elseif isnumeric(kolsi)
				k(i,1:length(kolsi))=kolsi(:)';
			else
				warning('PLOTMAT:UnknownKOLSdata','!!!onbekende data in {kols}!!!');
			end
		end
		if size(k,1)>1
			ok=sum(k)>0;
		else
			ok=k>0;
		end
		kols=k(:,ok);
	else
		error('!!!niet klaar!!!')
	end
	if isempty(kols)
		warning('No columns to plot - nothing is done!')
		if nargout
			SetOut(cell(1,nargout))
		end
		return
	end
end

X = [];
if isempty(x)
	% do nothing (x is separate for signals, and available in e (e.g. timeseries)
elseif bXvector
	X = x(:);	% not yet used (shoud replace added X)
	if fx~=1 || dx~=0
		X = double(X)*fx+dx;
	end
elseif numel(x)>numel(kols)&&~isempty(kols)&&all(kols>0)
	error('Er is iets fout met de x=as')
elseif x<=0
	if x==0
		x=1;
	else
		x=abs(x);
	end
	X = (0:size(e,1)-1)'*x;
	bXvector = true;
else
	X = e(:,x);
	if fx~=1 || dx~=0
		X = X*fx+dx;
	end
	bXcommon = all(x==x(1));
end
if isempty(kols)
	if bXfirstColumn
		kols=(2:nChannels)';
	else
		kols=(1:nChannels)';
	end
end
if size(kols,1)>64
	error('Too much graphs on one figure!')
end

xl = ~isempty(naame) && ~bXvector;
if ~isempty(de)&&length(de)==size(e,2)-1
	de=de([1:end 1]);
end

nkan=size(kols,1);
if isempty(nrij)
	if isempty(nkol)
		if nkan<4
			nrij=nkan;
			nkol=1;
		else
			nrij=ceil(nkan/2);
			nkol=2;
		end
	else
		nrij=ceil(nkan/nkol);
	end
elseif isempty(nkol)
	nkol=ceil(nkan/nrij);
end
n=nrij*nkol;
if n<nkan
	% plot in verschillende figuren
	i=0;
	out = cell(1,ceil(nkan/n));
	nOut = 0;
	while i<nkan
		nOut = nOut+1;
		[out{nOut,:}] = plotmat(e,kols(i+1:min(end,i+n)),x,naame,de,varargin{:});
		i=i+n;
	end
	if nargout
		SetOut(out)
	end
	return
end

if isempty(bAddPlot)
	bAddPlot = double(fignr)<0;
elseif ischar(bAddPlot)
	switch bAddPlot
		case 'all'
			bAddPlot=-1;
		case 'off'
			bAddPlot=false;
		case 'on'
			bAddPlot=true;
		otherwise
			error('Wrong use of plotmat - option bAddPlot')
	end
end
if isempty(fignr)
	if bAddPlot
		fignr=gcf;
	else
		%fignr=figure('Menubar','none','Papertype','a4');
		if exist('nfigure','file')
			fignr=nfigure;
		else
			fignr=figure;
		end
		if ~isempty(sfTitle)
			set(fignr,'Name',sfTitle)
		end
	end
else
	if ischar(fignr)
		fignr=getmakefig(fignr,[],[],sfTitle);
	end
	fignr=figure(abs(double(fignr)));
end
if bAddPlot
	axs=findobj(fignr,'Type','axes');
	set(axs,'NextPlot','add')
	if bAddPlot<0
		for i=1:length(axs)
			setappdata(axs(i),'PlotHoldStyle',true);
		end
	end
	fignr=abs(double(fignr));
else
	clf
end
if ischar(titleFig)
	set(fignr,'Name',titleFig)
end
if bNavFig
	navfig
end
if (nkan<4)&&(nkan>1)
	orient tall
else
	orient landscape
end
if usetex
	set(fignr,'defaulttextinterpreter','tex')
else
	set(fignr,'defaulttextinterpreter','none')
end
corder=get(fignr,'DefaultAxesColorOrder');
ass=zeros(nkan,2);
lijnen=cell(nkan,2);
nXi = [];
if bXcommon
	Xi = X;
	if istable(Xi) || istabular(Xi)
		Xi = table2array(Xi);
	end
	if xl && isscalar(x) && x>=1
		nXi = naame{x};
	end
end
for i=1:nkan
	ass(i)=subplot(nrij,nkol,i);
	k=kols(i,:);
	k(k<=0)=[];
	k(k>nChannels)=[];
	if isempty(k)
		continue
	end
	
	if ~bXcommon
		if isnumeric(X) && ~isempty(X)
			Xi = X(:,x(i));
			if istable(Xi)
				Xi = table2array(Xi);
			elseif istabular(Xi)
				Xi = Xi.Time;	%!!!!!!!??????????
			end
			if xl
				nXi = naame{x(i)};
			end
		end
	end
	k2=[];
	if ~isempty(de)
		de1=de{k(1)};
		for j=2:length(k)
			if doyyplot&&~strcmp(de1,de{k(j)})
				k2=[k2 j]; %#ok<AGROW>
			end
		end
		k3=k(k2);
		k(k2)=[];
	else
		k3=[];
	end
	xxx=[];
	if bPlotCarr&&~isempty(naame)&&length(k)==1&&naame{k}(1)=='#'
		xxx=plotcarr(e(:,k),Xi,naame{k});
	end
	if isempty(xxx)&&~isempty(k)
		if bPlotLong
			pl=plotlong(Xi,e(:,k));
		elseif isa(e,'timeseries')
			if ~isempty(x)
				Y = e(k).Data;
				if isscalar(x)
					Xi = e(x).Data;
				else
					Xi = x;
				end
				pl = plot(Xi,Y);
			elseif isscalar(k)
				pl=plot(e(k));
			else
				C=cell(2,length(k));
				C(1,:)={e(k).Time};
				C(2,:)={e(k).Data};
				pl=plot(C{:});
			end
		elseif specType==1	% simulink
			for ik=1:length(k)
				if bPlotEnum&&~isempty(enumeration(e{k(ik)}.Values.Data))
					pl_i=PlotDiscrete(e{k(ik)}.Values.Time,e{k(ik)}.Values.Data);
				else
					pl_i=plot(e{k(ik)}.Values);
				end
				if length(pl_i)>1
					if nargout>1
						warning('more than 1 line plotted at once')
					end
					pl_i = pl_i(1);
				elseif isempty(pl_i)
					warning('No line drawn?!')
					pl_i = 0;
				end
				if ik==1
					pl=pl_i;
					if length(k)==1
						% do something?
					else
						hold all
						pl(length(k))=pl_i;
					end
				else
					pl(ik)=pl_i;
				end
			end
			if length(k)>1
				hold off
			end
			xl = false;
		else
			ePlot = e(:,k);
			if istable(ePlot) || istabular(ePlot)
				ePlot = table2array(ePlot);
			end
			if isempty(Xi)
				Xi = (1:size(ePlot,1))';	% (!! starting from 1 <=> some other cases !!)
			end
			pl=plot(Xi,ePlot);
		end
		for ik=1:length(k)
			if ~isempty(naame)&&~isempty(naame{k(ik)})
				set(pl(ik),'tag',naame{k(ik)}(:)')	% making name row vector for some (strange) applications
			end
		end
		if bCMenu
			for ik=1:length(k)
				hCM=uicontextmenu('UserData',pl(ik));
				uimenu(hCM,'label',sprintf('channel #%d',k(ik))	...
					,'enable','off');
				if ~isempty(naame)&&~isempty(naame{k(ik)})
					uimenu(hCM,'label',naame{k(ik)},'Callback',@MenuCall)
					uimenu(hCM,'label',[naame{k(ik)} '-UI'],'Callback',@MenuCallUI)
				end
				set(pl(ik),'UIcontextMenu',hCM)
			end
		end
		grid on
		lijnen{i}=pl(:)';
		if ~isempty(lijntype)
			for ipl=1:length(pl)
				set(pl(ipl),'LineStyle',lijntype(1+rem(ipl-1,size(lijntype,1)),:))
			end
		end
		if ~isempty(punttype)
			for ipl=1:length(pl)
				set(pl(ipl),'Marker',punttype(1+rem(ipl-1,length(punttype))))
			end
		end
		if ~isempty(naame)
			n=[];
			kt=[k k3];
			for j=1:length(kt)
				n=[n ', ' naame{kt(j)}(:)']; %#ok<AGROW>
			end
			%title(lower(n(3:length(n))))
			title(n(3:length(n)))
			if false	% ???hoe bepalen? (vroeger vpntst...)
				set(gca,'YTick',istates,'YTickLabel',cstates)
			end
		end
		if ~isempty(de)
			de1=de{k(1)};
			if ~isempty(de1)&&de1(1)==';'
				j=find(de1==';');
				dex='';
				j(length(j)+1)=length(de1)+1;
				for j1=1:length(j)-1
					dex=addstr(dex,de1(j(j1)+1:j(j1+1)-1));
				end
				set(gca,'YTick',0:length(j)-2,'YTickLabel',dex);
			else
				if isstring(de1)
					de1 = "["+deblank(de1)+"]";
				else
					de1 = ['[' deblank(de1) ']'];
				end
				ylabel(de1)
			end
		end
	end
	if ~isempty(nXi)	% move this to creation of nXi
		if isempty(de)
			xlabel(sprintf('%s',nXi))
		elseif bXcommon
			xlabel(sprintf('%s [%s]',nXi,de{x}))
		else
			xlabel(sprintf('%s [%s]',nXi,de{x(i)}))
		end
	end
	if ~isempty(k3)
		p=get(ass(i),'Position');
%             p(3)=p(3)*0.95;
		set(ass(i),'Position',p);
		ass(i,2)=axes('Position',p  ...
			,'YAxisLocation','right'      ...
			,'Parent',fignr	...
			,'Color','none'	...
			,'XTick',[]	...
			);
		pl=line(Xi,e(:,k3));
		if ~isempty(naame)&&~isempty(naame{k3(1)})
			set(pl,'tag',naame{k3(1)})	% (!)(1) added(!?)
		end
		if bCMenu
			hCM=uicontextmenu;
			uimenu(hCM,'label',sprintf('channel #%d',k3),'enabled',false);
			if ~isempty(naame)&&~isempty(naame{k3})
				uimenu(hCM,'label',naame{k3})
			end
			set(pl,'UIcontextMenu',hCM)
		end
		lijnen{i,2}=pl(:)';
		for ipl=1:length(pl)
			set(pl(ipl),'Color',corder(1+rem(ipl-1+length(k),size(corder,1)),:))
		end
		      
		if ~isempty(lijntype)
			for ipl=1:length(pl)
				set(pl(ipl),'LineStyle',lijntype(1+rem(ipl-1+length(k),size(lijntype,1)),:))
			end
		end
		if ~isempty(punttype)
			for ipl=1:length(pl)
				set(pl(ipl)     ...
					,'Marker',punttype(1+rem(ipl-1+length(k),length(punttype)))       ...
					)
			end
		end
		de1 = de{k3(1)};
		ylabel(de1)
	end
end
if bXdata
	axtick2date
end
if bNavfig
	if bXdata
		navfig('updateAxes',@axtick2date)
	else
		navfig
	end
end

if nargout
	if all(ass(:,2)==0)
		ass=reshape([ass(:,1);zeros(nrij*nkol-size(ass,1),1)],nkol,nrij)';
		lijnen=reshape([lijnen(:,1);cell(nrij*nkol-size(lijnen,1),1)],nkol,nrij)';
	end
	assen=ass;
end

function MenuCall(h,~)
hCM=get(h,'parent');
L=get(h,'Label');
if strcmpi(get(hCM,'Type'),'uicontextmenu')
	l=get(hCM,'UserData');
	ax=get(l,'Parent');
	p=get(ax,'CurrentPoint');
	X=get(l,'XData');
	Y=get(l,'YData');
	i=findclose(p(1),X);
	fprintf('%s: (%g,%g)\n',L,X(i),Y(i))
else
	disp(L)
end

function MenuCallUI(h,~)
hCM=get(h,'parent');
L=get(h,'Label');
if strcmpi(get(hCM,'Type'),'uicontextmenu')
	l=get(hCM,'UserData');
	ax=get(l,'Parent');
	p=get(ax,'CurrentPoint');
	X=get(l,'XData');
	Y=get(l,'YData');
	i=findclose(p(1),X);
	text(p(1,1),p(1,2),sprintf('\\leftarrow %s: (%g,%g)\n',L,X(i),Y(i))	...
		,'horizontalal','left','verticalal','middle'	...
		,'color',get(l,'color'),'interpreter','tex'	...
		,'ButtonDownFcn',@delete	...
		);
end

function SetOut(out)
vOut = {'assen','lijnen','ngevonden','kols','x'};
for i=1:size(out,2)
	if size(out,1)==1
		assignin('caller',vOut{i},out{i})
	else
		assignin('caller',vOut{i},out(:,i)')
	end
end
