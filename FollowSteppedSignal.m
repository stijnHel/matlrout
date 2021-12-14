function [D,DMS,B]=FollowSteppedSignal(e,varargin)
%FollowSteppedSignal - follow a stepped signal
%
%      The goal of this function is to follow a signal with noise where the
%      signal itself is changed in steps.  The steps should be high enough
%      compared to the noise.
%
%        [D,DMS,B]=FollowSteppedSignal(x[,options])
% inputs:
%      e   - input vector
% outputs
%      D   - running mean and std (same sampling as input x)
%      DMS - Dmean and Dstd over constant parts
%              DMS(:,3:4) gives starting and ending of parts
%      B   - logical vector (length x) true at ends of cst blocks

nStart=100;
fS=3;
nHighDiff=5;
kForget=0.99;
nSkipStart=20;	% skip for average calculation, but also used for other
		% measures
nSkipEnd=10;
nMaxShortPieces=5;

if ~isempty(varargin)
	setoptions({'nStart','fS','nHighDiff','kForget','nSkipStart','nSkipEnd'}	...
		,varargin{:})
end

s=std(e(1:nStart));
m=mean(e(1:nStart));
s2=s^2;
D=nan(length(e),2);

D(1:nStart)=m;
D(1:nStart,2)=s;
i=nStart+1;
n=nStart;
iStartLast=1;
bHigh=false;
nShortPieces=0;
while i<=length(e)
	dE=e(i)-m;
	n=n+1;
	if abs(dE)>fS*s
		if ~bHigh
			if i-iStartLast>nSkipStart
				iLastLong=i;
				nShortPieces=0;
			else
				nShortPieces=nShortPieces+1;
				if nShortPieces>nMaxShortPieces
					i1=iLastLong+nSkipStart;
					s1=std(e(i1:i));
					if s1>s*1.05
						m=mean(e(i1:i));
						s=s1;
						i=i1;	% restart
						continue
					end
				end
			end
		end
		j=1;
		while j<=nHighDiff&&i+j<=length(e)&&(e(i+j)-m)*sign(dE)>s
			j=j+1;
		end
		if j>nHighDiff
			i=i+j;
			m=e(i-1);
			n=0;
		else
			i=i+1;
		end
		bHigh=true;
	else
		if bHigh
			iStartLast=i;
		end
		if n>=nStart
			x=e(i);
			m=kForget*m+(1-kForget)*x;
			s21=(x-m)^2;
		else
			m=mean(e(i-n:i));
			s1=std(e(i-n:i));
			s21=s1^2;
		end
		s2=kForget*s2+(1-kForget)*s21;
		s=sqrt(s2);
		D(i)=m;
		D(i,2)=s;
		i=i+1;
		bHigh=false;
	end
end

B=false(length(e),1);
B(1)=true;
bHigh=false;
iLast=1;
for i=nStart:length(B)
	if isnan(D(i))
		bHigh=true;
	else
		if bHigh
			if abs(D(i)-D(iLast))>fS*D(iLast,2)
				B(i)=true;
				if i-iLast<nSkipStart
					B(iLast)=false;
				end
			end
		end
		iLast=i;
	end
end
B(end)=true;
DMS=zeros(sum(B),4);
iLast=1;
iD=0;
for i=2:length(B)
	if B(i)
		ii=find(~isnan(D(iLast+1:i-nSkipEnd,1)))+iLast;
		iD=iD+1;
		DMS(iD,1)=mean(D(ii));
		DMS(iD,2)=sqrt(mean(D(ii,2).^2));
		DMS(iD,3:4)=ii([1 end]);
		iLast=i;
	end
end
if iD<size(DMS,1)
	DMS=DMS(1:iD,:);
end
