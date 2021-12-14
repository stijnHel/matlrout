function [yi,varargout]=interpfft(xi,N)
%interpfft - interpolate using fft-domain
%   similar to interpft, except for the addition of calculation of
%   derivatives
%
%    [YI,dYI/dt,d2dYI/dt2,...]=interpfft(xi,N);
%  xi must have data in columns

if N<length(xi)
	warning('Interpolation function used but data is decimated!')
end
if size(xi,1)==1
	xi=xi';
end
[n,m]=size(xi);

n2=ceil((n+1)/2);
N2=ceil((N+1)/2);

XI=fft(xi,[],1);
if N<length(xi)
	if rem(N,2)
		YI=XI([1:N2 n-N2+2:n],:);
	else
		YI=[XI(1:N2-1,:);zeros(1,m);XI(n-N2+3:n,:)];
	end
elseif N>length(xi)
	YI=[XI(1:n2,:);zeros(N-n,m);XI(n2+1:n,:)];
	if rem(N,2)==0
		YI(n2,:)=YI(n2,:)/2;
		YI(n2+N-n,:)=YI(n2,:);
	end
else
	YI=XI;
end
YI=YI*(N/n);
yi=ifft(YI,[],1,'symmetric');

if nargout>1
	varargout=cell(1,nargout-1);
	YI(1)=0;
	WI=(1:N2-1)'*(2i*pi/N);
	for i=1:nargout-1
		YI(2:N2)=YI(2:N2).*WI;
		YI(end:-1:end-N2+2)=YI(end:-1:end-N2+2).*WI;
		varargout{i}=ifft(YI,[],1,'symmetric');
	end
end
