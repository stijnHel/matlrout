function Z=compVectors(X,Y,tol)
%compVectors - Compare vectors for equal elements
%    Z=compVectors(X,Y[,tol])
%          if tol is given, abs(x-y)<tol is used in place of equality
%       Z is a nX x nY logical matrix with "true" when the i-th element of
%          X is equal to the j-th element of Y

Z=false(length(X),length(Y));
if size(X,2)>1
	X=X';
end
for i=1:length(Y)
	Z(:,i)=X==Y(i);
end
