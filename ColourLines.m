function ColourLines(fig)
%ColourLines - Colour lines based on axes colour order
%      ColourLines(fig)	% default gcf
%      ColourLines(ax)

if nargin<1||isempty(fig)
	fig=gcf;
end
if strcmp(get(fig(1),'Type'),'figure')
	ax = GetNormalAxes(fig);
else
	ax = fig;
end
for i=1:length(ax)
	l = findobj(ax(i),'Type','line');
	l = l(end:-1:1);
	ccc = get(ax(i),'ColorOrder');
	for j=2:length(l)
		set(l(j),'Color',ccc(1+rem(j-1,size(ccc,1)),:))
	end
end
