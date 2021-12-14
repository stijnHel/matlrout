function [L,offsets]=ResetGraphLines(h)
%ResetGraphLines - Reset lines in graphs
%    [L,offsets]=ResetGraphLines(h)
%        h: figure(s), axes, lines
%
%   Add offset to lines to put first shown point to zero

if nargin==0||isempty(h)
	h=gcf;
end

L=findobj(h,'Type','line');
offsets=nan(1,length(L));
for i=1:length(L)
	xl=xlim(get(L(i),'Parent'));
	X=get(L(i),'XData');
	Y=get(L(i),'YData');
	i1=find(X>=xl(1),1);
	if ~isempty(i1)&&X(i1)<xl(2)
		offsets(i)=Y(i1);
		set(L(i),'YData',Y-Y(i1))
	end
end
