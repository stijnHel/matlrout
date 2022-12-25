function [Xout,nX,dX]=ReadSD800(fName,varargin)
%ReadSD800 - Read SD800-logger file (air quality logger)
%      [X,nX]=ReadSD800(fName)

[bPlot]=nargout==0;
sTitle=[];
[bSaveGraph]=[];
fGraphName=[];
[bRemoveBadDates]=true;
[startDate] = -1;
[bAddMarkers] = false;
[tOffset] = -1.5/24;

if nargin>1
	setoptions({'bPlot','sTitle','bSaveGraph','fGraphName','bRemoveBadDates'	...
		,'startDate','bAddMarkers','tOffset'},varargin{:})
end
if length(startDate)>2
	startDate = datenum(startDate);
elseif startDate<0	% 31 days ago
	startDate = now-31;
end

if isempty(zetev)||(~exist(fFullPath('CHA01',false,[],false),'dir')&&isempty(direv('CHA*.XLS')))
	zetev C:\Users\stijn.helsen\Documents\kleineProjs\AirQualityLeuven
end
if nargin>0 && ischar(fName)
	if startsWith('AddMarkers',fName)
		f = getmakefig('AirQuality',true,false);
		if isempty(f)
			error('Sorry, no figure found!!!!')
		end
		Tloc = ReadInfo();
		subp(3,1,3);
		xl = xlim;
		if Tloc{1}<xl(1) || Tloc{end,1}>xl(2)
			T = [Tloc{:,1}];
			Tloc(T<xl(1) | T>xl(2),:) = [];
		end
		for i=1:size(Tloc,1)
			line(Tloc{i}+[0 0],[200 500],'color',[1 0 0])
			text(Tloc{i}+5/86400,200,Tloc{i,2},'color',[1 0 0]	...
				,'horizontalal','left','verticalal','bottom')
		end
		return
	end
end
if exist(zetev([],'CHA01'),'dir')
	%(!)this is only tested with 1 directory!!!!
	dDir=direv('CHA*','dir');
	
	X=cell(1,length(dDir));
	for i=1:length(dDir)
		zetev(fullfile(dDir(i).folder,dDir(i).name))
		[X{i},nX,dX]=ReadSD800([],'bRemoveBadDates',bRemoveBadDates		...
			,'startDate',startDate,'tOffset',tOffset);
	end
	zetev(dDir(1).folder)
	X=cat(1,X{:});
	if bPlot
		PlotMeas(X,nX,dX,bSaveGraph,fGraphName,sTitle)
		if bAddMarkers
			ReadSD800 AddMarkers
		end
	end
	if nargout
		Xout=X;
	end
	return
elseif nargin==0||isempty(fName)
	fName=direv('CHA01*.xls');
	if ~isempty(startDate)
		B = [fName.datenum]<startDate;
		if any(B)
			fName(B) = [];
		end
	end
	l=cellfun('length',{fName.name});
	fName(l~=12)=[];
	fName=sort(fName,'name');
end
if ~ischar(fName)&&length(fName)>1
	X=cell(length(fName),3);
	cStat = cStatus('Reading files',0);
	for i=1:length(fName)
		[X{i,:}]=ReadSD800(fName(i),'bRemoveBadDates',bRemoveBadDates	...
			,'startDate',startDate,'tOffset',tOffset);
		cStat.status(i/length(fName))
	end
	cStat.close();
	nX=X{1,2};
	dX=X{1,3};
	X=cat(1,X{:,1});
	if bPlot
		PlotMeas(X,nX,dX,bSaveGraph,fGraphName,sTitle)
		if bAddMarkers
			ReadSD800 AddMarkers
		end
	end
	if nargout
		Xout=X;
	end
	return
end
cFile=cBufTextFile(fFullPath(fName));

lHead=cFile.fgetl();
w=cellfun(@strtrim,regexp(lHead,'\t','split'),'UniformOutput',false);
nX=w([1,3,4,6,8]);
nX{3}='RH';
nX{4}='Temp';
nX{5}='CO2';

l=cFile.fgetl();
w=cellfun(@strtrim,regexp(l,'\t','split'),'UniformOutput',false);
n=ceil((cFile.lFile-length(lHead)-1)/(length(l)+1));
X=zeros(n,length(nX));
X(1,:)=ReadLine(l);
dX=[{'-','days'} w(5:2:9)];

for i=2:n
	l=cFile.fgetl();
	if isempty(l)
		X=X(1:i,:);
		break
	end
	X(i,:)=ReadLine(l);
end
if bRemoveBadDates
	B=X(:,2)<datenum(2019,8,1)|X(:,2)>datenum(2029,8,1);
	if any(B)
		X(B,:)=[];
	end
end
if tOffset~=0
	X(:,2) = X(:,2)+tOffset;
end

if bPlot
	PlotMeas(X,nX,dX,bSaveGraph,fGraphName,sTitle)
end
if nargout
	Xout=X;
end

function X1=ReadLine(l)
w=regexp(l,'\t','split');
X1=zeros(1,5);
X1(1)=sscanf(w{1},'%d');
d=datenum(sscanf(w{2},'%d/%d/%d')');
t=[3600 60 1]*sscanf(w{3},'%d:%d:%d');
X1(2)=d+t/86400;
X1(3)=sscanf(w{4},'%g');
X1(4)=sscanf(w{6},'%g');
X1(5)=sscanf(w{8},'%g');

function PlotMeas(X,nX,~,bSaveGraph,fGraphName,sTitle)
B=X(:,2)>datenum(2019,8,1);
f = getmakefig('AirQuality');
nX{5}='CO_2';
X([false(size(X,1),2),X(:,3:5)==0])=NaN;
for i=1:3
	subp(3,1,i)
	plot(X(B,2),X(B,i+2));grid
	title(nX{i+2})
end
navfig
navfig(char('D'-64))
if ~isempty(sTitle)
	subp(3,1,0,sTitle)
end
setappdata(f,'AirQual',var2struct(X,nX))

if bSaveGraph
	if isempty(fGraphName)
		dtLast=X(end,2);
		tLast=(dtLast-floor(dtLast))*24;
		if tLast<9
			dtLast=dtLast-1;
		end
		d=datevec(dtLast);
		fGraphName=sprintf('AirQuality_%2d%02d%02d.png',d(1:3));
	end
	xl=floor(dtLast)+[7 18]/24;
	xl(2)=min(xl(2),X(end,2));
	bepfig(xl)
	savefigr(zetev([],fGraphName),[20 30],'-bcrop')
end

function L = ReadInfo()
cF = cBufTextFile(fFullPath('info.txt'));
LT = cF.fgetlN(10000);
L = cell(length(LT),2);
nL = 0;
for i=1:length(LT)
	l = LT{i};
	if contains(l,'-->')
		k = strfind(l,'-->');
		if k>10
			w = regexp(l(1:k-1),' *','split');
			nd = sscanf(w{2},'%d/%d/%d',[1 3]);
			nt = sscanf(w{3},'%d:%d',[1 2]);
			if length(nd)==3&&length(nt)==2
				if nd(3)<100
					nd(3) = nd(3)+2000;
				end
				t = datenum(nd(3),nd(2),nd(1),nt(1),nt(2),0);
				nL = nL+1;
				L{nL,1} = t;
				L{nL,2} = sscanf(l(k+4:end),'%s',1);
			end
		end
	end
end
L = L(1:nL,:);
