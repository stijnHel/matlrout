function [S,T1,T2]=calcschemering(geog,D,schAngles)
%calcshemering - Berekent schemering
%   [S,T1,T2]=calcschemering(geog,D)
%        S: hours before/after sunrise/-set
%        T1: time of sunrise (in fractional hours)
%        T2: time of sunset

if ~exist('geog','var')||isempty(geog)
	geog='ukkel';
end
if ~exist('D','var')||isempty(D)
	D=clock;
	D=D(3:-1:1);
elseif length(D)>3
	D=D(1:3);
end
if ~exist('schAngles','var')||isempty(schAngles)
	schAngles=[6 12 18];
end
if isscalar(D)
	t=D;
else
	t=calcjd(D);
end

[T1,T2]=efemeride(t,'zon',geog,{'bCalcMinSec',false});

rSch=sort(schAngles)*pi/180;
p=[0 0];
u=T1;
i=1;
P=zeros(1,500);
du=0.02;
while p(2)+rSch(end)>0&&u>0
	u=u-du;
	p=calcposhemel(geog,t+u/24,'zon',{'bAtmCor',false});
	i=i+1;
	P(i)=p(2);
end
if any(diff(P(1:i))>=0)
	error('Wat gebeurt hier(1)?')
end
S1=interp1(P(1:i),(0:i-1)*du,-rSch);
% het volgende zou eenvoudiger moeten kunnen
p(2)=0;
u=T2;
i=1;
du=0.02;
while p(2)+rSch(end)>0&&u<24
	u=u+du;
	p=calcposhemel(geog,t+u/24,'zon',{'bAtmCor',false});
	i=i+1;
	P(i)=p(2);
	if P(i)>=P(i-1)
		i=i-1;
		break
	end
end
if any(diff(P(1:i))>=0)
	error('Wat gebeurt hier(2)?')
end
S2=interp1(P(1:i),(0:i-1)*du,-rSch);

S=[S1;S2];
