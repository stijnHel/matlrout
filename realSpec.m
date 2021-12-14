function [S,F]=realSpec(D,df,Nover)
%realSpec - Retrieves real frequency spectrum from multi-,undersampled data
%   [S,F]=realSpec(D[,df[,Nover])
%
%  This function looks to FFT's of sampled data at different sampling
%  frequencies, so that "ghost-frequency contents" can be separated from
%  real frequencies.
%  The measurement should be done for fixed conditions (so that spectrums
%  at different times can be compared well).
%  The function works by calculating the FFT's of different parts (using a
%  fixed length), and hanning window.  These FFT's are extended to higher
%  frequencies, and the minimum of all spectrums are calculated.
%  (the 0-frequency-point is calculated by taking the mean of the means of
%  all taken parts).
%
% (based on data read by readwfm)

dt=cat(2,D.dt);
Nlist=cellfun('length',{D.e});
if std(Nlist)>0
	warning('REALSPEC:MinLengthUsed','Only minimum length is used')
end
dfList=1./(dt.*Nlist);
if ~exist('df','var')||isempty(df)
	df=min(dfList/2);
end
if ~exist('Nover','var')||isempty(Nover)
	Nover=5;
end

Nfft=min(Nlist);
F=(0:df:min(Nover./dt))';
S=F+Inf;
mnE=zeros(1,length(D));
win=hanning(Nfft);
for i=1:length(D)
	x=D(i).e(1:Nfft);
	mnE(i)=mean(x);
	X=repmat(abs(fft((x(:)-mnE(i)).*win)),Nover,1);
	fX=(0:length(X)-1)'/length(x)/dt(i);
	S=min(S,interp1(fX,X,F));
end
S=S/(Nfft/2*mean(win));
S(1)=mean(mnE);
