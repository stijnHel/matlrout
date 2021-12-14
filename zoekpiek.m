function [iD,P]=zoekpiek(x,N,n)
%ZOEKPIEK - Zoekt pieken bij ongeveer gekende periode

BUSE4THDEGREEPOL=true;
D=max(x)-min(x);
d=D*0.6;
i=0;
while true
	x1=x(i+1:i+N);
	if max(x1)-min(x1)>d
		break;
	end
	i=i+N;
end
iD=zeros(1,round((length(x)-i)/N)+100);
iPMx=4;
if BUSE4THDEGREEPOL
	P=zeros(length(iD),6);
	iP=[1:3 5 6];
else
	P=zeros(length(iD),4);
	iP=1:3;
end
iiD=0;
[mx,j]=max(x1);
i=i+j;
n2=round(n/2);
k=(-n2:n2)';
k2=(n2*2:N-n2*2)';
status('Overlopen van periodische maxima',0);
bWarn=false;
while i<=length(x)-N
	ri=round(i);
	xt=x(ri+k);
	if max(xt)<max(x(ri+k2))
		[mx,j]=max(x(ri+1:ri+N));
		i=ri+j;
	else
		p=polyfit(k,xt,2);
		bMxOK=true;
		if BUSE4THDEGREEPOL
			p=polyfit(k,xt,4);
			mxj=roots(p(1:4).*[4 3 2 1]);
			mxj(imag(mxj)~=0)=[];
			if length(mxj)>1
				mxj(abs(mxj)>3)=[];
				if length(mxj)>1
					%!!!
					[mxj1,j]=min(abs(mxj));
					mxj=mxj(j);
				elseif isempty(mxj)
					if ~bWarn
						warning('Dit was niet verwacht (i=%d)...',i)
						bWarn=true;
					end
					bMxOK=false;
					mxj=0;	%!!!!
					mx=x(ri);
				end
			end
			if bMxOK
				mx=polyval(p,mxj);
			end
		else
			p=polyfit(k,xt,2);
			mxj=-p(2)/2/p(1);
			mx=p(3)-p(2)^2/4/p(1);
		end
		if abs(mxj)>3
			i=i+mxj;
			xt=x(round(i)+k);
			p=polyfit(k,xt,2);
			mxj=-p(2)/2/p(1);
			mx=p(3)-p(2)^2/4/p(1);
			if BUSE4THDEGREEPOL
				p=[0 0 p];
			end
		end
		i=i+mxj;
		iiD=iiD+1;
		iD(iiD)=i;
		P(iiD,iP)=p;
		P(iiD,iPMx)=mx;
		i=i+N;
	end
	status(i/length(x))
end
status
iD=iD(1:iiD);
P=P(1:iiD,:);
