function [F,T,A,I,DC,xID]=calcRunFreq2(x,dt,n,Amin,varargin)
%calcRunFreq2 - Calculates running frequency by zero-crossings
%      [F,T,A,I,DC]=calcRunFreq2(x,dt,n,Amin[,options])
%           similar to calcRunFreq, but with histeresis (Amin)
%            F - frequency
%            T - time related to frequency
%            A - amplitude
%            I - ("raw signal") - edges - fractional index
%            DC - time and duty cycle
%
%            x  - signal (around zero)
%            dt - sampling time
%            n  - number of edges to calculate frequency
%            Amin - minimum amplitude
%
%            options:
%                iEdge - edge type (-1 falling, 0 all, +1 rising edge)
%
% see also: calcRunFreq

iEdge=0;
nMin=0;
x=x(:);	% force it to be a column vector
if ~isempty(varargin)
	setoptions({'iEdge','nMin'},varargin{:})
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
	iEdge=-1;
elseif iEdge>0
	iEdge=1;
else
	fFactor=0.5;
end

mAmin=-Amin;
N=length(x);
xI=zeros(N-1,1);
xD=xI;
x1=x(1);
mn=x1;
i=1;
while abs(x1)<Amin
	i=i+1;
	if i>N
		error('No signal found above threshold')
	end
	x1=x(i);
	mn=min(mn,x1);
end
mx=0;
if x1>0
	if i>1
		xI(i-1)=mn;
	end
	mx=x1;
	while x1>=mAmin
		i=i+1;
		if i>N
			error('No cycle start found')
		end
		x1=x(i);
		mx=max(mx,x1);
	end
end
if i>1
	xD(i-1)=mx;
end
iDlast=-1e5;
iIlast=iDlast;
iDl2=0;
mn=x1;
while i<N
	% increasing
	while x1<Amin
		i=i+1;
		if i>N
			break
		end
		x1=x(i);
		mn=min(mn,x1);
	end
	if i>N
		break
	end
	if i-iDlast<nMin
		xD(iDlast)=0;
		iDlast=iDl2;
	else
		iIl2=iIlast;
		iIlast=i-1;
		xI(iIlast)=mn;
		mx=x1;
	end
	% decreasing
	while x1>mAmin
		i=i+1;
		if i>N
			break
		end
		x1=x(i);
		mx=max(mx,x1);
	end
	if i-iIlast<nMin
		xI(iIlast)=0;
		iIlast=iIl2;
	else
		iDl2=iDlast;
		iDlast=i-1;
		xD(iDlast)=mx;
		mn=x1;
	end
end
xI(end)=0;
xD(end)=0;
iI=find(xI);
Ai=xI(iI);
iI=iI-(x(iI)-Amin)./(x(iI+1)-x(iI));
iD=find(xD);
Ad=xD(iD);
iD=iD-(x(iD)-mAmin)./(x(iD+1)-x(iD));
nn=min(length(iD),length(iI));
A=(Ad(1:nn)-Ai(1:nn))/2;
switch iEdge
	case -1
		I=iD;
	case 0
		if length(iI)+length(iD)<2
			I=[iI;iD];
		else
			iI=iI(:)';
			iD=iD(:)';
			if iD(1)<iI(1)
				I=iD;
				I(2,1:length(iI))=iI;
			else
				I=iI;
				I(2,1:length(iD))=iD;
			end
			I=I(:);
			if I(end)==0
				I(end)=[];
			end
		end
	otherwise
		I=iI;
end

dI=I(1+n:end)-I(1:end-n);
F=n/dt./dI*fFactor;
T=(I(1:end-n)+I(1+n:end))*(dt/2);
if n>1
	%A=conv(MX,ones(1,n)/n);
	%A=A(n:end-n+1);
end
if nargout>4
	if iEdge~=0
		warning('CALCRUN:NoDutySingleEdge','No duty cycle output with single edge detection')
	end
	if length(I)<4
		DC=[];
	else
		if iI(1)>iD(1)
			i1=2;
		else
			i1=1;
		end
		tDC=(I(i1+1:2:end-1)-1)*dt;
		DC=[tDC (I(1+i1:2:end-1)-I(i1:2:end-2))./diff(I(i1:2:end))];
	end
	if nargout>5
		if length(xD)>length(xI)
			xD(end)=[];
		elseif length(xI)>length(xD)
			xI(end)=[];
		end
		xID=[xI xD];
	end
end
