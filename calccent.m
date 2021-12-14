function X0=calccent(d,R)
%calccent - Berekent centrum van cirkel op basis van booglengte en R
%
%  Deze berekening werd gemaakt ivm bepaling van temperatuur op basis van
%  uitzetting van cilinder van IPSO-case (mmWaves)
%
%      X0=calccent(d,R)
%            d  : afstand tussen center-punten van rollen
%            R  : straal ((!)inclusief straal van rollen
%            X0 : hoogte van centrum

if length(d)>1
	r=d(2);
	d=d(1);
	phi=0:pi/300:pi*2+100*eps;
	plot([d -d]/2,[0 0],'x');grid
	axis equal
	line(-d/2+r*cos(phi),r*sin(phi),'color',[0 1 0])
	line(d/2+r*cos(phi),r*sin(phi),'color',[0 1 0])
	linest={'-','--',':'};
	if nargout
		X0=R;
	end
	for i=1:length(R)
		x0=calccent(d,r+R(i));
		line(R(i)*cos(phi),x0+R(i)*sin(phi),'color',[0 0 1]	...
			,'linestyle',linest{rem(i-1,3)+1})
		if nargout
			X0(i)=i;
		end
	end
	return
end

X0=sqrt(R*R-d*d/4);
