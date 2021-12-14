function [nPer,D]=FindPeriod(x,varargin)
%FindPeriod - Find existing period in a signal
%      nPer=FindPeriod(x)

rLimMultiple=0.9;
rPeakRem=1e-3;
nMultiPers=1;	% multiple periods
if nargin>1
	setoptions({'rLimMultiple','nMultiPers','rPeakRem'},varargin{:})
end

WARNS={};

Xc=xcorr(double(x)-mean(x));
iX0=(length(Xc)+1)/2;
Xc0=Xc(iX0);
Xc(1:iX0)=[];	% Xc is symmetric - remove first part, including "zero-point"

% Remove "zero-peak"
i=1;
while Xc(i+1)<Xc(i)
	Xc(i)=0;
	i=i+1;
	if i>=length(Xc)
		nPer=[];
		D=[];
		warning('Can''t find a period --- very flat xcorrelation!')
		return
	end
end

[XcMx,nPer,Xc1,WARNS]=FindMax(Xc,WARNS,rLimMultiple);
while nMultiPers>1&&isempty(WARNS)
	XcCumMax=Xc;
	for i=length(Xc)-1:-1:1
		XcCumMax(i)=max(XcCumMax(i:i+1));
	end
	nPer1=nPer(end);
	i=nPer1;
	while i<length(Xc)-nPer1&&XcCumMax(i)>Xc0*rPeakRem
		i1=i;
		while Xc(i1-1)<Xc(i1)
			i1=i1-1;
		end
		i2=i;
		while Xc(i2+1)<Xc(i2)
			i2=i2+1;
		end
		Xc(i1:i2)=0;
		i=i+nPer1;
	end
	[XcMx2,nPer2,Xc2,WARNS]=FindMax(Xc,WARNS,rLimMultiple);
	if isempty(WARNS)
		nPer=[nPer nPer2]; %#ok<AGROW>
		XcMx=[XcMx XcMx2]; %#ok<AGROW>
		Xc1=[Xc1 Xc2]; %#ok<AGROW>
	else
		WARNS{1,end+1}=var2struct(nPer2,XcMx2,Xc2); %#ok<AGROW>
	end
	nMultiPers=nMultiPers-1;
end
D=var2struct(Xc0,XcMx,Xc1);

if ~isempty(WARNS)
	D.WARNS=WARNS;
end

function [XcMx,nPer,Xc1,WARNS]=FindMax(Xc,WARNS,rLimMultiple)
[XcMx,nPer]=max(Xc);
Xc1=XcMx;

ii=find(Xc>Xc1*rLimMultiple);

if length(ii)>1
	if any(diff(ii)==1)
		WARNS{1,end+1}='No clear peaks - successive pts close to maximum!';
	else
		ii1=ii(1);
		ii=setdiff(ii,ii(1)*(1:ceil(ii(end)/ii1)));	% remove "harmonics"
		if ~isempty(ii)
			WARNS{1,end+1}='Multiple periods in the signal?';
		end
		if rem(nPer,ii1)
			WARNS{1,end+1}='"Maximum period" is not the base period?';
		else
			nPer=ii1;
			Xc1=Xc(ii1);
		end
	end
end
