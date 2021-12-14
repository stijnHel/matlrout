function i=binzoek(A,x,exact)
% CELL/BINZOEK - Zoekt een string in een gesorteerde lijst (volgens binaire zoekmethode)

% !!! ??? test bij voorkomen van meerdere gelijke elementen ???
%         NEEN
if isempty(A)
	if nargin>2
		i=[];
	else
		i=0.5;
	end
	return
end
i=1;
j=length(A);
while j-i>1
	k=floor((i+j)/2);
	c=strcmpc(A{k},x);
	if c<0
		i=k+1;
	elseif c>0
		j=k-1;
	else
		i=k;
		return
	end
end
c=strcmpc(x,A{i});
if i==j
	if nargin>2
		if c
			i=[];
		end
	else
		i=i+c/2;
	end
elseif c<0
	if nargin>2
		i=[];
	else
		i=i-0.5;
	end
elseif c>0
	c=strcmpc(x,A{j});
	if c<0
		if nargin>2
			i=[];
		else
			i=i+0.5;
		end
	elseif c==0
		i=j;
	elseif nargin>2
		i=[];
	else
		i=j+0.5;
	end
end
