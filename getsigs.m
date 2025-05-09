function [X,Xinfo]=getsigs(graphs,varargin)
%getsigs  - Get signals from graphs
%
%   [X,Xinfo]=getsigs(graphs,varargin)
%
%      X --> [<X-data> <Y-data> <X in lim> <Y in lim>]
%
%   see also getplotdata

if nargin==0||isempty(graphs)
	graphs=gcf;
end
[bClipData] = false;
[bKeepCell] = false;	% if true, cell output also if only one channel
[bRemoveHiddenPoints] = false;
[bCombine] = false;
if nargin>1
	setoptions({'bClipData','bKeepCell','bRemoveHiddenPoints','bCombine'},varargin{:})
end
if bRemoveHiddenPoints && ~bClipData
	warning('bRemoveHiddenPoints only works if bClipData!')
	bRemoveHiddenPoints = false;
end

if strcmp(get(graphs(1),'type'),'figure')
	graphs=findobj(graphs,'Type','axes');
end

X=cell(size(graphs));
Xi=struct('lines',X,'axes',[],'fig',[],'pos',[],'xlim',[],'ylim',[]);
for i=1:numel(graphs)
	l=[findobj(graphs(i),'Type','line','Visible','on');
		findobj(graphs(i),'Type','patch','Visible','on');
		findobj(graphs(i),'Type','stair','Visible','on')];
	xl=get(graphs(i),'XLim');
	yl=get(graphs(i),'yLim');
	Xi(i)=struct('lines',l,'axes',graphs(i),'fig',get(graphs(i),'Parent')	...
		,'pos',get(graphs(i),'Position'),'xlim',xl,'ylim',yl);
	if i==1&&numel(graphs)>1
		Xi(size(graphs,1),size(graphs,2)).axes=[];
	end
	X{i}=cell(1,length(l));
	for j=1:length(l)
		Xdata=get(l(j),'XData');
		Ydata=get(l(j),'YData');
		if isinteger(Xdata)
			Xdata=double(Xdata);	% double - to prevent problems with combining X and Y with integer data
		end
		if isinteger(Ydata)
			Ydata=double(Ydata);
		end
		B=Xdata>=xl(1)&Xdata<=xl(2) & Ydata>=yl(1)&Ydata<=yl(2);
		if ~bClipData
			if strcmp(class(Xdata),class(Ydata))
				X{i}{j}=[Xdata;Ydata;Xdata>=xl(1)&Xdata<=xl(2);Ydata>=yl(1)&Ydata<=yl(2)]';
			else
				X{i}{j}={Xdata(:),Ydata(:),Xdata(:)>=xl(1)&Xdata(:)<=xl(2),Ydata(:)>=yl(1)&Ydata(:)<=yl(2)};
			end
		end
		if isprop(l(j),'BrushData') && any(l(j).BrushData) && ~all(l(j).BrushData)
			X{i}{j}(1:length(l(j).BrushData),end+1) = l(j).BrushData(:)>0;
		end
		if isprop(l(j),'MarkerIndicesMode')		...
				&& length(l(j).MarkerIndices)<length(Xdata)
			if bRemoveHiddenPoints
				B1 = false(size(B));
				B1(l(j).MarkerIndices) = true;
				B = B&B1;
			else
				X{i}{j}(l(j).MarkerIndices,end+1) = 1;
			end
		end		% if MarkerIndices
		if bClipData
			if strcmp(class(Xdata),class(Ydata))
				X{i}{j} = [Xdata(B)' Ydata(B)'];
			else
				X{i}{j} = {Xdata(B)',Ydata(B)'};
			end
		end
	end		% for i
	if length(l)==1&&~bKeepCell
		X{i}=X{i}{1};
	end
end
if length(X)==1 && ~bKeepCell
	X=X{1};
end
if bCombine
	N = cellfun('length',X);
	if isscalar(X)
		X = X{1};
	elseif all(N==N(1))
		X0 = cellfun(@(x) x(1),X);
		Xe = cellfun(@(x) x(end,1),X);
		if all(X0==X0(1) & Xe==Xe(1))
			X1 = X{1};
			X1(1,end+length(X)-1) = X1(1);	% enlarge
			for i=2:length(X)
				X1(:,3+i) = X{i}(:,2);
			end
			X = X1;
		else
			warning('Not the same X-data?!')
		end
	else
		warning('Not all signals the same length!')
	end
end
Xinfo=Xi;
