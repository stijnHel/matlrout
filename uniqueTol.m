function u=uniqueTol(x,tol)
%uniqueTol - set unique with tolerance
%   u=uniqueTol(x,tol)
% only for vectors, not for arrays

u=unique(x);
i=1;
while i<length(u)
	j=i+1;
	while j<=length(u)&&u(j)-u(i)<tol
		j=j+1;
	end
	if j-i>1
		u(i)=mean(u(i:j-1));
		u(i+1:j-1)=[];
		j=i+1;
	end
	i=j;
end
