function [shift,e]=FindShift(x1,y1,x2,y2)
%FindShift - Find shift between two signals (with different sampling rates)
%      shift=FindShift(x1,y1,x2,y2)

%remarks:
% - not yet implemented:
%        - tests on lower sampling rates
% - speed improvement - polyfit,... --> direct formulas

fLimit=10;

dx1=median(diff(x1));
dx2=median(diff(x2));
if dx1<=0||dx2<=0
	error('This function is made for strictly increasing data')
end
bRef1=dx1>=dx2;
if bRef1
	dx=dx1;
else
	dx=dx2;
end
L=[max(x1(1),x2(1))+fLimit*dx min(x1(end),x2(end))-fLimit*dx];
if L(1)>=L(2)
	error('This data is not suited for this function - too low number of points?')
end
if bRef1
	B=x1>=L(1)&x1<=L(2);
	x11=x1(B);
	y11=y1(B);
	x21=x2;
	y21=y2;
else
	B=x2>=L(1)&x2<=L(2);
	x11=x1;
	y11=y1;
	x21=x2(B);
	y21=y2(B);
end
e1=RMSdiff(x11,y11,x21,y21,bRef1,0);
e2=RMSdiff(x11,y11,x21,y21,bRef1,dx);
if e2>e1
	dx=-dx;
	e2_0=e2;	% to be used in case shift is close to 0
	e2=RMSdiff(x11,y11,x21,y21,bRef1,dx);
	if e2>=e1	% shift is close to 0
		p=polyfit([-1 0 1],[e2_0 e1 e2],2);
		shift=-p(2)/2/p(1)*dx;
		if nargout>1
			e=polyval(p,-p(2)/2/p(1));
		end
		return
	end
elseif e2==e1	% luck?
	error('This case is not (yet) implemented!!!')
end
Dx=dx;
while e2<e1
	e0=e1;
	e1=e2;
	Dx=Dx+dx;
	% Test if working range needs to be adapted
	bUpdateB=false;
	if bRef1
		if Dx>0
			if x11(1)-Dx<x2(1)
				L=[max(x1(1)+2*dx,x2(1)+Dx+fLimit*dx) min(x1(end)-fLimit*dx,x2(end)+Dx-2*dx)];
				bUpdateB=true;
			end
		elseif x11(end)-Dx>x2(end)	% Dx<0
			L=[max(x1(1)-fLimit*dx,x2(1)+Dx-2*dx) min(x1(end)+2*dx,x2(end)+Dx+fLimit*dx)];
			bUpdateB=true;
		end
		if bUpdateB
			B=x1>=L(1)&x1<=L(2);
			x11=x1(B);
			y11=y1(B);
		end
	else	% ~bRef1
		if Dx>0
			if x21(end)+Dx>x1(end)	% Dx<0
				L=[max(x1(1)-Dx+2*dx,x2(1)+fLimit*dx) min(x1(end)-Dx-fLimit*dx,x2(end)-2*dx)];
				bUpdateB=true;
			end
		elseif x21(1)+Dx<x1(1)
			L=[max(x1(1)-Dx-fLimit*dx,x2(1)-2*dx) min(x1(end)-Dx+2*dx,x2(end)+fLimit*dx)];
			bUpdateB=true;
		end
		if bUpdateB
			B=x2>=L(1)&x2<=L(2);
			x21=x2(B);
			y21=y2(B);
		end
	end
	if bUpdateB
		% recalc e0, e1
		e0=RMSdiff(x11,y11,x21,y21,bRef1,Dx-2*dx);
		e1=RMSdiff(x11,y11,x21,y21,bRef1,Dx-dx);
		if e1>e0
			ns=0;
			while e1>e0
				ns=ns+1;
				Dx=Dx-dx;
				e1=e0;
				e0=RMSdiff(x11,y11,x21,y21,bRef1,Dx-2*dx);
			end
			warning('Unexpected error: updated error values don''t give the same ordering! (%d steps back!)'	...
				,ns)
		end
	end
	e2=RMSdiff(x11,y11,x21,y21,bRef1,Dx);
end
shift=Dx-dx;	% to be corrected!!!!
p=polyfit([-1 0 1],[e0 e1 e2],2);
shift=shift-p(2)/2/p(1)*dx;
if nargout>1
	e=polyval(p,-p(2)/2/p(1));
end

function e=RMSdiff(x1,y1,x2,y2,bRef1,dx)
if bRef1
	y21=interp1(x2,y2,x1-dx);
	e=sum((y1-y21).^2);
else
	y12=interp1(x1,y1,x2+dx);
	e=sum((y2-y12).^2);
end
if isnan(e)
	error('NaNnnnnn! - work on L-adaptation!!!')
end
