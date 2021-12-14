function specanal(x,N,N1,Noverlap,f0,f,ordes,wind,metspline,logplot)
% SPECANAL - spectrogram-analyse
%     specanal(x,N,N1,f0,f,ordes,wind,metspline,metlog)
%        x  : tijd en te analyseren signaal
%        N  : lengte van de fourier
%        N1 : lengte van het gebruikte gedeelte van de fourier (indien gegeven)
%        Noverlap : de 'overlap' van het spectrogram
%        f0 : filter-frequentie (voor highpass) (indien gegeven)
%        f  : tijd en frequentie om orde van frequentie te bepalen
%        wind : te gebruiken window (default hamming)
%        logplot : logaritmische plot


global X F T dt lx O
global SPECANALspline SPECANALlog

if nargin<3
	error('Minstens 2 inputs moeten gegeven worden');
end

if ~exist('metspline')|isempty(metspline)
	if ~isempty(SPECANALspline)
		metspline=SPECANALspline;
	end
end
if ~exist('logplot')|isempty(logplot)
	if isempty(SPECANALlog)
		SPECANALlog=true;
	end
	logplot=SPECANALlog;
end

if ~isempty(x)
	SIGtb=1;
	dt=x(2,1)-x(1,1);
	lx=length(x);
	if abs(diff(x(:,1))-dt)
		error('Er moet gesampled zijn met equidistante punten');
	end
	if exist('f0')&~isempty(f0)
		try
			[B,A]=butter(4,f0*2*dt,'high');
			xf=filtfilt(B,A,x(:,2));
		catch
			xf=x;
			warning('!!!high-pass filter werkte niet, mogelijk signal processing toolbox niet beschikbaar!!')
			SIGtb=0;
		end
	else
		xf=x(:,2);
	end

	if ~exist('N1')|isempty(N1)
		N1=N;
	end

	if ~exist('Noverlap')|isempty(Noverlap)
		Noverlap=N1/2;
	end
	if exist('wind')&~isempty(wind)
		if ischar(wind)
			eval(['wind=' wind '(N1);']);
		end
	else
		try
			wind=hamming(N1);
		catch
			wind=0.5-cos((0:N1-1)'/(N1-1)*2*pi)/2;
			if SIGtb
				warning('!!!window-bepaling werkte niet, mogelijk signal processing toolbox niet beschikbaar!! - eenvoudig cos-window werd genomen')
				SIGtb=0;
			end
		end
	end
	X0=max(abs(fft([wind'.*sin((0:N1-1)*2*pi/10) zeros(1,N-N1)])));
	[X,F,T]=specgram(xf,N,1/dt,wind,Noverlap);
	X=abs(X)/X0;
	T=T+N1/2*dt;
end
nfigure
if logplot
	imagesc(T,F,log(X))
else
	imagesc(T,F,X)
end
grid
axis xy

if exist('f')&~isempty(f)
	if size(f,2)==1
		dt2=dt*round(lx/length(f));
		t2=(0:length(f)-1)*dt2;
	else
		t2=f(:,1);
		f=f(:,2);
	end
	line(t2,f,'color',[1 0 0])
	if exist('ordes')&~isempty(ordes)
		status('Berekenen van de ordes',0)
		if T(2)-T(1)>mean(diff(t2))*2
			[B,A]=butter(2,2*mean(diff(t2))/(T(2)-T(1)));
			f=filtfilt(B,A,f);
		end
		if exist('metspline')&length(metspline)==1&metspline==1
			f1=interp1([-1;t2(:);T(end)*2],f([1 1:end end]),T,'spline');
		else
			f1=interp1([-1;t2(:);T(end)*2],f([1 1:end end]),T);
		end
		if max(f1)*ordes(end)>F(end)
			fprintf('!!Hoge freq''s (%5g > %5g)!!  Frequentiegebied wordt uitgebreid\n',max(f1)*ordes(end),F(end))
			F1=[F;F(2:end-1)+F(end)];
			X1=[X;X(end-1:-1:2,:)];
			while max(f1)*ordes(end)>F1(end)
				F1=[F1;F1(1:length(F)*2-2)+F(end)*2];
				X1=[X1;X1(1:length(F)*2-2,:)];
			end
		else
			F1=F;
			X1=X;
		end
		O=zeros(length(ordes),length(T));
		for i=1:length(T)
			fo=f1(i)*ordes;
			j=find(fo<=F1(end));
			if exist('metspline')&length(metspline)==1&metspline==1
				O(j,i)=interp1(F1,X1(:,i),fo(j),'spline')';
			else
				O(j,i)=interp1(F1,X1(:,i),fo(j))';
			end
			status(i/length(T))
		end
		status
		nfigure
		if abs(std(diff(ordes)))/mean(diff(ordes))<0.001
			if logplot
				imagesc(T,ordes,log(O))
			else
				imagesc(T,ordes,O)
			end
			grid;axis xy
		else
			if logplot
				imm=pcolor(T,ordes,log(O));
			else
				imm=pcolor(T,ordes,O);
			end
			grid
			set(gca,'layer','top')
			set(imm,'FaceColor','interp','LineStyle','none')
		end
		xlabel 'tijd [s]'
		ylabel orde
	end
end
