function Y=cumnzel(X)
%cumnzel  - Cumulative non-zero element calculation
%   counts successive non-zero elements
%      Y=cumnzel(X)
%
%  If X is a matrix, counting is done row by row.
%
% see also cumSuccCnt

if isnumeric(X)
	X=X~=0;
end
if isrow(X)
	X=X';
end

sX=size(X);
iC=find(sX);

if iC>1
	bSwap=true;
	X=X';
else
	bSwap=false;
end
Y=zeros(size(X));
Y(1,:)=X(1,:)~=0;
for j=1:size(X,2)
	for i=2:size(X,1)
		if X(i,j)
			Y(i,j)=Y(i-1,j)+1;
		else
			Y(i,j)=0;
		end
	end
end

if bSwap
	Y=Y';
end
