function [D,E] = EclipsCalcs(tRange,varargin)
%EclipsCalcs - Calculations around eclipses
%      D = EclipsCalcs(tRange,...)

[bUseFminsearch] = false;
[bAll] = false;
[bPlot] = nargout==0;
if nargin<1 || isempty(tRange)
	tRange = [calcjd(1,1,2000),calcjd(1,1,2050)];
elseif ischar(tRange)
	if strcmpi(tRange,'getfunLE')
		D = @CalcDistLE;
	elseif strcmpi(tRange,'getfunSE')
		D = @CalcDistSE;
	elseif strcmpi(tRange,'getfunPlot')
		D = @Plot;
	else
		error('Wrong use of this function')
	end
	return
end
if nargin>1
	setoptions({'bUseFminsearch','bAll','bPlot'},varargin{:})
end

r_sun = 695700;		% [km]
d_moon = 1737.4;	% [km]	------> dit is straal!!!!
d_earth = 6371.0;	% [km]	------> dit is straal!!!!

%% earth and moon motions over time
dt = 0.05;
t = (tRange(1):dt:tRange(end))';
cStat = cStatus(sprintf('Calculating a lot of (too much) sun&moon positions (#%d, %.2f year)',length(t),(t(end)-t(1))/365.25));
Pa = calcvsop87('aa',t);
Pm = calclunarc(t);
Da = calcdang(Pa(:,1:2),Pm(:,1:2));
cStat.close()
if nargout>1
	E = var2struct(t,Pa,Pm,Da);
	% find perigee
	iiP = find(Pm(1:end-2,3)>Pm(2:end-1,3)&Pm(2:end-1,3)<=Pm(3:end,3))+1;
	if iiP(1)==1
		iiP(1) = [];	% to make it easy...
	end
	if iiP(end)==length(t)
		iiP(end) = [];
	end
	tP = t(iiP);
	dt1 = (-1:1)'*dt;
	for i=1:length(iiP)
		p = polyfit(dt1,Pm(iiP(i)-1:iiP(i)+1,3),2);
		tP(i) = tP(i)-p(2)/2/p(1);
	end
	E.tP = tP;
	iiDr = find(Pm(2:end,2)>=0&Pm(1:end-1,2)<0);
	E.tDr = t(iiDr)-Pm(iiDr,2)./(Pm(iiDr+1,2)-Pm(iiDr,2))*dt;
end

%% lunar eclipses
%   Very stupid calcs...
% first "raw data" - closest apparent distance between earth and moon seen
% from the sun.
ii = find(Da(1:end-2)>Da(2:end-1)&Da(2:end-1)<=Da(3:end))+1;

% now find data (not looking to minimum, but same calculation with coarser time steps

TM = zeros(length(ii),11);
TM(:,11) = t(ii);
OS = optimset('TolX',1e-5);
cStat = cStatus(sprintf('Finding %d lunar eclipses',length(ii)),0);
for i=1:length(ii)
	if bUseFminsearch
		% less accurate!!!!
		t1 = t(ii(i));
		TM(i) = fminbnd(@CalcDistLE,t1-dt,t1+dt,OS);
		[TM(i,2),TM(i,3:5),TM(i,6:8)] = CalcDistLE(TM(i));
	else
		tt = (t(ii(i)-1):1e-4:t(ii(i)+1))';
		Pa1 = calcvsop87('aa',tt);
		Pm1 = calclunarc(tt);
		Da1 = calcdang(Pa1(:,1:2),Pm1(:,1:2));
		[TM(i,2),i1] = min(Da1);
		TM(i) = tt(i1);
		TM(i,3:5) = Pa1(i1,:);
		TM(i,6:8) = Pm1(i1,:);
	end
	cStat.status(i,length(ii))
end
cStat.close()
DD = r_sun./TM(:,5)/unitcon(1,'AU','km');
B = d_earth./TM(:,8);
A = B-DD;
C = B+DD;

BB = TM(:,2)<C;	% at least partial
if bAll
	BBfull = TM(:,2)<=A;	%!!!!!! take size of moon into account!!!!
	D = var2struct(TM,DD,A,B,C,BB,BBfull);
else
	% Filter to real eclipses
	TM = TM(BB,:);
	BBfull = TM(:,2)<=A(BB);	%!!!!!! take size of moon into account!!!!
	
	TM(:,9) = BBfull;
	%TM(:,10) = min(1,(A(BB)-TM(:,2)));
	%TM(:,10) = fraction estimation
	
	D = struct('LunarEclipses',TM);
end

%% solar eclipses
ii = find(Da(1:end-2)<Da(2:end-1)&Da(2:end-1)>=Da(3:end))+1;
TS = zeros(length(ii),11);
TS(:,11) = t(ii);

cStat = cStatus(sprintf('Finding %d solar eclipses',length(ii)),0);
for i=1:length(ii)
	if bUseFminsearch
		% less accurate!!!!
		TS(i) = fminbnd(@CalcDistSE,t(ii(i))-dt,t(ii(i))+dt);
		[TS(i,2),TS(i,3:5),TS(i,6:8)] = CalcDistSE(TS(i));
	else
		tt = (t(ii(i)-1):1e-4:t(ii(i)+1))';
		Pa1 = calcvsop87('aa',tt);
		Pm1 = calclunarc(tt);
		Da1 = calcdang(Pa1(:,1:2),Pm1(:,1:2));
		[mx,i1] = max(Da1);
		TS(i,2) = pi-mx;
		TS(i) = tt(i1);
		TS(i,3:5) = Pa1(i1,:);
		TS(i,6:8) = Pm1(i1,:);
	end
	cStat.status(i,length(ii))
end
cStat.close()
DD = r_sun./TS(:,5)/unitcon(1,'AU','km');
DDe = d_earth/2./TS(:,8);
B = d_moon./TS(:,8);
A = B-DD;
C = B+DD;

if bAll
	TS(:,9) = BBfull;
	D.SolarEclipses = TS;
	D.BBfull = TS(:,2)<=A;
else
	BB = TS(:,2)<C+DDe;	% at least partial
	TS = TS(BB,:);
	BBfull = TS(:,2)<=A(BB);	%!!!!!! not
	
	TS(:,9) = BBfull;
	%TS(:,10) = min(1,(A(BB)-TS(:,2)));
	%TS(:,10) = fraction estimation
	D.SolarEclipses = TS;
end
D.E_SE = var2struct(DD,A,B,C,BB);

if bPlot
	Plot(D)
end

function [d,Pa,Pm] = CalcDistLE(t)
Pa = calcvsop87('aa',t);
Pm = calclunarc(t);
d = calcdang(Pa(1:2),Pm(1:2));

function [d,Pa,Pm] = CalcDistSE(t)
Pa = calcvsop87('aa',t);
Pm = calclunarc(t);
d = pi-calcdang(Pa(1:2),Pm(1:2));

function Plot(D)
[f1,bN1] = getmakefig('LunarEclipse');
plot(D.LunarEclipses(:,1),D.LunarEclipses(:,2)*180/pi,'o');grid
title 'maansverduisteringen'
ylabel [^o]
if bN1
	navfig
	navfig(char(4))
	navfig('X')
end

[f2,bN2] = getmakefig('SolarEclipse');
BB = D.E_SE.BB;
subplot 211
plot(D.SolarEclipses(:,1),D.SolarEclipses(:,2)*180/pi,'o');grid
title 'zonsverduisteringen - hoek-afstand middelpunten'
ylabel [^o]
subplot 212
plot(D.SolarEclipses(:,1),D.E_SE.A(BB)*180/pi,'o');grid
title 'grootte'
ylabel [^o]
xlabel '\alpha < 0 ==> ringvormige zonsverduistering'
if bN2
	navfig
	navfig(char(4))
	navfig('X')
end
if bN1 && bN2
	navfig('link',[f1,f2])
end
