function [f,fFFT]=buneman(x,fs)
%buneman  - Calculates buneman frequency estimation
%   f=buneman(x[,fs])
%
%  Is supposed to be correct for pure sine waves, but it seems not to be
%  OK.  (better to use "StoneHann"!)
%
% see also StoneHann

if nargin<2
	fs=1;
end

if size(x,1)==1
	x=x';
end
A=abs(fft(x-mean(x)));
%A=abs(fft((x-mean(x))).*hanning(length(x)));
N=length(x);
[Amx,imx]=max(A(1:floor(N/2)));
B=imx-1+N/pi*atan(sin(pi/N)./(cos(pi/N)+A(imx)./A(imx+1)));
f=B*fs/N;
if nargout>1
	fFFT=(imx-1)*fs/N;
end
