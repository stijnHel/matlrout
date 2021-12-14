function [yy,PP]=mySpline(x,y,xx,varargin)
%mySpline - Changed spline interpolation function - mainly as a trial
%    [yy,PP]=mySpline(x,y,xx,...)
%    PP=mySpline(x,y,...)
%
%    currently only equidistant-x!
%  The natural cubic spline is calculated (with endpoints having 0 second
%  derivatives).  The endpoints is the difference between this function and
%  the Matlab spline function (which is using the "not-a-knot end
%  condition").
%
%       see also ppval, spline
%
% ref.: http://www.geos.ed.ac.uk/~yliu23/docs/lect_spline.pdf

bCalcInterpol=false;
if nargin>2
	options=varargin;
	if isnumeric(xx)
		bCalcInterpol=true;
	else
		options=[{xx},options];
	end
	if ~isempty(options)
		setoptions({''},options{:})	% not yet any options!!!!
	end
end

dx=diff(x);
h=mean(dx);
if max(dx)-min(dx)>h/1e10
	error('Only works for equidistant samples!!')
end
y=y(:);

n = length(x);
if n<2
	error('No interpolation possible - not enough data!!!')
elseif n==2
	p=polyfit(x,y,1);
elseif n==3&&isempty(endslopes) % the interpolant is a parabola
	p=polyfit(x,y,2);
else % set up the sparse, tridiagonal, linear system b = ?*c for the slopes
	% Create the equations to create the spline (see eq. 3.18 in
	% "lect_spline.pdf")
	C=spdiags([1 1 0;repmat([1 4 1],n-2,1);0 1 1],[-1 0 1],n,n);
	C(1,2)=0;
	C(n,n-1)=0;
	% the right hand side of the equation
	F=[y(1);6*y(2:n-1);y(n)]/h^3;
	% Calculate the a0..aN coefficients
	A=C\F;
	% add the first and last coefficients
	Am1=2*A(1)-A(2);
	Anp1=2*A(n)-A(n-1);
	A=[Am1;A;Anp1];
	
	% Create the set of polynomials
	p=zeros(n-1,4);
	P=bsxfun(@times,cumprod([1 h h h]),[1/6 0 0 0;-0.5 0.5 0.5 1/6;1/2 -1 0 2/3;-1/6 1/2 -1/2 1/6]);
		% P is the parts of the "B-functions" (combined of 4 pieces(
		%     the zero end parts are not included here
	% The polynomials are weighted sums of the "B-functions"
	for i=1:n-1
		p(i,:)=A(i+3:-1:i)'*P;
	end
end
P=struct('form','pp','breaks',x,'coefs',p,'pieces',n-1	...
	,'order',size(p,2),'dim',1);
if bCalcInterpol
	yy=ppval(P,xx);
	if nargout>1
		PP=P;
	end
else
	yy=P;
end
