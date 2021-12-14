function   [xc,yc,R,dR2] = circfit(x,y,bSigned)
%circfit - Fit circle through set of points.
%   [xc yx R] = circfit(x,y[,bSigned])
%
%   fits a circle  in x,y plane in a more accurate
%   (less prone to ill condition )
%  procedure than circfit2 but using more memory
%  x,y are column vector where (x(i),y(i)) is a measured point
%
%  result is center point (yc,xc) and radius R
%  an optional output is the vector of coeficient a
% describing the circle's equation
%
%   x^2+y^2+a(1)*x+a(2)*y+a(3)=0
%
%  If bSigned is given (and true), then R will be negative if rotation
%  direction is "positive" (counter clockwise).
%
%  By:  Izhak bucher 25/oct /1991 with changes by FMTC

if nargin<3||isempty(bSigned)
	bSigned=false;
end

x=x(:);
y=y(:);
% centre around mean (for better numerical stability for circles far of 0-pt
mx=mean(x);
my=mean(y);
x=x-mx;
y=y-my;
dR2=[];
A=[x y ones(size(x))];
rA=rank(A);
if rA<3
	if rA==1	% point
		xc=0;
		yc=0;
		R=NaN;
	else	% line
		% not necessary, but easy determination of orthogonal
		[~,s,v]=svd(A);
		[~,i]=min(abs(diag(s)));
		xc=v(1,i);
		yc=v(2,i);
		R=Inf;
	end
else
	P2=x.^2+y.^2;
	a=A\P2;
	xc = mx+.5*a(1);
	yc = my+.5*a(2);
	R  =  sqrt((a(1)^2+a(2)^2)/4+a(3));
	if nargout>3
		dR2=A*a-P2;
	end
	if bSigned
		if (x(1)-xc)*(y(end)-y(1))<(y(1)-yc)*(x(end)-x(1))
			R=-R;
		end
	end
end
