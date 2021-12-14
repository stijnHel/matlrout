function C=adjugate(A,bCofactor)
%adjugate - Calculate the adjugate (or cofactor) matrix
%   C=adjugate(A)      -> adjugate matrix
%   C=adjugate(A,true) -> cofactor matrix
%  The cofactor matrix is the matrix where its elements are the determinant
%  of the matrix where the row and column of that element are removed, with
%  an alternating sign.
%  A must be a square matrix.
%  The adjugate is the transpose of the cofactor matrix.
%
%  It is the same as inv(A)*det(A), but in case of zero determinants, this
%  gives problems.
%
% see https://en.wikipedia.org/wiki/Adjugate_matrix

n=size(A);
if length(n)>2||n(1)~=n(2)
	error('A must be a square matrix')
end
n=n(1);
ii=1:n;

C=A;
for iRow=1:n
	for iCol=1:n
		C(iRow,iCol)=(-1)^(iRow+iCol)*det(A(ii(ii~=iRow),ii(ii~=iCol)));
	end
end
if nargin==1||isempty(bCofactor)||~bCofactor
	C=C';
end
