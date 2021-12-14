function T=ident1st(t,x,tlim)
% IDENT1ST - Identificeert een eerste orde systeem
%   ident1st(t,x,tlim)

if exist('tlim','var')&&~isempty(tlim)
	i=find(t>=tlim(1)&t<=tlim(2));
	bTlim=true;
else
	i=1:length(t);
	bTlim=false;
end

xstart=x(i(1));
tstart=t(i(1));
xend=x(i(end));

N1=5;
p1=polyfit(t(i(1:5)),x(i(1:5)),1);
T1=(xend-xstart)/p1(1);

fprintf('Eerste schatting van T = %6.3fs, en volgende ',T1)
figure
plot(t(i),x(i));grid
if bTlim
	line(tlim,[0 0]+xend,'linestyle',':')
end
line(tstart+[0 0],[xstart xend],'linestyle',':')

line(tstart+[0 T1],polyval(p1,tstart+[0 T1]),'linestyle',':','marker','o')
text(tstart,xstart,sprintf('%6.3fs',T1),'verticalal','bottom','horizontalal','left')

T=T1;
dt=T1/8;
for t1=tstart+T1/3:T1/3:tstart+T1*1.5
    j=find(t>=t1-dt&t<=t1+dt);
    p2=polyfit(t(j),x(j),1);
    x0=polyval(p2,t1);
    T(end+1)=(xend-x0)/p2(1);
    line(t1+[0 T(end)],polyval(p2,t1+[0 T(end)]),'linestyle',':','marker','o')
    text(t1,x0,sprintf('%6.3fs',T(end)),'verticalal','bottom','horizontalal','left')
end
fprintf('%6.3f,',T(2:end-1))
fprintf('%6.3f\n',T(end))
fprintf('Dit geeft een gemiddelde van %6.3fs (+/- %5.3fs)\n',mean(T),std(T))

