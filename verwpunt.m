function verwpunt(f)
% VERWPUNT - Verwijdert lijnen met bepaalde lijntypes

if ~exist('f','var');f=[];end

if isempty(f)
	f=gcf;
end
if length(f)==1
	if strcmp(get(f,'type'),'figure')
		figure(f)
	end
end
l=[findobj(f,'Type','line');findobj(f,'Type','Stair')];
for i=1:length(l)
	pt=get(l(i),'Marker');
	x=get(l(i),'XData');
	if ~strcmp(pt,'none')&&~strcmp(get(l(i),'linestyle'),'none')&&length(x)>1
		set(l(i),'Marker','none')
	end
end
