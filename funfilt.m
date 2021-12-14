function y=funfilt(x,dt,f0,nHarm,dN)
% FUNFILT - frequentie-uitfiltering - op basis van fft
%     y=funfilt(x,dt,f0[,nHarm[,dN]])
%         x : signaal
%         dt : tijdstap
%         f0 : uit te filteren frequentie
%         nHarm : aantal harmonischen uit te filteren
%            (-1 : alle, default 0)
%         dN : aantal punten in frequentiedomein rond f0 op nul te zetten

if ~exist('nHarm','var')|isempty(nHarm)
	nHarm=0;
end
if ~exist('dN','var')|isempty(dN)
	dN=5;
end
if length(dt)~=1|dt<=0
	error('Onmogelijke waarde voor dt')
end

mx=mean(x);
iF=round(length(x)*f0*dt);
Nextra=0;
if abs(round(iF)-iF)>.1
	kf0=1/(f0*dt);
	if abs(kf0-round(kf0))>1e-6
		warning('f0 is geen veelvoud van f_samp - dit is niet ideaal')
	else
		Nextra=ceil(length(x)/iF)*iF-length(x);
	end
end
x=x-mx;
if Nextra
	if size(x,1)==1
		x=[x zeros(1,Nextra)];
	else
		x=[x;zeros(Nextra,1)];
	end
end
X=fft(x);

if nHarm
	if nHarm<0
		nHarm=1e5;
	end
	n=min(nHarm+1,floor(0.5/dt/f0+0.9));
else
	n=1;
end
for i=1:n
	iF=round(i*(length(x)+Nextra)*f0*dt);
	X(2+iF-dN:2+iF+dN)=0;
	X(end-iF-dN:end-iF+dN)=0;
end
yc=ifft(X);
if max(abs(imag(yc)))>max(abs(real(yc)))/1e5
	warning('!!!!geen verwaarloosbaar imaginair gedeelte!!!??')
end
y=real(yc)+mx;
if Nextra
	y=y(1:length(x));
end
