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
bClipData=false;
bKeepCell=false;	% if true, cell output also if only one channel
if nargin>1
	setoptions({'bClipData','bKeepCell'},varargin{:})
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
		Xdata=double(get(l(j),'XData'));	% double - to prevent problems with combining X and Y with integer data
		Ydata=double(get(l(j),'YData'));
		if bClipData
			B=Xdata>=xl(1)&Xdata<=xl(2);Ydata>=yl(1)&Ydata<=yl(2);
			X{i}{j}=[Xdata(B)' Ydata(B)'];
		else
			X{i}{j}=[Xdata;Ydata;Xdata>=xl(1)&Xdata<=xl(2);Ydata>=yl(1)&Ydata<=yl(2)]';
		end
	end
	if length(l)==1&&~bKeepCell
		X{i}=X{i}{1};
	end
end
if length(X)==1&&~bKeepCell
	X=X{1};
end
if nargout>1
	Xinfo=Xi;
end
