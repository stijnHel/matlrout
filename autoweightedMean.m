function mn=autoweightedMean(x)
%autoweightedMean - weighted mean with automated weights based on std
%     mn=autoweightedMean(x)

mn=mean(x);
s=std(x);
s(s==0)=1;
b2D=min(size(x))>1;
if size(x,1)==1
	x=x';
elseif b2D
	x1=x;
	W=x;
end
if b2D
	for j=1:size(x,2)
		x1(:,j)=x(:,j)-mn(j);
		W(:,j)=exp(-(x1(:,j)/s(j)).^2/2);
	end
else
	x1=x-mn;
	W=exp(-(x1/s).^2/2);
end
mn=mn+sum(x1.*W)./sum(W);
