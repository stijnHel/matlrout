function [F,T,A,I]=calcRunFreq(x,dt,n,Amin,varargin)
%calcRunFreq - Calculates running frequency by zero-crossings
%      [F,T,A,I]=calcRunFreq(x,dt,n,Amin[,options])
%            options:
%              iEdge : -1 (negative edge), 0 (both) or +1
% if both edges are used and n<=2, A will also contain duty cycle

iEdge=0;

if ~isempty(varargin)
	setoptions({'iEdge'},varargin{:})
end
if ~exist('dt','var')||isempty(dt)
	dt=1;
end
if ~exist('n','var')||isempty(n)
	n=2;
end
if ~exist('Amin','var')||isempty(Amin)
	Amin=0;
end

fFactor=1;
if iEdge<0
	bInc=false;
	bDec=true;
	iEdge=-1;
elseif iEdge>0
	bInc=true;
	bDec=false;
	iEdge=1;
else
	bInc=true;
	bDec=true;
	fFactor=0.5;
end

if bInc
	iI=find(x(1:end-1)<0&x(2:end)>=0);
	iI=iI-x(iI)./(x(iI+1)-x(iI));
end
if bDec
	iD=find(x(1:end-1)>=0&x(2:end)<0);
	iD=iD-x(iD)./(x(iD+1)-x(iD));
end
switch iEdge
	case -1
		I=iD;
	case 0
		if length(iI)+length(iD)<2
			I=[iI;iD];	% one of the two
		else
			iI=iI(:)';
			iD=iD(:)';
			if iD(1)<iI(1)
				firstEdge=-1;
				I=iI;
				iI=iD;
				iD=I;
			else
				firstEdge=1;
			end
			I=iI;
			I(2,1:length(iD))=iD;
			I=I(:);
			if length(iD)<length(iI)
				I(end)=[];
			end
		end
	case 1
		I=iI;
end
MX=I;
MN=I;
iI=1;
mx=x(1);
mn=mx;
for ix=2:length(x)
	x1=x(ix);
	if ix>=I(iI)
		MX(iI)=mx;
		MN(iI)=mn;
		iI=iI+1;
		if iI>length(I)
			break
		end
		mx=x1;
		mn=x1;
	else
		mx=max(mx,x1);
		mn=min(mn,x1);
	end
end
if iEdge==0
	b=MX>=Amin|MN<=-Amin;
else
	b=MX>=Amin&MN<=-Amin;
end
I=I(b);
MX=MX(b);

dI=I(1+n:end)-I(1:end-n);
F=n/dt./dI*fFactor;
T=(I(1:end-n)+I(1+n:end))*(dt/2);
if n>1
	if iEdge==0
		MX=abs(MX(2:end)-MX(1:end-1))/2;
	else
		MX(1)=[];
	end
	A=conv(MX,ones(1,n)/n);
	A=A(n:end-n+1);
else
	A=MX(2:end);
end
if n<=2&&iEdge==0
	if firstEdge>0
		i1=1;
	else
		i1=2;
	end
	nI=length(I);
	dc=(I(i1+1:2:nI-1)-I(i1:2:nI-2))./(I(i1+2:2:nI)-I(i1:2:nI-2));
	A(i1:2:nI-2,2)=dc;
	A(i1+1:2:nI-1,2)=dc;
end
