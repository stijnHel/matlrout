function dy=dinterpm(A,x)
% DINTERPM - Bepaalt helling in punt
%    dy=interpm(A,x)

if A(2,1)<A(1,1)
	A=flipud(A);
end
i=find(A(:,1)<=x);
if isempty(i)
	if x==A(1,1)
		dy=(A(2,2)-A(1,2))/(A(2,1)-A(1,1));
	else
		dy=0;	% !!rand
		warning('!!!Bepaling helling buiten gebied (x<min(X))')
	end
elseif length(i)==length(A)
	dy=0;
	warning('!!!Bepaling helling buiten gebied (x>max(X))')
elseif A(end,1)==x
	dy=(A(end,2)-A(end-1,2))/(A(end,1)-A(end-1,1));
else
	i=i(end);
	dy=(A(i+1,2)-A(i,2))/(A(i+1,1)-A(i,1));
end
