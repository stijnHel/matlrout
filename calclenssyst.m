function S=calclenssyst(d,Xf,D)
%calclenssyst - Berekent een lenssysteem
%      S=calclenssyst(d,Xf,D)
%   bepaalde afstand detector-target (d)
%   bepaalde afstand detector-lens
%   gezocht : focus, vergroting, ...
%     voor extra berekende parameters wordt D gebruikt : diameter lens
%   andere bepaling :
%      S=calclenssyst([d,<vergroting>])

if length(d)==2
	g=d(2);
	d=d(1);
	if nargin>1
		D=Xf;
	end
	Xf=d/(g+1);
	X=Xf^2/d;
	X2=(d-Xf)^2/d;
else
	% hieruit volgt X en X2 (afstand van andere focuspunt tot target)
	%X=Xf-f;		% ook gelijk aan Xf^2/d
	%X2=f*f/X;	% ook gelijk aan (d-Xf)^2/d
	X=Xf^2/d;
	X2=(d-Xf)^2/d;

	% vergroting
	%g=(f+X2)/(f+X);	% ook gelijk aan (d-Xf)/Xf
	g=(d-Xf)/Xf;
end
% focusafstand :
%      Enerzijds de relatie focus-afstand en totale afstand:
%         X^2 + (2f-d)*X + f^2 = 0
%      Anderzijds een vastgelegde afstand lens tot detector:
%         X+f = y (hier is 'y' 'Xf' genoemd
%      Daaruit volgt de bepaling voor f
f=Xf*(1-Xf/d);

if ~exist('D','var')||isempty(D)
	D=.0254;	% diameter lens ivm hoek van ontvangen straling
end

% gedetecteerde oppervlak (met vaste grootte detector 3.6 mm vierkant
A=(.0036*g)^2;

% Afstanden lens tot detector en target
dDL=X+f;	% is gelijk aan de opgelegde Xd(!)
dLT=X2+f;	% afstand lens-target

% De hoek van waar straling komt (in princiepe enkel voor middelpunt)
Hr=atan2(D/2,dLT)*2;
H=Hr*180/pi;

% De totale hoeveelheid ontvangen straling (bij eenheidsstraling van
% oppervlak).
I=A*2*pi*(1-cos(Hr/2));

S=struct('d',d,'Xf',Xf,'D',d	...
	,'f',f	...
	,'X',[X,X2]	...
	,'dDL',dDL,'dLT',dLT	...
	,'g',g,'A',A	...
	,'H',H	...
	,'I',I	...
	);
