function [Rh1,CH,F,Xin,Xout]=CalcH1Estim(Xin,Xout,varargin)
%CalcH1Estim - Calculate response via H1-estimator with coherence calculation
%   [Rh1,CH]=CalcH1Estim(Xin,Xout)
%        Xin and Xout are assumed to be FFT-spectra and must have the same
%             number of rows and columns (1st two dimensions)
%             if Xout has a third dimension, these are regarded as
%                  different signals, giving two-dimensional outputs
%        CH (coherence) only if multiple columns in Xin and Xout
%   [Rh1,CH,F,Xin,Xout]=CalcH1Estim(xin,dtIn,xout,dtOut,tBlock,fOverlap,fEnd)

if nargin==2
	Phh=mean(Xin.*conj(Xin),2);
	bCH=nargout>1;%&&size(Xout,2)>1;
	
	Rh1=zeros(size(Xin,1),size(Xout,3));
	if bCH
		CH=zeros(size(Xin,1),size(Xout,3));
	end
	for i=1:size(Rh1,2)
		Xout1=Xout(:,:,i);
		Pyy=mean(Xout1.*conj(Xout1),2);
		Pyh=mean(Xout1.*conj(Xin),2);

		Rh1(:,i)=Pyh./Phh;
		if bCH
			CH(:,i)=(abs(Pyh).^2)./(Phh.*Pyy);
		end
	end
else
	dtOut=[];
	tBlock=[];
	fOverlap=0.5;
	fEnd=[];
	xin=Xin;
	dtIn=Xout;
	xout=varargin{1};
	if nargin>3
		dtOut=varargin{2};
	end
	if isempty(dtOut)
		dtOut=dtIn;
	end
	if length(varargin)>2
		tBlock=varargin{3};
		if length(varargin)>3
			fOverlap=varargin{4};
			if length(varargin)>4
				fEnd=varargin{5};
			end
		end
	end
	tInTot=(length(xin))*dtIn;
	tOutTot=(size(xout,1))*dtOut;
	if isempty(xin)	% Only preparation of response estimation
		tInTot=tOutTot;
	elseif isempty(xout)
		tOutTot=tInTot;
		xout=xin;
		xin=[];
	end
	tTot=min(tInTot,tOutTot);
	if isempty(tBlock)
		tBlock=512*dtIn;
	end
	if tTot<tBlock
		tBlock=tTot;
	end
	if isempty(fEnd)
		fEnd=0.5/dtIn;
	end
	DT=tBlock*(1-fOverlap);
	nBlock=floor((tTot-tBlock)/DT+1);
	nIn=round(tBlock/dtIn);
	nOut=round(tBlock/dtOut);
	wIn=hanning(nIn)/nIn;
	wOut=hanning(nOut)/nOut;
	iIn=0;
	iOut=0;
	nF=1+round(fEnd*tBlock);
	Xin=zeros(nF,nBlock);
	Xout=zeros(nF,nBlock,size(xout,2));
	for i=1:nBlock
		if ~isempty(xin)
			x=xin(iIn+1:iIn+nIn);
			if length(x)<nIn
				x(nIn)=0;	% is this possible?
			end
			x=x.*wIn;
			X1=fft(x);
			Xin(:,i)=X1(1:nF);
		end
		for j=1:size(xout,2)
			y=xout(iOut+1:iOut+nOut,j);
% 			if length(y)<nIn
% 				y(nIn)=0;
% 			end
			y=y.*wOut;
			X1=fft(y);
			Xout(:,i,j)=X1(1:nF);
		end
		iIn=iIn+round(DT/dtIn);
		iOut=iOut+round(DT/dtOut);
	end		% for i
	F=(0:nF-1)'/nIn/dtIn;
	if isempty(xin)
		Rh1=Xout;
		CH=F;
	else
		[Rh1,CH]=CalcH1Estim(Xin,Xout);
	end
end		% if nargin>2
