function [y,yFFT]=resamplefft(x,fRe,bWindow)
%resamplefft - Resamples a signal using FFT
%   y=resamplefft(x,fRe[,bWindow])
%         fS(y) = fS(x) * fRe
%       fractional resampling factors are rounded to a possible factor
%    if fRe<=1, the original vector is given as output
%
%    (!)the fft is taken from x, high calculation time can be needed for
%    long input vectors, especially if length is not a power of two
%    resampling factors which are a power of two will also give faster
%    calculations

if ~exist('bWindow','var')||isempty(bWindow)
	bWindow=true;
end
if min(size(x))~=1
	error('Only vectors are allowed as input!')
end
if fRe<=1
	y=x;
	return
end
n=length(x);
if n<4
	error('Not enough points for resampling')
end
bTrans=size(x,2)>1;
if bTrans
	x=x';
end
if bWindow
	x=x.*hanning(n);
end
X=fft(x);
nNew=round(n*fRe);
if rem(n,2)
	n1=(n+1)/2;
	Y=[X(1:n1);zeros(nNew-n+1,1);conj(X(n1:-1:2))];
else
	n1=n/2+1;
	X(n1)=X(n1)/2;
	Y=[X(1:n1);zeros(nNew-n,1);conj(X(n1:-1:2))];
end
y=real(ifft(Y))*(length(Y)/length(x));
if bWindow
	H=hanning(length(y));
	h1=H(round(fRe*10));	% don't amplify end parts too much
	y=y./max(H,h1);
end
if bTrans
	y=y';
end
if nargout>1
	yFFT=Y;
end
