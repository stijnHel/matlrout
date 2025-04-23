function [X,B] = nonnans(X)
%nonnans - elements with NaN's removed (like nonzeros)
%    X = nonnans(X)
%    [X,Bnans] = nonnans(X)	- also returns the nans (discarded elements)
%            Bnans is a boolean matrix with the same size as X

B = isnan(X);
X(B) = [];
