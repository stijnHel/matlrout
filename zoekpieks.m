function [iD,P]=zoekpieks(x,N)
%ZOEKPIEKS - Zoekt sterke pieken met varierende periode
%   gegeven signaal moet sterke pieken vertonen! anders loopt het fout

BUSE4THDEGREEPOL=true;
BAUTOADAPTMAX=true;

if size(x,1)==1
	x=x';
end
mnX=min(x);
mxX=max(x);
D=mxX-mnX;
Lx=mnX+D*(0:0.01:0.90);

d=D*0.6;
iStart=0;
while true
	x1=x(iStart+1:iStart+N);
	if max(x1)-min(x1)>d
		break;
	end
	iStart=iStart+N;
end

[mx,i]=max(x(iStart+1:iStart+N*5));
N2=round(N/2);
X1=x(iStart+i+N2:iStart+i+2*N+N2);
nLx=Lx;
for i=1:length(Lx);
	nLx(i)=sum(X1>Lx(i));
end
i=length(Lx);
mxDif=max([nLx(end)/4,min(nLx(round(end/2))/4,20)]);
while nLx(i-1)-nLx(i)<mxDif
	i=i-1;
end
Width=nLx(i)/2;
XlimL=Lx(i);
i=find(nLx<Width);
if isempty(i)
	XlimH=Lx(end);
else
	XlimH=Lx(i(1));
end
Width2=sum(X1>XlimH)/2;

iD=zeros(1,round((length(x)-iStart)/N)+100);
if BUSE4THDEGREEPOL
	P=zeros(length(iD),8);
else
	P=zeros(length(iD),6);
end
iiD=0;
iStart=iStart+1;
while x(iStart)>=XlimH
	iStart=iStart+1;
end
while x(iStart)<XlimH
	iStart=iStart+1;
end
if BAUTOADAPTMAX
	rXlimH=XlimH/mx;
	rXlimL=XlimL/mx;
end

lastW2=Width2;
status('Overlopen van periodische maxima',0);
while iStart<length(x)
	i=iStart+min(10,floor(lastW2/2));
	while i<=length(x)&&x(i)>=XlimH
		i=i+1;
	end
	lastW2=i-iStart;
	if i>length(x)
		break
	end
	if i-iStart==2
		if x(iStart)>x(i-1)
			iStart=iStart-1;
		else
			i=i+1;
		end
	elseif i-iStart==1
		iStart=iStart-1;
		i=i+1;
	end
	iiD=iiD+1;
	xt=x(iStart:i-1)';
	if BUSE4THDEGREEPOL&&lastW2>10
		p=polyfit(0:i-iStart-1,xt,4);
		mxj=roots(p(1:4).*[4 3 2 1]);
		mxj(imag(mxj)~=0)=[];
		if length(mxj)>1
			mxj(mxj<0|mxj>i-iStart-1)=[];
			if length(mxj)>1
				%!!!
				mxj=mxj(findclose(mxj,(i-iStart-1)/2));
			end
		end
		mx=polyval(p,mxj);
		P(iiD,[1:3 7 8])=p;
	else
		p=polyfit(0:i-iStart-1,xt,2);
		mxj=-p(2)/2/p(1);
		mx=p(3)-p(2)^2/4/p(1);
		P(iiD,1:3)=p;
	end
	iD(iiD)=iStart+mxj;
	P(iiD,4)=mx;
	P(iiD,5)=iStart;
	P(iiD,6)=i-1;
	while i<length(x)&&x(i)>XlimL
		i=i+1;
	end
	while i<length(x)&&x(i)<XlimH
		i=i+1;
	end
	if BAUTOADAPTMAX
		XlimH=rXlimH*mx;
		XlimL=rXlimL*mx;
	end
	iStart=i;
	status(i/length(x))
end
status
iD=iD(1:iiD);
P=P(1:iiD,:);
