function [Q,R]=polydiv(A,B)
%polydiv  - Division of polynomials
%
%       C=polydiv(A,B)
%
%  Division of polynomials with polynomials defined as vectors (see polyval)
%  The division is done by deconv.  The difference in the results is that
%  they are simplified (0-coefficients of highest order are removed).
%
% see also deconv, conv

[Q,R]=deconv(A,B);
if Q(1)==0
	i=find(Q~=0,1);
	if isempty(i)
		Q=0;
	else
		Q=Q(i:end);
	end
end
if R(1)==0
	i=find(R~=0,1);
	if isempty(i)
		R=0;
	else
		R=R(i:end);
	end
end
