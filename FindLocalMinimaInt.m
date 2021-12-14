function [tMin,xMin]=FindLocalMinimaInt(x,tMin,dt)
%FindLocalMinimaInt - Find local minima with parabolic interpolation
%    [tMin,xMin]=FindLocalMinimaInt(x,tMin,dt)
%    [tMin,xMin]=FindLocalMinimaInt(x)	% indexes are assumed

ii=find(x(1:end-2)>x(2:end-1)&x(3:end)>=x(2:end-1));
if isempty(ii)
	tMin=[];
	xMin=[];
else
	xm1=x(ii);
	x0=x(ii+1);
	xp1=x(ii+2);
	diMin=(xm1-xp1)./(xm1-2*x0+xp1)/2;
	if nargin==1
		tMin=ii+diMin+1;
	else
		tMin=(ii+diMin)*dt+tMin;
	end
	if nargout>1
		xMin=(((xm1+xp1)/2-x0).*diMin+(xp1-xm1)/2).*diMin+x0;
	end
end
