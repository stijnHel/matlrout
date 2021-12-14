function [f,df]=estimf_FFT(x,dt,varargin)
%estimf_FFT - estimates frequency using FFT
%    [f,df]=estimf_FFT(x,dt[,options])
%          options N : max 
N=[];
if ~isempty(varargin)
	setoptions({'N'},varargin{:})
end
if isempty(N)
	N=max(length(x),65536);
elseif length(x)>N
	warning('Only first part of signal is used')
	x=x(1:N);
end
N4=floor(N/4);
Y=abs(fft((x-mean(x)).*hamming(length(x)),N));
Y=Y(1:N4);
Y(1:ceil(N/length(x)*2.1)+1)=0;
[~,i]=max(Y);
%f=(i-1)/dt/N;
f=((i-2:i)*Y(i-1:i+1))/(sum(Y(i-1:i+1))*dt*N);
df=1/(dt*N);
