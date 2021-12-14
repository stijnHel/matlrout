function C=polyprod(A,B)
%polydiv  - Multiplication of polynomials (product)
%
%       C=polyprod(A,B)
%
%  Multiplication of polynomials with polynomials defined as vectors (see
%  polyval).  The product is made by conv.  The difference in the result
%  is that it is simplified (0-coefficients of highest order are removed).
%
% see also deconv, conv

C=conv(A,B);
if C(1)==0
	i=find(C~=0,1);
	if isempty(i)
		C=0;
	else
		C=C(i:end);
	end
end
