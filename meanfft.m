function [Y,F,YY]=meanfft(X,Nfft,dt)
%meanfft  - FFT with averaging
%    [Y,F]=meanfft(X,Nfft,dt)
%    [Y,F]=meanfft(X,[0 nBlocks],dt)

if size(X,1)<size(X,2)
	X=X';
end
if size(X,2)>1
	if nargin<3
		Y=meanfft(X(:,1),Nfft);
	else
		[Y,F]=meanfft(X(:,1),Nfft,dt);
	end
	Y(1,size(X,2))=0;
	for i=2:size(Y,2)
		Y(:,i)=meanfft(X(:,i),Nfft);
	end
	return
end

X=X-mean(X);
if length(Nfft)>1
	X=reshapetrunc(X,[],Nfft(2));
	Nfft=size(X,1);
else
	X=reshapetrunc(X,Nfft,[]);
end
W=hanning(Nfft)*(2/Nfft);
YY=abs(fft(bsxfun(@times,X,W)));
Y=sqrt(mean(YY.^2,2))*1.63;
if nargout>1
	F=(0:Nfft-1)'/Nfft/dt;
end
