function figsOut=PlotNavMSRS(varargin)
%PlotNavMSRS - Plot linked images and plots
%    figs=PlotNavMSRS({..},...)
%           {..}:
%               {X,Y,Z,idx} - image, with Z a 3D matrix where idx points to
%                    the index being run through via navigation
%                        --> imagesc(X,Y,squeeze(Z(:,<i>,:))) if idx=2
%               {X,Z,idx} - a line
%  optional
%               {<figTitle>,...} - gives the figure name
%               {@fun,...} - applies function to the data

bTimeXax=false;

i=1;
while i<=nargin
	if iscell(varargin{i})
		nData=i;
	else
		break;
	end
	i=i+1;
end
DATA=varargin(1:nData);
if nData<nargin
	setoptions({'bTimeXax'},varargin{nData+1:end})
end

figs=zeros(1,nData);
hLines=zeros(1,nData);
hTitles=zeros(1,nData);
nDataSets=0;
for i=1:nData
	Ci=DATA{i};
	figTitle=[];
	dataFcn=[];
	while true
		if ischar(Ci{1})
			figTitle=Ci{1};
			Ci(1)=[];
		elseif isa(Ci{1},'function_handle')
			dataFcn=Ci{1};
			Ci(1)=[];
		else
			break
		end
	end		% optional inputs
	figs(i)=getmakefig(sprintf('NAVMSRS%02d',i),[],[],figTitle);
	idx=Ci{end};
	setappdata(figs(i),'dataFcn',dataFcn)
	if ~isscalar(idx)||~isnumeric(idx)
		error('An index to indicate the datasets must be given!')
	end
	
	Z=Ci{end-1};
	nDataS1=size(Z,idx);
	if i==1
		nDataSets=nDataS1;
	elseif nDataSets~=nDataS1
		error('Number of datasets doesn''t match (1: %d, %d: %d)!'	...
			,nDataSets,i,nDataS1)
	end
	if length(Ci)==3	% line
		iType=1;
		hLines(i)=plot(Ci{1},Ci{1});grid
	elseif length(Ci)==4	% image
		iType=2;
		hLines(i)=imagesc(Ci{1},Ci{2},zeros(length(Ci{2}),length(Ci{1})));grid
		axis xy
	else
		error('Wrong input #%d',i)
	end
	setappdata(figs(i),'type',iType)
	hTitles(i)=get(get(hLines(i),'parent'),'title');
	setappdata(figs(i),'mainFig',figs(1))
	setappdata(figs(i),'figData',Ci)
	navfig
	if bTimeXax
		navfig(char(4))	% do the same as pressing ctrl-D
	end
	navfig('addkey','[',0,@(f,~) Update(f,-1))
	navfig('addkey',']',0,@(f,~) Update(f,+1))
end

navfig('link',figs)
navfig X
setappdata(figs(1),'commonData'	...
	,struct('lines',hLines,'titles',hTitles,'nData',nDataSets))
setappdata(figs(1),'nr',1)
Update(figs(1))
if nargout
	figsOut=figs;
end

function Update(f,dNr)
f=ancestor(f,'figure');
fMain=getappdata(f,'mainFig');
CD=getappdata(fMain,'commonData');
nr=getappdata(fMain,'nr');

if nargin>1
	nr=nr+dNr;
	if nr<=0
		nr=CD.nData;
	elseif nr>CD.nData
		nr=1;
	end
	setappdata(fMain,'nr',nr)
end

for i=1:length(CD.lines)
	f=ancestor(CD.lines(i),'figure');
	iType=getappdata(f,'type');
	Ci=getappdata(f,'figData');
	idx=Ci{end};
	Z=Ci{end-1};
	C={':'};
	C=C(1,ones(1,ndims(Z)));
	C{idx}=nr;
	Sref=struct('type','()','subs',{C});
	Z1=squeeze(subsref(Z,Sref));
	dataFcn=getappdata(f,'dataFcn');
	if ~isempty(dataFcn)
		Z1=dataFcn(Z1);
	end
	switch iType
		case 1
			set(CD.lines(i),'ydata',Z1);
		case 2
			set(CD.lines(i),'cdata',Z1);
	end
end
set(CD.titles,'string',sprintf('#%d/%d',nr,CD.nData))
