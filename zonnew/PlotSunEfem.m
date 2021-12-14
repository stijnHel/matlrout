function PlotSunEfem(year,pos)
%PlotSunEfem - Plot efemeride of a given year
%       PlotSunEfem(year,pos)

if nargin<2
	pos=[];
end
if nargin<1||isempty(year)
	t=clock;
	year=t(1);
end
t=calcjd(1,1,year)+(0:366)';
[H1,H2]=efemeride(t,[],pos);
B=isDST(t+0.5);	% daylight saving time in the middle of the day (and also morning/evening)
T1=H1(:,5:7)*[60;1;1/60];	% --> [minutes]
T2=H2(:,5:7)*[60;1;1/60];

f1=getmakefig('efem-variation');
plot(middlepoints(t),diff([T1 T2 T1+T2]));grid
ylabel [minutes]
title 'Variation in efemerides'
legend 'sunrise' sunset noon

T1b=T1+60+B*60;	% local time (with DST)
T2b=T2+60+B*60;
ax=plotmat([bsxfun(@plus,T1,[0 60 120]) T1b,...
		bsxfun(@plus,T2,[0 60 120]) T2b]/60,[1 2 3 4;5 6 7 8]	...
	,t,[],[],'fig','efemerides');
title(ax(1),'sunrise (UTC, UTC+1, UTC+2, belgian time)')

ax2=plotmat((T1+T2)/120+1,1,t,[],[],'fig','noon');
title 'noon (in "normal Belgian (winter) time"'

navfig('link',[f1,ancestor(ax(1),'figure'),ancestor(ax2,'figure')])
navfig X
