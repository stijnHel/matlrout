function [p,mu] = quickpolyfit(x,y,n,bNormalizeX)
%quickpolyfit - Fit polynomial to data. - based on polyfit, but less tests
%   Tests appeared to take most of the time!
%       [p,mu] = quickpolyfit(x,y,n,bNormalizeX)

if numel(x)~=numel(y)
	error('Not equal length!')
elseif all(size(x)>1) || all(size(y)>1)
	error('Columns are expected!')
end

x = x(:);
y = y(:);

if nargin<4 || isempty(bNormalizeX)
	bNormalizeX = nargout>1;
end
if bNormalizeX
    mu = [mean(x); std(x)];
    x = (x - mu(1))/mu(2);
end

% Construct the Vandermonde matrix V = [x.^n ... x.^2 x ones(size(x))]
V(:,n+1) = ones(length(x),1,class(x));
for j = n:-1:1
    V(:,j) = x.*V(:,j+1);
end

% Solve least squares problem p = V\y to get polynomial coefficients p.
[Q,R] = qr(V,0);
p = R\(Q'*y);               % Same as p = V\y

% Issue warnings.
if size(R,2) > size(R,1)
    warning(message('MATLAB:polyfit:PolyNotUnique'))
end

p = p.'; % Polynomial coefficients are row vectors by convention.
