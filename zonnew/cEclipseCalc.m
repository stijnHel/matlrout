classdef cEclipseCalc < handle
	% cEclipseCalc - class combining eclipse related calculations
	%    This class is made to look to a specific solar eclipse
	%           interactive visualisation of the course of an eclipse
	%			find the time(s) of an eclipse
	%
	%    It could be extended to finding eclipses (solar and lunar).
	%            see EclipsCalcs

	properties
		dMoonEq = 3476280	% [m]
		dMoonPol = 3471940	% [m]
		dMoon
		dSun = 1391400e3	% [m]
	end		% properties

	properties	% (variables)
		pos_last
		D_last
	end		% properties (variables)
	
	methods
		function c = cEclipseCalc(varargin)
			c.dMoon = (c.dMoonEq+c.dMoonPol)/2;
			if nargin
				c.CalcEclipsTime(varargin{:});
			end
		end

		function [t0JD,D] = CalcEclipsTime(c,pos,t0)
			if ischar(pos)
				pos = geogcoor(pos);
			end
			if length(t0)>=3
				t0 = calcjd(t0);
			elseif isdatetime(t0)
				t0 = juliandate(t0);
			elseif t0<500000
				error('What kind of date is this?')
			elseif t0<800000	% Matlab time
				t0 = calcjd(t0);
			elseif t0<2e6 || t0>3e6
				error('What kind of date is this?')
			end
			% find closest distance
			f = @(t) calcdang(calcposhemel(pos,t),calcposhemel(pos,t,'maan'));
			%tCentre = fminsearch(f,t0); %doesn't work (as wanted)
			tCentre = FindMinimum(f,t0);
			dCentre = f(tCentre);
			% check if day-time
			pS = calcposhemel(pos,tCentre);
			pM = calcposhemel(pos,tCentre,'maan');

			if pS(2)<0
				warning('Eclipse during the night!')
			end

			% calc sizes at time of closest distance
			Pe = calcvsop87('aarde',tCentre);	% distance sun-earth in AU
			dS = unitcon(Pe(3),'AU','m');
			Pm = calclunarc(tCentre);	% lunar distance in [km]
			dM = Pm(3)*1000;
			arS = atan(c.dSun/dS/2);	% apparent size (radius) of the sun
			arM = atan(c.dMoon/dM/2);	% apparent size (radius) of the moon
			dAngSize = arM-arS;
			bAngular = false;
			bFull = abs(dAngSize)>=dCentre;
			tFull = 0;
			tStart = tCentre;
			tEnd = tCentre;

			% check eclipse
			if bFull
				bAngular = dAngSize<0;	% moon smaller than the sun
				dt = 0.0001;
				[tStart,tEnd] = FindStartEnd(f,tCentre,dt,dCentre,abs(dAngSize));
				tFull = (tEnd-tStart)*1440;	% [minutes]
				fOverlap = 1;
			elseif arS+arM >= dCentre
				Aoverlap = AcircOverlap(arS,arM,dCentre);
				fOverlap = Aoverlap/(pi*arS^2);
				fprintf('Partial eclipse (%.1f %%)\n',fOverlap*100)
			else
				warning('No eclipse at all!')
				bFull = -1;
				fOverlap = 0;
			end

			if bFull>=0
				% find first and last contact
				dt = 0.001;
				[t1,t4] = FindStartEnd(f,tCentre,dt,dCentre,arS+arM);
				t1 = datetime(t1,'ConvertFrom','juliandate');
				t4 = datetime(t4,'ConvertFrom','juliandate');
			else
				t1 = [];
				t4 = [];
			end

			t0JD = tCentre;
			tCentre = datetime(tCentre,'ConvertFrom','juliandate');
			tStart = datetime(tStart,'ConvertFrom','juliandate');
			tEnd = datetime(tEnd,'ConvertFrom','juliandate');
			D = var2struct(pos, t0JD, tCentre,dCentre,fOverlap, pS, pM, arS, arM, Pe, Pm	...
				, tStart, tEnd, tFull, t1, t4	...
				, bFull, bAngular);

			c.pos_last = pos;
			c.D_last = D;
		end		% CalcEclipsTime

		function Plot(c,t,pos,ax)
			D = [];
			if nargin<2
				t = [];
			end
			if nargin<3
				pos = [];
			end
			if nargin<4 || isempty(ax)
				ax = gca;
			end
			if ischar(pos)
				pos = geogcoor(pos);
			elseif isempty(pos)
				D = c.D_last;
				if isempty(D)
					error('Sorry, the eclipse wasn''t calculated yet!')
				end
			end
			if isempty(D)
				% check if day-time
				pS = calcposhemel(pos,t);
				pM = calcposhemel(pos,t,'maan');
	
				if pS(2)<0
					error('Eclipse during the night!')
				end
	
				% calc sizes
				Pe = calcvsop87('aarde',t);	% distance sun-earth in AU
				dS = unitcon(Pe(3),'AU','m');
				Pm = calclunarc(t);	% lunar distance in [km]
				dM = Pm(3)*1000;
				arS = atan(c.dSun/dS/2);	% apparent size (radius) of the sun
				arM = atan(c.dMoon/dM/2);	% apparent size (radius) of the moon
			elseif ~isempty(t)
				% check if day-time
				pS = calcposhemel(D.pos,t);
				pM = calcposhemel(D.pos,t,'maan');
	
				if pS(2)<0
					error('Eclipse during the night!')
				end
	
				% calc sizes ------ (!!!!!) or take from D??!!!!!
				%      most correct: recalculate
				%          <--->  consistency with Anim don't recalculate
				%      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				Pe = calcvsop87('aarde',t);	% distance sun-earth in AU
				dS = unitcon(Pe(3),'AU','m');
				Pm = calclunarc(t);	% lunar distance in [km]
				dM = Pm(3)*1000;
				arS = atan(c.dSun/dS/2);	% apparent size (radius) of the sun
				arM = atan(c.dMoon/dM/2);	% apparent size (radius) of the moon
			else
				pS = D.pS;
				pM = D.pM;
				arS = D.arS;
				arM = D.arM;
			end

			th = 0:pi/20:2*pi;
			%plot(pS(1)+arS*cos(th),pS(2)+arS*sin(th)	...
			%	,pM(1)+arM*cos(th),pM(2)+arM*sin(th));grid
			lS = findobj(ax,'Tag','sun');
			lM = findobj(ax,'Tag','moon');
			if isempty(lS) || isempty(lM)
				patch(pS(1)+arS*cos(th),pS(2)+arS*sin(th),[1 1 0],'Tag','sun')
				patch(pM(1)+arM*cos(th),pM(2)+arM*sin(th),[1 1 1]	...
					,'FaceAlpha',0.95,'Tag','moon')
			else
				set(lS,'XData',pS(1)+arS*cos(th),'YData',pS(2)+arS*sin(th))
				set(lM,'XData',pM(1)+arM*cos(th),'YData',pM(2)+arM*sin(th))
			end
			axis equal
		end		% Plot

		function Illustrate(c,t)
			f = gcf;
			fEclipse = getmakefig('Eclips',false,true,'Eclipse illustration');
			c.Plot(t,[],fEclipse.Children)
			figure(f)
		end		% Illustrate

		function Animate(c,D,t)
			nMax = 100;
			dtMin = 1;	% [seconds]
			if nargin<2
				D = c.D_last;
				if isempty(D)
					error('First calculate the eclipse!')
				end
			elseif ischar(D)
				pos = geogcoor(D);
				[~,D] = c.CalcEclipsTime(pos,t);
			end
			t1 = juliandate(D.t1);
			t2 = juliandate(D.t4);
			% test op zon op/onder!!!
			th = 0:pi/20:2*pi;
			dt = min(dtMin/86400,(t2-t1)/nMax);
			t = (t1:dt:t2)';
			i = findclose(t,D.t0JD);

			PS = calcposhemel(D.pos,t);
			PM = calcposhemel(D.pos,t,'maan');

			minPS = min(PS);
			maxPS = max(PS);
			minPM = min(PM);
			maxPM = max(PM);
			minP = min([minPS-D.arS;minPM-D.arM]);
			maxP = max([maxPS+D.arS;maxPM-D.arM]);

			fDeg = 180/pi;
			[figT,bNT] = getmakefig('eclips_Dplot');
			plot(t,calcdang(PS,PM)*fDeg);grid
			title 'Angular distance sun - moon'
			ylabel [^o]
			if bNT
				navfig
				navfig(char(4))
			end
			navfig('X')

			[fig,bN] = getmakefig('eclipsAnimation');
			plot(PS(:,1)*fDeg,PS(:,2)*fDeg,'--',PM(:,1)*fDeg,PM(:,2)*fDeg,':');grid
			lS = line((PS(i,1)+D.arS*cos(th))*fDeg,(PS(i,2)+D.arS*sin(th))*fDeg);
			lM = line((PM(i,1)+D.arM*cos(th))*fDeg,(PM(i,2)+D.arM*sin(th))*fDeg		...
				,'color',[0 0.5 0],'Linestyle','--');
			axis([minP(1) maxP(1) minP(2) maxP(2)]*fDeg)
			axis equal
			ylabel [^o]
			title(sprintf('Eclipse pos (%.4f N, %.4f E) - time in UTC',c.D_last.pos([2 1])*180/pi))
			set(fig,'UserData',var2struct(t,th,lS,lM,PS,PM))
			setappdata(fig,'idx',i)
			setappdata(fig,'focus',false)
			fig.KeyPressFcn = @c.KeyPressAnim;
			c.KeyPressAnim(fig,struct('Key','','Character','','Modifier',{{}}),true)
		end		% Animate

		function KeyPressAnim(c,fig,ev,bForce)
			if nargin<4 || isempty(bForce)
				bForce = false;
			end
			idx = getappdata(fig,'idx');
			bFocus = getappdata(fig,'focus');
			bIllustrate = getappdata(fig,'illustrate');
			if isempty(bIllustrate)
				bIllustrate = false;
				setappdata(fig,'illustrate',false);
			end
			D = fig.UserData;
			bUpdate = bForce;
			di = 0;
			fDeg = 180/pi;
			if any(strcmp(ev.Modifier,'control'))
				switch ev.Key
					case 'p'
						bIllustrate = ~bIllustrate;
						setappdata(fig,'illustrate',bIllustrate)
						if bIllustrate
							c.Illustrate(D.t(idx))
						end
				end
			else
				switch ev.Key
					case 'leftarrow'
						di = -1;
					case {'rightarrow','space'}
						di = 1;
					case 'uparrow'
						di = 10;
					case 'downarrow'
						di = -10;
					case 'pageup'
						di = 100;
					case 'pagedown'
						di = -100;
					case 'home'
						idx = 1;
						bUpdate = true;
					case 'end'
						idx = length(D.t);
						bUpdate = true;
					otherwise
						switch ev.Character
							case 'n'
								di = 1;
							case 'p'
								di = -1;
							case '0'
								idx = findclose(D.t,c.D_last.t0JD);
								bUpdate = true;
							case 'i'
								p0 = D.PS(idx,:)*fDeg;
								xl = xlim;
								yl = ylim;
								xlim(p0(1)+(xl-p0(1))/2)
								ylim(p0(2)+(yl-p0(2))/2)
							case {'o','u'}
								p0 = D.PS(idx,:)*fDeg;
								xl = xlim;
								yl = ylim;
								xlim(p0(1)+(xl-p0(1))*2)
								ylim(p0(2)+(yl-p0(2))*2)
							case 'f'
								bFocus = ~bFocus;
								bUpdate = bFocus;
								setappdata(fig,'focus',bFocus)
							case 'P'
								c.Illustrate(D.t(idx))
						end
				end		% switch
			end		% not control
			if di<0
				bUpdate = idx>1;
				idx = max(1,idx+di);
			elseif di>0
				bUpdate = idx<length(D.t);
				idx = min(length(D.t),idx+di);
			end
			if bUpdate
				set(D.lS,'XData',(D.PS(idx,1)+c.D_last.arS*cos(D.th))*fDeg	...
					,'YData',(D.PS(idx,2)+c.D_last.arS*sin(D.th))*fDeg);
				set(D.lM,'XData',(D.PM(idx,1)+c.D_last.arM*cos(D.th))*fDeg	...
					,'YData',(D.PM(idx,2)+c.D_last.arM*sin(D.th))*fDeg);
				d = calcdang(D.PS(idx,:),D.PM(idx,:));
				[~,~,~,fOverlap] = AcircOverlap(c.D_last.arS,c.D_last.arM,d);
				s = sprintf('%3d - %s - %.4f degree - %.1f %%',idx	...
					,calccaldate(D.t(idx),[],true)		...
					,d*180/pi,fOverlap*100);
				xlabel(s)
				if bFocus
					p0 = D.PS(idx,:)*fDeg;
					dx = diff(xlim)/2;
					dy = diff(ylim)/2;
					xlim((p0(1)+[-dx dx]))
					ylim((p0(2)+[-dy dy]))
				end
				setappdata(fig,'idx',idx)
				if bIllustrate
					c.Illustrate(D.t(idx))
				end
			end
		end		% KeyPressFcn
	end		% methods

end		% cEclipseCalc

function tMin = FindMinimum(f,t0)
dt = 0.1;
y2 = f(t0);
y1 = f(t0-dt);
y3 = f(t0+dt);
if y1<=y2 && y2<=y3
	while y1<=y2
		y3 = y2;
		y2 = y1;
		t0 = t0-dt;
		y1 = f(t0-dt);
	end
elseif y1>=y2 && y2>=y3
	while y2>=y3
		y1 = y2;
		y2 = y3;
		t0 = t0+dt;
		y3 = f(t0+dt);
	end
end
p = polyfit([-dt 0 dt],[y1-y2 0 y3-y2],2);
dx = -p(2)/2/p(1);
tMin = t0+dx;
dMin = f(tMin);
if dMin>y1 || dMin>y2 || dMin>y3
	warning('Minimum is higher than other points?!!!')
	return
end
%fprintf('     --> %10.5f (%11.4f - %s)\n',dMin*1000,dx*1440,calccaldate(tMin,[],true))
for i=1:5	%!!!!!!
	dt = dt/3;
	y2 = f(tMin);	% --> dMin(!)
	y1 = f(tMin-dt);
	y3 = f(tMin+dt);
	p = polyfit([-dt 0 dt],[y1-y2 0 y3-y2],2);
	dx = -p(2)/2/p(1);
	t0 = tMin;
	tMin = tMin+dx;
	d = f(tMin);
	if d>dMin
		warning('Bad optimisation?!')
		tMin = t0;
		break
	end
	dMin = d;
	%fprintf('     --> %10.5f (%11.4f - %s)\n',dMin*1000,dx*1440,calccaldate(tMin,[],true))
end
end		% FindMinimum

function [tStart,tEnd] = FindStartEnd(f,tCentre,dt,dCentre,dPlim)
tStart = tCentre;
dP = dCentre;
while dP<dPlim
	tStart = tStart-dt;
	dPl = dP;
	dP = f(tStart);
end
tStart = tStart+(dP-dPlim)/(dP-dPl)*dt;
tEnd = tCentre;
dP = dCentre;
while dP<dPlim
	tEnd = tEnd+dt;
	dPl = dP;
	dP = f(tEnd);
end
tEnd = tEnd-(dP-dPlim)/(dP-dPl)*dt;
end		% FindStartEnd
