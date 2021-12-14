function ChangeUIData(h,func,data)
%ChangeUIData - Change data in UI-elements
%      ChangeUIData(h,func,data)
%           h: handle(s)
%           func: function handle used to change the data
%           data: property of UI-element to change (default 'YData')
%  example:
%     ChangeUIData(gcf,@(x) x*10);
%              multiply all ydata in a figure with 10

if isscalar(h)
	if strcmp(get(h,'type'),'figure')
		h=GetNormalAxes(h);
	end
	h=findobj(h,'Type','line');
end
if nargin<3||isempty(data)
	data='YData';
end
for hi=h(:)'
	set(hi,data,func(get(hi,data)))
end
