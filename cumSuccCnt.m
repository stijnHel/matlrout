function N=cumSuccCnt(B)
%cumSuccCnt - Cumulative count of successive true values
%          N=cumSuccCnt(B)
%    works in rows
% see also cumnzel

N=zeros(size(B));
N(1,:)=B(1,:)~=0;
for i=2:size(N,1)
	for j=1:size(N,2)
		if B(i,j)
			N(i,j)=N(i-1,j)+1;
		else
			N(i,j)=0;
		end
	end
end
