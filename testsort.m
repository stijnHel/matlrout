function B=testsort(X)
% TESTSORT - Test of matrix gesorteerd is.

if isstr(X)
	b=1;
	i=2;
	while b&(i<size(X,1))
		b=strcmpc(deblank(X(i-1,:)),deblank(X(i,:)))<=0;
		i=i+1;
	end
else
	b=any(diff(X)>=0);
end

if nargout
	B=b;
elseif b
	fprintf('Matrix gesorteerd\n');
else
	fprintf('Matrix niet gesorteerd\n');
end