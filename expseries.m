function x=expseries(mn,mx,N)
%expseries - exponential series
%    x=expseries(mn,mx,N)
%    x=expseries([mn,mx],N)
%    x=expseries([mn,mx,N])

if numel(mn)==3
	if nargout>1
		error('Wrong inputs')
	end
	N=mn(3);
	mx=mn(2);
	mn=mn(1);
elseif numel(mn)==2
	if nargout~=2
		error('Wrong inputs')
	end
	N=mx;
	mx=mn(2);
	mn=mn(1);
elseif nargin~=3||~isscalar(mn)||~isscalar(mx)||~isscalar(N)
	error('Wrong inputs')
end

if N==0
	x=[];
elseif N==1
	x=mn;
elseif N==2
	x=[mn mx];
elseif N<0||N~=round(N)
	error('Wrong number of elements')
elseif mn<=0||mx<=0
	error('minimum and maximum must be strictly positive!')
else
	x=mn*exp((0:N-1)*(log(mx/mn)/(N-1)));
end
