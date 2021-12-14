function [Z,X,Y]=splits(A)
% SPLITS - splitst een gekombineerde tabel tot zijn elementen X, Y en Z
%     [Z,X[,Y]]=splits(A)
%        with
%           A = [X Z]
%           A = [ 0 X
%                 Y Z ]

if min(size(A))<2
	error('A heeft een verkeerde grootte')
end
if min(size(A))==2
	if (size(A,1)==2)&(size(A,2)>2)
		A=A';
	end
	Z=A(:,2);
	X=A(:,1);
else
	Z=A(2:size(A,1),2:size(A,2));
	X=A(1,2:size(A,2));
	Y=A(2:size(A,1),1);
end
