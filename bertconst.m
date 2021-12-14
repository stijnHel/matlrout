function bertconst(l,dx)
% BERTCONST  - Schat tijdskonstante op een punt.
%    bertconst(l,dx)   (default 10 meetpunten)
%       Zet ButtonDownFcn van l op bertconst
%    bertconst(f,dx) met f wijzend naar een as of een figuur
%       Zet ButtonDownFcn van alle lijnen van f op bertconst
%    bertconst(f,[dx,fFilt])
%    or
%    bertconst(f,[dx,fFilt,nFilt])
%        Does filtering before analysing
%           double direction butterworth filtering is used, with care for
%           initial values (starting from starting values)
%           default order is 2 (for single filtering)

uipos=1;
if nargin
	if ischar(l)
		switch l
			case 'calc'
				uipos=0;
				x0=dx;
			otherwise
				error('Verkeerd gebruik van bertconst')
		end
	else
		% setup
		if (nargin==1)|isempty(dx)
			dx=-1;
		end
		if length(l)==1
			t=get(l,'Type');
			if strcmp(t,'figure')|strcmp(t,'axes')
				l=findobj(l,'Type','line');
			end
		end
		set(l,'ButtonDownFcn','bertconst','UserData',dx)
		return
	end
end

l=gco;
x=get(l,'XData');
if any(diff(x)<0)
	errordlg('BERTCONST kan enkel gebruikt worden met lijnen met stijgende x-waarden','BERTCONT-ERROR')
	return
end
y=get(l,'YData');
dx=get(l,'UserData');
if length(dx)>1
	fFilt=dx(2);
	if length(dx)>2
		nFilt=dx(3);
	else
		nFilt=2;
	end
	dx=dx(1);
	dxMean=mean(diff(x));
	[Bf,Af]=butter(nFilt,fFilt*dxMean*2);
	y=y(1)+filter(Bf,Af,y-y(1));
	y=y(end)+filter(Bf,Af,y(end:-1:1)-y(end));y=y(end:-1:1);
end
if dx<0
	dx=10*mean(diff(x));
end
if uipos
	p=get(gca,'CurrentPoint');
	x0=p(1,1);
end


ii=find(x>=x0);
if length(ii)<4
	errordlg('Kan tijdsconstante niet vinden - onvoldoende punten','BERTCONST-error')
	return
end
xb=x0-dx;
xe=x0+dx;
i=find((x>=xb)&(x<=xe));

p=polyfit(x(i),y(i),1);
if p(1)==0
	errordlg('Tijdsconstante van een niet-varierend signaal kan niet bepaald worden.'	...
		,'BERTCONST-error');
	return
end
y0=polyval(p,x0);
j=i(end);
x1=xe;
if p(1)>0
	mxy=max(y(ii));
else
	mxy=min(y(ii));
end
taumax=(mxy-y0)/p(1);
xmax=min(x(end),x0+taumax*10);
tau=0;
tauest=[x0 y0 p 0 0];
meantau1=0;
while x1<xmax
	xb=x1-dx;
	xe=x1+dx;
	i=find((x>=xb)&(x<=xe));
	if isempty(i)
		break;
	end
	p1=polyfit(x(i),y(i),1);
	if p1(1)*p(1)<=0|abs(p1(1))<abs(p(1))/100
		if p(1)>0
			ymx=max(y(i));
		else
			ymx=min(y(i));
		end
		% !?gebruik maken van eerdere schattingen!!
		tau=(ymx-y0)/p(1);
		taubep=0;
		break
	end
	y1=polyval(p1,x1);
	esttau1=(x1-x0)/log(p(1)/p1(1));
	esttau2=(x1-tauest(end,1))/log(tauest(end,3)/p1(1));
	if esttau1<=dx
		esttau1=esttau2;
	end
	if esttau2<=dx
		esttau2=esttau1;
	end
	if esttau1>dx
		tauest(end+1,:)=[x1 y1 p1 esttau1 esttau2];
		if size(tauest,1)>5
			itau=max(2,size(tauest,1)-4):size(tauest,1);
			meantau1=mean(tauest(itau,5));
			stdtau1=std(tauest(itau,5));
			meantau2=mean(tauest(itau,6));
			stdtau2=std(tauest(itau,6));
			stdtau=min(stdtau1,stdtau2);
			if stdtau/meantau1<0.01
				stdtau2=std(tauest(itau,6));
				if stdtau2<stdtau1
					taubep=2;
					tau=meantau2;
				else
					taubep=1;
					tau=meantau1;
				end
				break;
			end
		end
	end
	x1=xe;
end
if length(tau)~=1|tau<=0
	errordlg('Tijdsconstante niet gevonden','BERTCONST-error')
	return
end
xunit=extractunit(get(get(gca,'xlabel'),'string'));
yunit=extractunit(get(get(gca,'ylabel'),'string'));
x2=x0+tau;
y2=polyval(p,x2);
if meantau1
	fprintf('Tijdsconstante (%g (+/-%g),%g) is %g (#%d - %d - %g(%g) %g(%g))\n'	...
		,x0,dx,y0,tau,taubep,size(tauest,1)-1,meantau1,stdtau1,meantau2,stdtau2)
else
	fprintf('Tijdsconstante (%g (+/-%g),%g) is %g (#%d - %d)\n'	...
		,x0,dx,y0,tau,taubep,size(tauest,1)-1)
end
fprintf('   y : %g -----> %g (x_test : %g ---> %g)\n',y0,y2,x0,x1)
dy=abs(y2-y0)/5;
l=line([x0 x2 x1 x1 x1 x1 x0 x0],[y0 y2 y2 y2+dy y2-dy y2 y2 y0]);
l1=line(x0,y0,'Marker','.','MarkerSize',6);
sval=sprintf('%g',tau);
t=text(x0,y1,sval,'HorizontalAlignment','center','VerticalAlignment','bottom');
beruis=[l l1 t];
set(beruis,'ButtonDownFcn','delete(get(gco,''UserData''));','UserData',beruis)

function unit=extractunit(s)
if isempty(s)
	unit='';
	return
end
i1=find(s=='[');
i2=find(s==']');
if (length(i1)==1)&(length(i2)==1)&(i1<i2)
	unit=s(i1+1:i2-1);
else
	unit='';
end
