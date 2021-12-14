function x=filtconv(x,n)
%filtconv - easy filter based on running average (based on convolution)
%      x=filtconv(x,n)
% only made to prevent choosing/making a filter, followed by using it

n2=round(n/2);
nx=length(x);
bTran=nx>size(x,1);
nChan=min(size(x));
ii=n2:n2+nx-1;
if nChan>1
	xf=zeros(size(x));
	if bTran
		c=ones(1,n)/n;
	else
		c=ones(n,1)/n;
	end
	for i=1:nChan
		if bTran
			x0=mean(x(i,1:n));
			y=conv(x(i,:)-x0,c);
			xf(i,:)=y(ii)+x0;
		else
			x0=mean(x(1:n,i));
			y=conv(x(:,i)-x0,c);
			xf(:,i)=y(ii)+x0;
		end
	end
	x=xf;
else
	if bTran
		x=x(:);
	end
	x0=mean(x(1:n));
	x=conv(x-x0,ones(n,1)/n);
	x=x(ii,:)+x0;
	if bTran
		x=x';
	end
end
