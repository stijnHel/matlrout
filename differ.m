function dx=differ(x,n,dt)
% DIFFER - Differentieer x, orde n

if ~exist('n')
	n=2;
end
if ~exist('dt')
	dt=1;
end
x=x(:);
n2=floor(n/2);
if rem(n,2)
	c=[ones(n2,1);0;-ones(n2,1)]/n2/(n2+1);
else
	c=[ones(n2,1);-ones(n2,1)]/n2/n2;
end
dx=conv(x,c);
dx=dx(n2:length(x)-n2-1)/dt;
dx(1:n2)=zeros(n2,1);
dx(length(x)-n2+1:length(x))=zeros(n2,1);
