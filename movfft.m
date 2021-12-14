function [Auit,F,f,t]=movfft(x,l,di,n,i0,ts)
% MOVFFT - moving fft
%
%        [A,F]=movfft(x,l,di,n,i0,ts)
% bepaalt 'n' fft's met lengte 'l' van delen van vector 'x'.  De eerste fft
% is de fft van de vector die begint bij 'x(i0)'.  De volgende fft wordt
% genomen van een vector die 'di' verder ligt.
% Vooraleer de fft's genomen worden, worden de nulde en eerste orde termen
% uit de gegevens gehaald om de fft's minder te verstoren.
% ts wordt gebruikt wanneer er een contourplot getekend wordt.
%
% Als n niet gegeven is (of kleiner dan 1), worden alle mogelijke fft's gehouden.
% Als di niet gegeven is (of kleiner dan 1), wordt 1 genomen.
% Als i0 niet gegeven is (of kleiner dan 1), wordt 1 genomen.
%
% Enkel de eerste helft van de fft wordt behouden.
%
% Het resultaat kan bijvoorbeeld getoond worden door :
%    contour((0:n-1)*(ts*di),1/ts/l*(0:l/2),A)
% of
%    imagesc((0:n-1)*(ts*di),1/ts/l*(0:l/2),A);axis('xy')
%   of A vervangen door log(A)
% Als er geen resultaat gevraagd is wordt dit gedaan (ts_default=1).
if nargin==0
	help movfft
	return
end
if length(x)<50
	error('Te korte data voor nuttige spectraal-analyse')
end
if ~exist('l','var')|isempty(l)
	l=1024;
	while l<length(x)
		l=l/2;
	end
end
if nargin<5
	i0=1;
	if nargin<4
		n=[];
		if nargin<3
			di=1;
			if nargin<2
				error('Er moeten juist 5 input-parameters zijn.')
			end
		elseif di<1
			di=1;
		end
	end
end
if ~exist('di','var')|isempty(di)
	di=max(1,round(l/2));
end
if isempty(i0)|i0<1
	i0=1;
end
if isempty(n)|n<1
	n=floor((length(x)-i0+1-l)/di);
end
if l<2
	error('de lengte van de ffts moet minstens 2 zijn.')
end
if i0+di*(n-1)+l-1>length(x)
	error('vector is te kort om deze ffts te kunnen maken')
end
if i0+di*(n-1)+l-1<1
	error('ffts komen voor het begin van de vector uit vanwege de negatieve offset.')
end
N=round((l+1)/2);

A=zeros(N,n); % reserveer geheugen
F=zeros(N,n);

i1=i0;
for i=1:n
	Z=fft(detrend(x(i1:i1+l-1)));
	A(:,i)=abs(Z(1:N));
	F(:,i)=angle(Z(1:N));

	i1=i1+di;
end
if ~exist('ts','var')|isempty(ts)
	ts=1;
end
t=(0:n-1)*ts*di;
f=1/ts/l*(0:l/2);
if nargout==0
	if nargin<6
		ts=1;
	end
%	contour(t,f,A);
	imagesc(t,f,log(A));axis('xy')
else
	Auit=A;
end
