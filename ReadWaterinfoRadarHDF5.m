function [IMGs,I,Prec] = ReadWaterinfoRadarHDF5(fName,varargin)
%ReadWaterinfoRadarHDF5 - Read HDF5 file from WATERINFO.be (radar images)
%     [IMGs,I] = ReadWaterinfoRadarHDF5(fName)
%            IMGs: images with precipitation values [mm/hr]
%            I: info
%     ... ReadWaterinfoRadarHDF5('web')
%            a file is created (in current directory)
%     ... ReadWaterinfoRadarHDF5('last')
%            reads the last file on the default location

[bPlot] = nargout==0;
[bAnim] = false;
nRepeat = 3;
tPause = 0.2;
tPeriod = 3;	% for downloading data
pth = [];
pos = [];
if nargin>1
	setoptions({'bPlot','bAnim','nRepeat','tPause','tPeriod','pth','pos'},varargin{:})
end

if ischar(fName)&&strcmpi(fName,'web')
	fName = sprintf('rastervalues_%04d%02d%02d_%02d%02d%02.0f.hdf5',clock);
	if isempty(pth)
		pth = DefaultPath();
	end
	fName = fullfile(pth,fName);
	tEnd = now;
	tEnd = floor(tEnd*288-3)/288;	% previous 5 minute rounded time
	%tStart = tEnd-tPeriod/24;
	%dt = 1+isDST(tStart);
	%tStart = tStart - dt/24;
	%tVec = datevec(tStart);
	%URLformat = 'https://hydro.vmm.be/grid/kiwis/KiWIS?datasource=10&service=kisters&type=queryServices&request=getrastertimeseriesvalues&ts_path=COMP_VMM/Vlaanderen_VMM/N/5m.Cmd.Raster.O.PAC_1h_1km_cappi_adj&period=PT%dH&from=%04d-%02d-%02dT%02d:%02d:%02d.000+%02d:0000&format=hdf5';
	%          PAC: Precipitation Accumulation (?)
	%urlString = sprintf(URLformat,tPeriod,tVec,dt);
	tVec = datevec(tEnd);
	URLformat = 'https://hydro.vmm.be/grid/kiwis/KiWIS?datasource=10&service=kisters&type=queryServices&request=getrastertimeseriesvalues&ts_path=COMP_VMM/Vlaanderen_VMM/Ni/5m.Cmd.Raster.O.SRI_1km_cappi&period=PT%dH&to=%04d-%02d-%02dT%02d:%02d:%02d&format=hdf5';
	%          DPSRI: Surface Rainfall Intensity
	urlString = sprintf(URLformat,tPeriod,tVec);
	H5 = urlbinread(urlString);
	fid = fopen(fName,'w');
	if fid<3
		error('Can''t open the file for writing?! (%d)',fName)
	end
	fwrite(fid,H5);
	fclose(fid);
elseif ischar(fName)&&strcmpi(fName,'last')
	pth = DefaultPath();
	d = dir(fullfile(pth,'*.hdf5'));
	[~,iLast] = max([d.datenum]);
	fName = fullfile(pth,d(iLast).name);
end
fFull = fFullPath(fName,false,'.hdf5',false);
if isempty(fFull)
	fFull = fullfile(DefaultPath(),fName);
	if ~exist(fFull,'file')
		error('File not found!')
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
sProjDef = h5readatt(fFull,'/where','projdef');
sProjDef = sProjDef{1};
projDef = struct();

c = h5readatt(fFull,'/dataset1/what','startdate');
dS = sscanf(c{1},'%04d%02d%02d',[1 3]);
c = h5readatt(fFull,'/dataset1/what','starttime');
tS = sscanf(c{1},'%02d%02d%02d',[1 3]);
c = h5readatt(fFull,'/dataset1/what','enddate');
dE = sscanf(c{1},'%04d%02d%02d',[1 3]);
c = h5readatt(fFull,'/dataset1/what','endtime');
tE = sscanf(c{1},'%02d%02d%02d',[1 3]);
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
PborderXY = ProjGPS2XY(Pborder,'Z1',[projDef.lat_0,projDef.lon_0],'Req',projDef.a,'Rpol',projDef.b);
[Pbel,Pother] = ReadRegion(Pborder);
PbelXY = ProjGPS2XY(Pbel(:,[2 1]),'Z1',[projDef.lat_0,projDef.lon_0],'Req',projDef.a,'Rpol',projDef.b);
PotherXY = ProjGPS2XY(Pother(:,[2 1]),'Z1',[projDef.lat_0,projDef.lon_0],'Req',projDef.a,'Rpol',projDef.b);

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
		pos(i,:) = ProjGPS2XY(p([2 1]),'Z1',[projDef.lat_0,projDef.lon_0],'Req',projDef.a,'Rpol',projDef.b);
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

I = var2struct(projDef,Pborder,PborderXY,xScale,yScale,Pbel,PbelXY,Pother,PotherXY	...
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
	Xworld = ReadESRI('C:\Users\stijn.helsen\Documents\temp\gps\borders\ne_10m_admin_0_countries\ne_10m_admin_0_countries');
end

if isempty(Xbel)
	Xbel = ReadESRI('C:\Users\stijn.helsen\Documents\temp\gps\borders\BEL_adm\BEL_adm2');
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
hI = imagesc(I.PborderXY([2,3],2)/1000,I.PborderXY([1 2],1)/1000,Xs(:,:,1));
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
D = var2struct(hI,hCountry,Xs,I);
setappdata(f,'D',D)
Update(hI,Xs,1,I)

function KeyPressed(f,ev)
D = getappdata(f,'D');
nr = getappdata(f,'nr');
switch ev.Character
	case {' ','n'}
		nr = nr+1;
		bUpdate = nr<=size(D.Xs,3);
	case {'N','p'}
		nr = nr-1;
		bUpdate = nr>=1;
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
				else
					bUpdate = false;
				end
			case 'downarrow'
				if nr<size(D.Xs,3)
					bUpdate = true;
					nr = min(size(D.Xs,3),nr+10);
				else
					bUpdate = false;
				end
			otherwise
				bUpdate = false;
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
set(get(ancestor(hI,'axes'),'Title'),'String',sprintf('%s (%d/%d)',datestr(t),nr,size(X,3)))
set(get(ancestor(hI,'axes'),'XLabel'),'String',sprintf('max %8.3f mm/hr',exp(max(X(:,:,nr),[],'all'))))
setappdata(ancestor(hI,'figure'),'nr',nr)

function pth = DefaultPath()
pth = fileparts(fileparts(which(mfilename)));
pth1 = fullfile(pth,'weer');
if exist(pth1,'dir')
	pth = pth1;
end
