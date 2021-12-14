function dy=dinterp1(X,Y,x)
% DINTERPM - Bepaalt helling in punt
%    dy=interpm(X,Y,x)

if X(2)<X(1)
	X=flipud(X);
	Y=flipud(Y);
end
i=find(X<=x);
if isempty(i)
	if x==X(1)
		dy=(Y(2)-Y(1))/(X(2)-X(1));
	else
		dy=0;	% !!rand
		warning('!!!Bepaling helling buiten gebied (x<min(X))')
	end
elseif length(i)==length(X)
	dy=0;
	warning('!!!Bepaling helling buiten gebied (x>min(X))')
elseif x==X(end)
	dy=(Y(end)-Y(end-1))/(X(end)-X(end-1));
else
	i=i(end);
	dy=(Y(i+1)-Y(i))/(X(i+1)-X(i));
end
