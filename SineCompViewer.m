function [varargout] = SineCompViewer(varargin)
%SineCompViewer - sine wave component viewer (UI creation to show DFT components)
%
%       SineCompViewer()   - starts UI based on current (single line) graph

% first argument
%    commands (like remove lines)
%    handle

%!!! if figure contains multiple lines!!!!!

%!! phase is bijna OK!!!!!!
%       niet bepalen via fft maar via sin/cos bepaling (met integrale periode?)?

fBase = gcf;

nPmax = 100;
relAmin = 1e-10;

if nargin
	setoptions({'nPmax','relAmin'},varargin{:})
end

fWin = @(n) sin((0:n-1)*(pi/n)).^2;	% better than hanning and han (!)
[fFFT,Dfft] = plotffts(fBase,'windowUsed',fWin,'-bHalfFFT');
Dfft.fBase = fBase;
Dfft.lSine = line(Dfft.T(1),Dfft.X(1),'color',[1 0 0]	...
	,'Parent',get(Dfft.l,'Parent')	...
	,'Tag','SineLine'	...
	);
nFFT = length(Dfft.T);
F = Dfft.F;
Z = Dfft.Z;

[Dfft.Fpk,Dfft.Apk,Dfft.ph_pk] = CalcPeak(F,Z,nFFT,nPmax,relAmin,Dfft.T(1));

lPk = line(Dfft.Fpk,Dfft.Apk,'linestyle','none','marker','o','color',[1 0 0]	...
	,'ButtonDownFcn',@PeakLineClicked);
set(lPk,'UserData',Dfft);
set(fFFT,'CloseRequestFcn',@CloseWin	...
	,'UserData',lPk)

function [f,A,ph]=CalcPeak(x,Z,nFFT,nPeaks,relAmin,t0)
f  = zeros(1,nPeaks);
A  = f;
ph = f;

y = abs(Z);
Amin = max(y)*relAmin;
df = x(2)-x(1);

% remove DC
i2 = 2;
while i2<=length(y) && y(i2)<=y(i2-1)
	i2 = i2+1;
end
y(1:i2-1)=0;

% remove nyquist frequency (unreliable anyway, but mainly to avoid problems)
y(end-1:end) = 0;

for i=1:nPeaks
	[Xmax,iMax]=max(y);
	if Xmax<=Amin	% other conditions to stop? !!!!
		f = f(1:i-1);
		A = A(1:i-1);
		ph = ph(1:i-1);
		break;
	end
	Xm_p=y(iMax-1);	% previous
	Xm_n=y(iMax+1);	% next
	s=sign(Xm_n-Xm_p);

	switch s
		case -1	% Xm_n < Xm_p
			r=Xmax/Xm_p;
			p=(r-2)/(r+1);
			i_f=iMax+p;
			A(i)=(1-p^2)/sinc(p)*Xmax;
		case 0	% Xm_n = Xm_p
			A(i)=Xmax;
			i_f=iMax;
		case 1	% Xm_n > Xm_p
			r=Xmax/Xm_n;
			p=(2-r)/(r+1);
			i_f=iMax+p;
			A(i)=(1-p^2)/sinc(p)*Xmax;
	end
	
	% second iteration
	i_0=floor(i_f);
	ii=(i_0-1:i_0+2);
	ph0=angle(Z(i_0));
	
	% aliasing around DC
	rr=ii+i_f-2;
	Zoffset=abs(sinc(rr)./(rr.^2-1))*A(i)*exp(-1i*(pi+ph0));
	Z(ii)=Z(ii)-Zoffset;
	% aliasing around fs/2
	rr=ii-(nFFT-i_f)-2;
	Zoffset=abs(sinc(rr)./(rr.^2-1))*A(i)*exp(-1i*ph0);
	Z(ii)=Z(ii)-Zoffset;

	Xmax(i)=abs(Z(iMax));

	switch s
		case -1	% Xm_n < Xm_p
			Xm_p=abs(Z(iMax-1));
			r=Xmax(i)/Xm_p;
			p=(r-2)/(r+1);
			i_f=iMax+p;
			A(i)=(1-p^2)/sinc(p)*Xmax(i);
		case 0	% Xm_n = Xm_p
			A(i)=Xmax(i);
			i_f=iMax;
		case 1	% Xm_n > Xm_p
			Xm_n=abs(Z(iMax+1));
			r=Xmax(i)/Xm_n;
			p=(2-r)/(r+1);
			i_f=iMax+p;
			A(i)=(1-p^2)/sinc(p)*Xmax(i);
	end

	f(i)  = (i_f-1)*df;
	A(i)  = A(i);
	ph(i) = mod(angle(Z(i_0))'-pi*rem(i_f,1)-t0*f(i)*2*pi	...
		,2*pi);
	
	% prepare for next peak
	%      put peak to 0 for next peaks
	i1 = iMax-1;
	while i1>=1 && y(i1)<=y(i1+1)
		i1 = i1-1;
	end
	i2 = iMax+2;
	while i2<=length(y) && y(i2)<=y(i2-1)
		i2 = i2+1;
	end
	y(i1+1:i2-1)=0;
end		% for i (nPeaks)
A=A*2;

function PeakLineClicked(l,ev)
D = get(l,'UserData');
i = findclose(D.Fpk,ev.IntersectionPoint(1));
y = D.Apk(i)*cos((2*pi*D.Fpk(i))*D.T+D.ph_pk(i));
if ev.Button==1
	set(D.lSine,'XData',D.T,'YData',D.Xdc+y)
elseif ev.Button==3
	y = y+get(D.lSine,'YData');
	set(D.lSine,'XData',D.T,'YData',y)
end

function CloseWin(f,~)
lPk = get(f,'UserData');
D = get(lPk,'UserData');
if ~isstruct(D)||~ishandle(D.lSine)
	warning('No sine-line?!')
else
	delete(D.lSine)
end
delete(f)
