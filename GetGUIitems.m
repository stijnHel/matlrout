function [Dout,f]=GetGUIitems(f,varargin)
%GetGUIitems - Get items on a GUI window
%    [D,f]=GetGUIitems(f[,options])

options=varargin;
if nargin==0
	f=[];
elseif ischar(f)
	options=[{f} varargin];
	f=[];
end
dispProp={'Type','Tag','Style','String','Position','Units'	...
	,'ButtonDownFcn','KeyPressFcn','Callback','CreateFcn','DeleteFcn'	...
	};
bDisp=nargout==0;
bGiveEmpty=false;
if ~isempty(options)
	setoptions({'dispProp','bDisp','bGiveEmpty'},options{:})
	dispProp=dispProp(:)';
	if length(dispProp)~=length(unique(dispProp))
		error('Please give properties only once')
	end
	if ~strcmpi(dispProp{1},'type')
		i=find(strcmpi('type',dispProp));
		if isempty(i)
			warning('GETGUIITEMS:NoType','Type must be the first property to display - this is added!')
			dispProp=[{'Type'} dispProp];
		else
			warning('GETGUIITEMS:NoType','Type must be the first property to display - this is moved to the first!')
			dispProp=[{'Type'} dispProp(setdiff(1:length(dispProp),i))];
		end
	end
end

if isempty(f)
	cSHH=get(0,'ShowHiddenHandles');
	set(0,'ShowHiddenHandles','on')
	f=gcf;
	set(0,'ShowHiddenHandles',cSHH)
end
hChildren=get(f,'Children');
hChildren=hChildren(end:-1:1);
D=cell(2,length(hChildren));
B1=false(1,length(dispProp)+1);
D1=dispProp([1 1],:);
D1{1,end+1}='Children';
for i=1:length(hChildren)
	B1(:)=false;
	D{1,i}=hChildren(i);
	for j=1:length(dispProp)
		if isprop(hChildren(i),dispProp{j})
			D1{2,j}=get(hChildren(i),dispProp{j});
			B1(j)=bGiveEmpty||~isempty(D1{2,j});
		end
	end
	if isprop(hChildren(i),'Children')
		D1{2,end}=GetGUIitems(hChildren(i));
		B1(end)=bGiveEmpty||~isempty(D1{2,end});
	end
	D{2,i}=D1(:,B1);
end
if nargout
	Dout=D;
end
if bDisp
	DisplayChildren(D,'')
end

function DisplayChildren(D,sPre)
for i=1:size(D,2)
	D1=D{2,i};
	fprintf('%s%d (%8g): %s',sPre,i,D{1,i},D1{2})
	if strcmpi(D1{1,2},'Tag')
		fprintf(' (tag:%s)',D1{2,2})
		j1=3;
	else
		j1=2;
	end
	fprintf('\n')
	for j=j1:size(D1,2)
		fprintf('    %-15s: %s\n',D1{1,j},dispForm(D1{2,j}))
	end
	fprintf('\n')
	if strcmpi(D1{1,end},'Children')&&~isempty(D1{2,end})
		DisplayChildren(D1{2,end},['  ' sPre num2str(i) '.'])
	end
end

function s=dispForm(data)
if ischar(data)
	s=data;
elseif iscell(data)
	sD=size(data);
	s=[sprintf('cell (%d',sD(1)) sprintf('x%d',sD(2:end)) ')'];
elseif isstruct(data)
	sD=size(data);
	s=[sprintf('struct (%d',sD(1)) sprintf('x%d',sD(2:end)),...
		sprintf(' - %d fields)',length(fieldnames(data)))];
elseif isnumeric(data)
	sD=size(data);
	if isempty(data)
		s='[]';
	elseif isscalar(data)
		s=sprintf('[%g]',data);
	elseif length(data)<8&&min(sD)==1
		s=[sprintf('[%g',data(1)) sprintf(',%g',data(2:end)) ']'];
		if sD(1)>1
			s(end+1)='''';
		end
	else
		s=[sprintf('%s (%d',class(data),sD(1)) sprintf('x%d',sD(2:end)) ')'];
	end
elseif isa(data,'function_handle')
	s=char(data);
else
	sD=size(data);
	s=[sprintf('%s (%d',class(data),sD(1)) sprintf('x%d',sD(2:end)) ')'];
end
