function [x,y,r,I]=zoekcirc(xlijst,ylijst,x0,y0,bGraph)
% ZOEKCIRC - Zoek de best passende cirkel door punten
%         [x,y,r]=zoekcirc(xlijst,ylijst,x0,y0[,bGraph])
%     xlijst,ylijst : coordinaten van punten
%     x0,y0 : bereik van middelpunt

if ~nargin
	x1=0.6;
	y1=0.9;
	r1=4;
	rr=0.3;
	w=0:0.01:2;
	xlijst=x1+cos(w).*(r1+(rr*rand(1,length(w))-rr/2));
	ylijst=y1+sin(w).*(r1+(rr*rand(1,length(w))-rr/2));
	x0=[-20 20];
	y0=[-20 20];
	%zoekcirc(xx,yy,x0,y0)
end
if ~exist('bGraph','var')|isempty(bGraph)
	bGraph=false;
end

% voorlopig geven x0 en y0 de limieten waar middelpunt gezocht moet worden.
i=0:0.01:1;
xx=i*(x0(2)-x0(1))+x0(1);
yy=i*(y0(2)-y0(1))+y0(1);

z=zeros(length(yy),length(xx));
R=z;
for i=1:length(xx)
	for j=1:length(yy)
		if false
		r2=(xlijst-xx(i)).^2+(ylijst-yy(j)).^2;
		r=mean(sqrt(r2));
		z(j,i)=sum(r2-r*r);
		else
		rr=sqrt((xlijst-xx(i)).^2+(ylijst-yy(j)).^2);
		r=mean(rr);
		z(j,i)=sum((rr-r).^2);
		end
		R(j,i)=r;	% only for graph and limit-find
	end
end
[mn1,i]=min(z);
[mn,j]=min(mn1);
i=i(j);
if i<3|i>length(yy)-2|j<2|j>length(xx)-2
	warning('centrum dicht bij de rand van het gegeven grensgebied!')
	x=xx(j);
	y=yy(i);
	r=R(i,j);
else
	p=polyfit(xx(j-2:j+2)-xx(j),z(i,j-2:j+2),2);
	x=xx(j)-p(2)/(2*p(1));
	mnx=p(3)-p(2)^2/(4*p(1));
	p=polyfit(yy(i-2:i+2)'-yy(i),z(i-2:i+2,j),2);
	y=yy(i)-p(2)/(2*p(1));
	mny=p(3)-p(2)^2/(4*p(1));
end
r=mean(sqrt((xlijst-x).^2+(ylijst-y).^2));
if bGraph
	nfigure
	mesh(xx,yy,sqrt(z))
	title 'error on estimation (sqrt(square error))'
	nfigure
	plot(xlijst,ylijst,'x');grid
	hold on
	[c,h]=contour(xx,yy,z,20);
	%clabel(c,h)
	hold off

	line(x0,y*[1 1])
	line(x*[1 1],y0)
	w=0:0.01:6.3;
	line(x+cos(w)*r,y+sin(w)*r);

	if exist('x1','var')
		line(x1,y1,'LineStyle','none','Marker','x','MarkerSize',30)
		line(x1+cos(w)*r1,y1+sin(w)*r1,'LineStyle',':');
	end

	axis equal
	nfigure
	subplot 211
	mesh(xx,yy,R)
	title 'estimated radius'
	subplot 212
	[c,h]=contour(xx,yy,R,20);grid
	%clabel(c,h)
	axis equal
end
if nargout>3
	I=struct('dx',xx(2)-xx(1),'dy',yy(2)-yy(1)	...
		,'x0',xx(j),'y0',yy(i)	...
		,'e',[mn mnx mny]	...
		,'xx',xx,'yy',yy,'z',z,'R',R	...
		);
end
