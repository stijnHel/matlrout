function [f,A,ph,D]=StoneHann(x,f_s,fRange,nFFT)
%StoneHann - extract single tone information from Hanning spectrum
%    [f,A,ph]=StoneHann(x,fSampling,fRange,nFFT)
%        peak in FFT (with hann window) is retrieved, corrections for
%        aliasing is done, and the the peak frequency ("subsampled DFT") is
%        retrieved, frequency, amplitude and phase
%     (based on LabVIEW code)

if ~exist('nFFT','var')
	nFFT=[];
end
if ~exist('f_s','var')||isempty(f_s)
	f_s=1;
end
if ~exist('fRange','var')
	fRange=[];
end
if nargin==0||isempty(x)
	[X,Xi]=getsigs;
	if isnumeric(X)
		X={X};
	elseif any(cellfun(@iscell,X))
		for i=1:length(X)
			if ~iscell(X{i})
				X{i}=X(i);
			end
		end
		X=[X{:}];
	end
	if nargout
		f=zeros(1,length(X));
		A=f;
		ph=f;
		D=cell(1,length(X));
	end
	for i=1:length(X)
		X1=X{i};
		x=X1(X1(:,3)>0,1);
		if length(x)<6
			warning('STONEHANN:lowNrPoints','too low number of points (#%d: %d-',i,length(x))
		else
			y=X1(X1(:,3)>0,2);
			f_s=1/median(diff(x));
			[f1,A1,ph1,D1]=StoneHann(y,f_s,fRange,nFFT);
			if nargout
				f(i)=f1;
				A(i)=A1;
				ph(i)=ph1;
				D1.line=Xi(i);
				D{i}=D1;
			else
				fprintf('#%2d: f=%10g Hz, A=%10g, ph=%10g rad\n',i,f1,A1,ph1)
			end
		end		% end if x OK
	end		% end for
	if nargout
		D=cat(2,D{:});
	end
	return
end
if isempty(nFFT)
	nFFT=length(x);
end

%win=hanning(length(x));	not used because different result
%         hann is different too
win=sin((0:length(x)-1)'*(pi/length(x))).^2;
DC=mean(x);	% prevent influence of "excessive" DC (in combination with window)
y=(x(:)-DC).*win*(sqrt(2)/(nFFT/2));
if nFFT<=0
	nFFT=length(y);
	Z=fft(y);
else
	Z=fft(y,nFFT);
end
Z=Z(1:floor((length(Z)+1)/2));
Z(1)=Z(1)/sqrt(2);
X=abs(Z);
X(1:2)=0;	% avoid DC selection
Z0=Z;

if length(X)>nFFT/2
	X=X(1:floor(nFFT/2));
end

% first iteration
if isempty(fRange)
	[Xmax,iMax]=max(X);
	bPeakOK = iMax>1&&iMax<length(X);
elseif length(fRange)==1 || isvector(fRange)&&diff(fRange)<=0	% set frequency
	% not known if this can give useful results!!!
	iMax=round(fRange(1)/(f_s/nFFT))+1;
	Xmax=X(iMax);
	bPeakOK = iMax>1&&iMax<length(X);
else	% possible to have multiple ranges
	if size(fRange,2)==1
		fRange=fRange';
	end
	Xmax=zeros(1,size(fRange,1));
	iMax=Xmax;
	bPeakOK = true(1,length(Xmax));
	for i=1:length(Xmax)
		iRange=fRange(i,:)/(f_s/nFFT)+1;
		i1=max(1,floor(iRange(1)));
		i2=min(length(X),ceil(iRange(2)));
		if i1>=length(X)||i2<2
			error('frequency request out of range')
		elseif i2-i1<=1
			i1=i1-1;
			i2=i2+1;
		end
		[Xmax(i),iMax(i)]=max(X(i1:i2));
		if iMax(i)==1||iMax(i)==i2-i1+1
			bPeakOK(i) = false;
		end
		iMax(i)=iMax(i)+i1-1;
	end
end

f=zeros(1,length(iMax));
A=f;
ph=f;
i_0=ones(1,length(iMax));
i_f=i_0;
for i=1:length(iMax)
	if bPeakOK(i)
		Xm_p=X(iMax(i)-1);	% previous
		Xm_n=X(iMax(i)+1);	% next
		s=sign(Xm_n-Xm_p);

		switch s
			case -1	% Xm_n < Xm_p
				r=Xmax(i)/Xm_p;
				p=(r-2)/(r+1);
				i_f(i)=iMax(i)+p;
				A(i)=(1-p^2)/sinc(p)*Xmax(i);
			case 0	% Xm_n = Xm_p
				A(i)=Xmax(i);
				i_f(i)=iMax(i);
			case 1	% Xm_n > Xm_p
				r=Xmax(i)/Xm_n;
				p=(2-r)/(r+1);
				i_f(i)=iMax(i)+p;
				A(i)=(1-p^2)/sinc(p)*Xmax(i);
		end

		% second iteration
		i_0(i)=floor(i_f(i));
		if i_0(i)+2>length(Z)
			i_0(i)=length(Z)-2;	%!!!!!
		end
		ii=(i_0(i)-1:i_0(i)+2)';
		ph0=angle(Z(i_0(i)));
		% aliasing around DC
		rr=ii+i_f(i)-2;
		Zoffset=abs(sinc(rr)./(rr.^2-1))*A(i)*exp(-1i*(pi+ph0));
		Z(ii)=Z(ii)-Zoffset;
		% aliasing around fs/2
		rr=ii-(nFFT-i_f(i))-2;
		Zoffset=abs(sinc(rr)./(rr.^2-1))*A(i)*exp(-1i*ph0);
		Z(ii)=Z(ii)-Zoffset;

		Xmax(i)=abs(Z(iMax(i)));

		switch s
			case -1	% Xm_n < Xm_p
				Xm_p=abs(Z(iMax(i)-1));
				r=Xmax(i)/Xm_p;
				p=(r-2)/(r+1);
				i_f(i)=iMax(i)+p;
				A(i)=(1-p^2)/sinc(p)*Xmax(i);
			case 0	% Xm_n = Xm_p
				A(i)=Xmax(i);
				i_f(i)=iMax(i);
			case 1	% Xm_n > Xm_p
				Xm_n=abs(Z(iMax(i)+1));
				r=Xmax(i)/Xm_n;
				p=(2-r)/(r+1);
				i_f(i)=iMax(i)+p;
				A(i)=(1-p^2)/sinc(p)*Xmax(i);
		end

		f(i)=(i_f(i)-1)*f_s/nFFT;
		A(i)=A(i)*sqrt(2);
	else	% peak not OK
		f(i)=(iMax(i)-1)*f_s/nFFT;
		A(i)=Xmax(i)*sqrt(2);
	end		% peak not OK
end		% for i
if nargout>2
	ph=mod(angle(Z(i_0))'-pi*rem(i_f,1),2*pi);
	if nargout>3
		t=(0:length(x)-1)'/f_s;
		y=cos(t*(f(1)*2*pi)+ph(1))*A(1);
		for i=2:length(f)
			y=y+cos(t*(f(i)*2*pi)+ph(i))*A(i);
		end
		e=x(:)-y;
		DC=mean(e);
		y=y+DC;
		e=e-DC;
		eM=sqrt(mean(e.^2));
		relPeak=reshape(X(max(1,iMax-2))+X(min(end,iMax+2)),1,[])/sqrt(2)./A;
		D=struct('Z0',Z0,'Z',Z,'t',t,'x',x,'y',y,'DC',DC,'e',e	...
			,'eRMS',eM,'relPeak',relPeak,'bPeakOK',bPeakOK);
	end
end
