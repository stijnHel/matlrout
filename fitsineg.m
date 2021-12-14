function D=fitsineg(t,x,varargin)%fitsineg - Fit sine through a number of points with a more global parameter search%    D=fitsineg(t,x[,options])%   Fits a sine wave through a signal from which it is expected to be close%   to a sine wave with a constant frequency.  Compared to fitsine, the%   optimisation is better.%!!!!!!!!!!!!!!!!not yet ready!!!!!!!!!!!!!!%   It is not necessary to have equidistant points.%  possible options : (pairs of option name and value)%    fSet    : fixed frequency%      the following options are only used if no given frequency%        and are used to do an estimate of the frequency%       fFilter : filter frequency (f<=0 ==> no filtering)%            second order high pass butter filtfilt is used%       bPerc   : interprete fLimH as "percentile" of all data,%           otherwise rLimH refers to relationship between min/max%       rLimH   : input for calculating high and low level part for%           searching for minima and maxima%   The calculation is done in two steps: "guessing" and "improving"%     The "guessing"-algorithm (calculating starting values) is done%     differently if the frequency is given or not.%     Frequency not given:%         - filter signal if requested%         - search for all local minima and maxima is done%             this is based on finding successive high values and%             successive low values;%             through all these extreme a 2nd order polynomial is fitted%             and the positions and values of the maxima are used as "tops"%             and "bottoms"%         - from these, the DC value, amplitude, time offset and frequency%             are estimated.%     Frequency is given: (kind of fourier data of on frequency is done)%         the DC component is calculated by calculating the mean value over%            a whole number of cycles.%         the DC component is subtracted from the signal to calculated the%            following%         by calculating the sum of the product of the signal with a sine%            and cosine of the given frequency over a full number of cycles,%         the phase and amplitude is calculated from this%     The estimated DC component, amplitude, time offset and if necessary%        frequency are updated successively by a cpu intensive, simple%        algorithm.  The error value (between the calculated sine and%        (unfiltered) signal is calculated for a couple of values.  A 2nd%        order polynomial is fitted, and the minimum value is used, if this%        is between estimated limits.%%   see also fitsinebPerc=false;	% percentile calculation for limits rather than just min/maxrLimH=0.8;fFilter=0;fSet=[];if ~isempty(varargin)	setoptions({'rLimH','bPerc','fFilter','fSet'},varargin{:})enddt=mean(diff(t));if ~isempty(fSet)	if fSet>0	% given and fixed		% Check if given frequency can be right		f=fSet;		nCyc=(t(end)-t(1))*fSet;		if nCyc<1.1			error('!!!low number of sine waves in measurement (%g)!!!',nCyc)		end		nPts=round(floor(nCyc)/(f*dt));		if nPts<1			warning('Given frequency can''t be right for this data!')			fSet=-1;		else	% other checks?		end	end	if fSet<=0	% fixed but not given		N=65536;		N4=N/4;		Y=abs(fft(x.*hamming(length(x)),N));		Y=Y(1:N4);		[mxY,i]=max(Y);		fSet=(i-1)/dt/N;		fprintf('      fixed frequency : %g Hz\n',fSet)		f=fSet;		nCyc=(t(end)-t(1))*f;		nPts=round(floor(nCyc)/(f*dt));	endend% Search for starting values for f, A, tOffset, DCif isempty(fSet)	if fFilter>0		if fFilter>1			if std(diff(t))/dt>1e-4				warning('Simple filtering used on non-equidistant data!!!')			end			rFilter=fFilter*dt;		else			rFilter=fFilter;		end		[Bf,Af]=butter(2,rFilter);		xf=filtfilt(Bf,Af,x);	else		xf=x;	end	if bPerc		xs=sort(xf);		Xh=xs(ceil(rLimH*length(xf)));		Xl=xs(ceil((1-rLimH)*length(xf)));		xmiddle=xs(ceil(length(xf)/2));	else		mx=max(xf);		mn=min(xf);		pkpk=mx-mn;		Xh=mn+pkpk*rLimH;		Xl=mn+pkpk*(1-rLimH);		xmiddle=(mx+mn)/2;	end	a=(xf(1)>=xmiddle)-1;	xST=zeros(size(xf));	xST(1)=a;	for i=2:length(xf)		if a>0			if xf(i)<=Xl				a=-1;			end		elseif xf(i)>=Xh			a=1;		end		xST(i)=a;	end	iCH=find(diff(xST));	E=zeros(length(iCH)-1,3);	E(:)=NaN;	if length(iCH)<4		iStart=1;	%????OK??		warning('!!!!low number of cycles!!!(??)!!')	else		iStart=2;	end	for i=iStart:length(iCH)-1 %(start from second (probably first whole cycle))		j=iCH(i)+1:iCH(i+1)-1;		if xST(j(1))>0			k=find(xf(j)>=Xh);		else			k=find(xf(j)<=Xl);		end		if length(k)<3			warning('!!To low number of points!!!')		else			j=j(k(1)):j(k(end));			t1=t(j);			[p,S,Mu]=polyfit(t1,xf(j),2);			if p(1)*xST(j(1))>=0				warning('!!unexpected extreme profile!!')			else				tmx1=-p(2)/(2*p(1));				tmx=tmx1*Mu(2)+Mu(1);				if tmx<t1(1)|tmx>t1(end)					warning('too high correction for extreme (%g s)!!',tmx)				else					E(i,1)=tmx;					Eex=polyval(p,tmx1);					E(i,(xST(j(1))<0)+2)=Eex;				end			end	% p(1)*xST(j(1)) OK		end	% length(k) OK	end %for i	iOK=find(~isnan(E(:,1)));	if length(iOK)<2		error('Not enough good points found')	end	if all(isnan(E(iOK,2)))|all(isnan(E(iOK,3)))		error('No maximum or minimum could be determined!!')	end	dtOK=(E(iOK(2:end))-E(iOK(1:end-1)))./diff(iOK);	iNOK=find(isnan(E(:,1)));	mnDif=(E(iOK(end))-E(iOK(1)))/(iOK(end)-iOK(1));	meanT=mean(dtOK);	if length(dtOK)>1		delT=max(std(dtOK),meanT/1e4);	else		delT=max(2*dt,meanT/50);	%!!!	end	if (meanT-dtOK)/meanT>0.2|delT/meanT>0.2		error('too much changes in dt --- something went wrong in estimations')	end	f=0.5/mnDif;	df=f*(delT/mnDif/sqrt(iOK(end)-iOK(1)));	iMax=find(~isnan(E(:,2)));	iMin=find(~isnan(E(:,3)));	newMax=mean(E(iMax,2));	newMin=mean(E(iMin,3));	A=(newMax-newMin)/2;	if length(iMax)==1		dMax=A/3;	else		dMax=max(A/1e4,std(E(iMax,2)));	end	if length(iMin)==1		dMin=A/3;	else		dMin=max(A/1e4,std(E(iMin,3)));	end	dA=sqrt(dMin*dMin+dMax*dMax);	% worth doing this, rather than just adding min/max?	dA=max(dA,A/100);	DC=(newMax+newMin)/2;	T=(0:size(E,1)-1)'*mnDif;	offset=E(iOK)-T(iOK);	mnOffset=mean(offset);	if length(offset)>1		dOffset=max(mnDif/10,std(offset));%%	else		dOffset=mnDif/10;	end	tOffset=mnOffset;	dDC=dA;else	% fixed frequency calculation	i=1:nPts;	DC=mean(x(i));	Zx=sum((x(i)-DC).*sin(f*2*pi*t(i)));	Zy=sum((x(i)-DC).*cos(f*2*pi*t(i)));	A=sqrt(Zx*Zx+Zy*Zy)/(length(i)/2);	phi=atan2(Zx,Zy);	tOffset=phi/(2*pi*f);	dA=A/10;	df=0;	dDC=dA;	dOffset=0.1/f;	xf=x;	mnDif=[];meanT=[];delT=[];E=[];endy0=cos((t-tOffset)*(f*2*pi))*A+DC;	% just for optimisation effecte0=sqrt(mean((x-y0).^2));if isempty(fSet)	P0=[tOffset;f;A;DC];	[P,e,fExit] = fminsearch(@(P) optimfunwithf(P,t,x),P0);	tOffset=P(1);	f=P(2);	A=P(3);	DC=P(4);else	P0=[tOffset;A;DC];	[P,e,fExit] = fminsearch(@(P) optimfunwithoutf(P,t,x,fSet),P0);	tOffset=P(1);	A=P(2);	DC=P(3);endy=cos((t-tOffset)*(f*2*pi))*A+DC;e1=sqrt(mean((x-y).^2));phase=-tOffset*2*f*pi;D=struct('t',t,'x',x,'xf',xf	...	,'A',A,'dA',dA,'P',mnDif,'P_est2',meanT,'dP',delT	...	,'f',f,'df',df	...	,'DC',DC,'dDC',dDC,'toffset',tOffset,'dtoffset',dOffset	...	,'phase',phase	...	,'E',E	...	,'y',y,'e0',e0,'e',e,'e1',e1	...	);function e=optimfunwithf(P,t,y)tOffset=P(1);f=P(2);A=P(3);DC=P(4);y1=cos((t-tOffset)*(f*2*pi))*A+DC;e=sqrt(sum((y1-y).^2));function e=optimfunwithoutf(P,t,y,f)tOffset=P(1);A=P(2);DC=P(3);y1=cos((t-tOffset)*(f*2*pi))*A+DC;e=sqrt(mean(((y1-y).^2)));