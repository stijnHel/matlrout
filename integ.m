function A=integ(x,h)
%integ    - simple integration
%       A=integ(x,h)
if ~exist('h','var');h=[];end
if isempty(h)
	h=1;
end

if size(x,1)==1
	x=x';
end
l=size(x,1);
if l<=2
	A=sum(x)*h*(l-1);
	return
elseif l<=4
	A=trapz(x)*h;
	return
end
if rem(l-1,2)
	dA=(x(l-1,:)+x(l,:))*h/2;
	l=l-1;
else
	dA=0;
end
A=(2*sum(x(3:2:l-1,:))+4*sum(x(2:2:l-1,:))+x(1,:)+x(l,:))*h/3+dA;
