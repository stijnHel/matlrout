function tekenbits(x,nbyte,revbitorder,revbyteorder)
% TEKENBITS - Tekent bits in graf

if ~exist('nbyte')|isempty(nbyte)
	nbyte=1;
end
if ~exist('revbitorder')|isempty(revbitorder)
	revbitorder=0;
end
if ~exist('revbyteorder')|isempty(revbyteorder)
	revbyteorder=0;
end

X=zeros(length(x),8);
if revbitorder
	y=128;
else
	y=1;
end
for i=1:8
	X(:,i)=bitand(x,y);
	if revbitorder
		y=y/2;
	else
		y=y*2;
	end
end
if nbyte>1
	dx=rem(length(x),nbyte);
	if dx
		warning('!!!!input wordt afgekapt om geheel aantal rijen te krijgen!!!')
		x=x(1:end-dx);
		X=X(1:end-dx,:);
	end
	N=length(x)/nbyte;
	Y=zeros(N,nbyte*8);
	for i=1:nbyte
		if revbyteorder
			Y(:,(i-1)*8+(1:8))=X(nbyte-i+1:nbyte:end,:);
		else
			Y(:,(i-1)*8+(1:8))=X(i:nbyte:end,:);
		end
	end
	X=Y;
end
[i,j]=find(X);
plot(j,i,'.');
axis equal
axis ij