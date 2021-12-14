function [z,dz]=plus_err(x,dx,y,dy)
%plus_err - add elements and keep track of error
%    [z,dz]=plus_err(x,dx,y,dy)
%    [z,dz]=plus_err(x,y)	% dx and dy are taken as floating point errors

if nargin==2
	y=dx;
	dx=eps(x);
	dy=eps(y);
elseif nargin~=4
	error('Wrong inputs!')
end

z=x+y;
%dz=max(eps(z),sqrt(dx.^2+dy.^2));
dz=sqrt(dx.^2+dy.^2);
