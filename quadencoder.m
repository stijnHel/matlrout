function [C,dC]=quadencoder(A,B,varargin)
%quadencoder - does quadrature encoder decoding
%    C=quadencoder(A) - encoder signals coded in integer
%        multiple encoder signals can be combined (bit1|0, bit3|2, ...)
%    C=quadencoder(A,B) - separate A and B vector
%           (or C=quadencoder(A,B,false))
%    C=quadencoder(A,B,true) - sincos-encoder

nMaxEncoders=4;

if nargin==1
	AB=A;
	if min(size(AB))==1
		if any(AB<0)||any(AB~=floor(AB))
			error('Input must be a non-negative integer vector!')
		end
		nEncoders=min(nMaxEncoders,ceil(log2(max(AB))/2));
		C=zeros(length(AB),nEncoders);
		if nargout>1
			dC=zeros(length(AB),nEncoders*2);
		end
		fEnc=1;
		for iEnc=1:nEncoders
			A=bitand(AB,fEnc);
			B=bitand(AB,fEnc*2);
			C(:,iEnc)=quadencoder(A,B);
			fEnc=fEnc*4;
			if nargout>1
				dC(:,iEnc*2-1)=A;
				dC(:,iEnc*2)=B;
			end
		end
		return
	elseif min(size(AB))==2
		if size(AB,1)==2&&size(AB,2)>2
			AB=AB';
		end
		A=AB(:,1);
		B=AB(:,2);
	else
		if diff(size(AB))>0
			AB=AB';
		end
		n=floor(size(AB,2)/2);
		C=zeros(size(AB,1),n);
		for i=1:n
			C(:,i)=quadencoder(AB(:,i*2-1:i*2));
		end
		return
	end
elseif nargin==2||(nargin>2&&~varargin{1})
	A=A~=0;
	B=B~=0;
else
	C=unwrap(atan2(B,A))/(2*pi);
	if nargin>1
		dC=diff(C);
	end
	return
end

dA=diff(A(:));
dB=diff(B(:));
%dC=(dA|dB).*((A(1:end-1)~=B(2:end))*2-1);
dC=(dA|dB).*((A(2:end)~=B(1:end-1))*2-1);
C=[0;cumsum(dC)];
if any(dA&dB)
	warning('QUEADenc:simulChange','simultaneous changes on A and B! (%d)',sum(dA&dB))
end
