function PtInLineSelector(h,varargin)
%PtInLineSelector - Point on a line selector
%     PtInLineSelector(h)

if nargin==0 || isempty(h)
	h = findobj(gca,'Type','line');
	if isempty(h)
		h = findobj(gca,'Type','image');
		if isempty(h)
			error('No object found in current axes')
		else
			warning('No line found.  An image is found, but that''s not implemented.')
			return
		end
	end
end
set(h,'ButtonDownFcn',@LineClicked)

function LineClicked(h,ev)
pt = get(gca,'CurrentPoint');
ax = ancestor(h,'axes');
ar = ax.DataAspectRatio;
z = pt(1)/ar(1) + 1i*pt(1,2)/ar(2);
Z = h.XData/ar(1)+1i/ar(2)*h.YData;
[~,iMin] = min(abs(Z-z));
tg = h.Tag;
if isempty(tg)
	s = '';
else
	s = sprintf(' ("%s")',tg);
end
fprintf('Point clicked%s: #%d (%g,%g)\n',s,iMin,h.XData(iMin),h.YData(iMin))
