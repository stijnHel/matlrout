function RemoveOffsetUI(varargin)
%RemoveOffsetUI - Remove offset from lines
%     RemoveOffsetUI - from current figure
%            offset recalculated for each line (visual part)
%     RemoveOffsetUI('bOneOffset',true) - only one offset (for all)
%     RemoveOffsetUI('bOnePerAxes',true) - only one offset per axes
%     RemoveOffsetUI('offset',offset) - fixed offset
%
%  everywhere: RemoveOffsetUI(h,...)
%        only works on handles h and its children

options=varargin;
h=gcf;
if nargin>0&&isnumeric(varargin{1})
	h=options{1};
	options(1)=[];
end
offset=[];
bOneOffset=false;
bOnePerAxes=false;
if ~isempty(options)
	setoptions({'offset','bOneOffset','bOnePerAxes'},options{:})
end

hL=findobj(h,'type','line');
if isempty(offset)
	if bOnePerAxes
		ax=findobj(h,'type','axes');
		if isempty(ax)
			ax=get(h,'parent');
			ax=unique([ax{:}]);
		end
		offset=ax;
		error('not ready')
	elseif bOneOffset
		error('not ready')
	end
end

for i=1:length(hL)
	x=get(hL(i),'XData');
	y=get(hL(i),'YData');
	if isempty(offset)
		ax1=get(hL(i),'parent');
		xl=get(ax1,'xlim');
		y1=y(x>=xl(1)&x<=xl(2));
		offset1=mean(y1);
	else
		%!!!!!!not OK
		offset1=offset(1);
	end
	set(hL(i),'YData',y-offset1)
end
