function B=splitbits(X,nBits)
%splitbits - Split integers in separate bits
%       B=splitbits(X)
%             X>=0
%       B=splitbits(X,nBits)
%             twos-complement with nBits-words

X=X(:);
if any(X~=floor(X))
	error('Only works with integral numbers!')
end
if nargin>1
	mxX2=2^nBits;
	if any(X<0)
		if any(X+mxX<0)
			warning('SPLITBITS:minSaturation','some values are lower than minimum!')
			X=max(X,-mxX);
		end
		X=X+(X<0).*mxX2;
		mxX=mxX2/2;
	else
		mxX=mxX2;
	end
	if any(X>=mxX)
		warning('SPLITBITS:maxSaturation','some values are higher than maximum!')
		X=min(X,mxX-1);
	end
	nB=nBits;
elseif any(X<0)
	error('Only positive values are allowed, or use "splitbits(X,nBits)" ')
else
	nB=ceil(log2(max(X)));
end

nBit=0;
B=zeros(length(X),nB);
while any(X)
	nBit=nBit+1;
	B(:,nBit)=rem(X,2);
	X=floor(X/2);
end
