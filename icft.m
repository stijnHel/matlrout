function [x,t,xf]=icft(X,df,varargin)
%icft     - Inverse continues fourier transform
%  Calculates from a "continues" frequency spectrum a time signal, assuming
%  that the time signal is a real value.
%
%       [x[,t,xf]]=icft(X[,df[,options]])
%     df is the frequency resolution, of a list of frequencies belonging to X.
%   possible options:
%          Nextra : Additional zeros to be put between two symmetrical
%                   parts of the DFT
%
%  A window is applied to the frequency response, which gives a reduction
%  at the end of the spectrum.  From this windowed spectrum, a complex
%  conjugate symmetrical DFT is made.  From this the real valued ifft is
%  calculated.

Nextra=0;
bMag2Size=true;

if ~isempty(varargin)
	setoptions({'Nextra'},varargin{:})
end

if ~exist('df','var')||isempty(df)
	df=2;
elseif length(df)>1
	if length(df)~=length(X)
		error('When using icft(X,fList) lengths of X and fList must be equal!')
	end
	if any(df<0)
		error('Only positive frequencies allowed!')
	end
	DF=diff(df);
	if any(DF<=0)
		error('Only strictly increasing frequency list is allowed!')
	end
	bResample=false;
	if std(DF(2:end))/mean(DF(2:end))>1e-4	% not equidistant frequency list
		bResample=true;
	elseif df(1)>0
		if df(1)/df(2)<1e-3	% low but not zero first frequency
			if abs(1-df(2)/mean(DF(2:end)))<1e-5	% constant 
				df=df(2);	% assume first frequency == 0
			else
				warning('unexpected frequency range, spectrum is resampled!')
				bResample=true;
			end
		else
			N_to_f1=round(df(1)/mean(DF));	% expected to be "integer enough"
			         % for just adding initial zeros
			X=[zeros(N_to_f1,1);X(:)];
		end
	end
	if bResample
		DF=0:mean(DF):df(end);
		X=interp1(df,X,DF);
		X(isnan(X))=0;
		df=DF(2);
	end
	if length(df)>1
		df=mean(DF);
	end
end

% Use a window over the spectrum (1 in the beginning, around 0 at the end)
Nr=length(X)*0.7;
fWindow=min(1,exp(-((1:length(X))/Nr).^10));
Xf=X(:).*fWindow(:);
if Nextra>=0
	if bMag2Size
		mN=ceil(log2(length(Xf)*2+Nextra-1));
		Ntot=round(2^mN);
		Nextra=Ntot-(length(Xf)*2-1);
	end
	Xf(end+1+Nextra:2*end-1+Nextra)=conj(Xf(end:-1:2));	% make F-responce symmetrical
else
	Ntot=length(Xf)*2-1+Nextra;
	if Ntot<length(X)+2
		error('Nextra is too negative!!')
	end
	if bMag2Size
		mN=ceil(log2(Ntot));
		Ntot=round(2^mN);
	end
	Xf(Ntot)=0;
	Xf(Ntot:-1:Ntot-length(X)+2)=Xf(Ntot:-1:Ntot-length(X)+2)+conj(Xf(2:length(X)));
end
Xf(1)=Xf(1)*2;
x=real(ifft(Xf))*(length(Xf)/2);

if nargout>1
	t=(0:length(x)-1)/(df*length(x));
	if nargout>2
		xf=conv(x,ones(4,1)/4);
		xf=xf(2:end-2);
	end
end
