function [S,ii]=genSort(S,fun)
%genSort  - General sort routine (with compare function)
%     [S,ii] = genSort(List,fun)
%         List: can be numeric array (rows are taken as elements except for
%               row vectors) or cell vectors
%         fun: function handle returning <0, =0, >0 for x<y, x==y, x>y
%
%  sorting is done from small to large (fun(S(1),S(2))<0)
%    equal values (fun(...)==0) are kept in order
%
%  Example:
%         A = [2 1 1+1i 2]
%         Asort = genSort(A,@(x,y) abs(x)-abs(y))
%
% (currently - just bubble sort)

bTrans = isnumeric(S) && isrow(S);
if bTrans
	S = S.';
end
bCell = iscell(S);
if bCell
	n = length(S);
else
	n = size(S,1);
end

ii = 1:n;
i1 = 1;
i2 = n;
bDir = true;

bUnsorted = true;

while bUnsorted && i2>i1
	bUnsorted = false;
	if bDir
		k1 = i1;
		k2 = i2-1;
		dk = 1;
	else
		k1 = i2;
		k2 = i1+1;
		dk = -1;
	end
	if bCell
		e1 = S{k1};
	else
		e1 = S(k1,:);
	end
	for k=k1:dk:k2
		if bCell
			e2 = S{k+dk};
		else
			e2 = S(k+dk,:);
		end
		c = fun(e1,e2)*dk;
		if c>0	% wrong order
			%??? do element reordering later? (and use index always)
			if bCell
				[ii(k),ii(k+dk),S{k},S{k+dk}] = deal(ii(k+dk),ii(k),S{k+dk},S{k});
			else
				[ii(k),ii(k+dk),S(k,:),S(k+dk,:)] = deal(ii(k+dk),ii(k),S(k+dk,:),S(k,:));
			end
			bUnsorted = true;
		else
			e1 = e2;
		end		% if c>0
	end
	if bDir
		i2 = i2-1;
		bDir = false;
	else
		i1 = i1+1;
		bDir = true;
	end
end

if bTrans
	S = S.';
end
