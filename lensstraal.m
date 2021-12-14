function [uit,hstraal,x0,S,dmin,R]=lensstraal(in,lens,doeplot)
% LENSSTRAAL - Bepaalt straal door een lens
%    [uit,hstraal,x0,S]=lensstraal(in,[D,r1,r2,d,n],doeplot)  (r1,r2>0 ==> convex)
%               voor lens mag ook : [D,f,d,n] of S
%        in : y of [y,hoek] of [x,y,hoek] of [x,y,hoek1,hoek2,...]
%              of [x,y,inf[,aantal]] of [ybereik,inf[,aantal]]
%        d : dikte van cilidrisch stuk tussen boloppervlakken
%              bij dubbel convexe of concave oppervlakken
%               en tussen twee oppervlakken bij y=0 bij gemengde(!)
%        r1,r2 : positief voor convex
%        x0 geeft in bepaalde gevallen de snijding van de uitgaande straal
%           met de X-as
%    Deze functie kan ook gebruikt worden om een lens-structure te maken :
%       L = lensstraal([<lensspec>]);
%     of
%       L = lensstraal([],[<lensspec>]);

% !!!zie ook maaklens

% De lens wordt geplaatst door buitenste cirkels rond nul te plaatsen.
%    (d = 0 ===> cirkels op nul, en anders op -d/2 en d/2)

%X0=zeros(0,0);ir2=0;for r2=0.02:0.002:0.1;ir2=ir2+1;iy=0;for y=0.001:0.001:0.012;iy=iy+1;[uit,X0(ir2,iy)]=lensstraal(y,[0.025,0.03,r2,0.0005,1.4]);end;end

if nargin==1
	bMaakEnkelLens=true;
	lens=in;
	in=[];
else
	bMaakEnkelLens=isempty(in);
end
if ~exist('doeplot','var')
	doeplot=[];
end
doeplotlens=nargout==0;
doeplotstraal=doeplotlens;
if length(doeplot)
	doeplotlens=doeplot(1);
	doeplotstraal=doeplot(1);
	if length(doeplot)>1
		doeplotstraal=doeplot(2);
	end
end

Lteken=[];
Dia=[];
if isstruct(lens)
	D=lens.D;
	r1=lens.r1;
	r2=lens.r2;
	d=lens.d;
	nlens=lens.n;
	f=lens.f;
	if isfield(lens,'Luit')
		Lteken=lens.Luit;
	end
	if isfield(lens,'Dia')
		Dia=lens.Dia;
	end
	if isempty(f)
		f=1/(1/r1+1/r2)/(nlens-1);	% (geen r1.r2/(r1+r2) voor ri=inf)
	elseif isempty(r1)
		if isempty(r2)
			r1=2*f*(nlens-1);
			r2=r1;
		else
			r1=(nlens-1)/(1/f-(nlens-1)/r2);
		end
	elseif isempty(r2)
		r2=(nlens-1)/(1/f-(nlens-1)/r1);
	end
elseif length(lens)==5
	D=lens(1);
	r1=lens(2);
	r2=lens(3);
	d=lens(4);
	nlens=lens(5);
	f=1/(1/r1+1/r2)/(nlens-1);
elseif length(lens)==4
	D=lens(1);
	f=lens(2);
	d=lens(3);
	nlens=lens(4);
	r1=2*f*(nlens-1);
	r2=r1;
else
	error('verkeerde definitie lens')
end
S=struct('D',D,'r1',r1,'r2',r2,'d',d,'n',nlens,'f',f	...
	,'Luit',Lteken,'Dia',Dia);
if bMaakEnkelLens
	uit=S;
	return
end
if isempty(Dia)
	Dia=D;
end

R=D/2;
nrel=nlens;	% eigenlijk delen door lucht brekingsindex

if R>=min(abs(r1),abs(r2))
	error('onmogelijke situatie')
end

sr1=sign(r1);
sr2=sign(r2);
ar1=abs(r1);
ar2=abs(r2);
if r1>0&r2>0
	if isinf(r1)
		x1=-d/2;
		xc1=x1;
	else
		x1=-d/2-(1-sqrt(1-(R/r1)^2))*r1;
		xc1=x1+r1;
	end
	if isinf(r2)
		x2=d/2;
		xc2=x2;
	else
		x2=d/2+(1-sqrt(1-(R/r2)^2))*r2;
		xc2=x2-r2;
	end
else
	error 'nog niet klaar!!'
end

if isempty(Lteken)
	Lteken=[ar1 ar2];
	Lteken(isinf(Lteken))=[];
	Lteken=max(Lteken);
end
if doeplotlens|doeplotstraal
	fignr=findobj('Tag','lensfigure');
	if isempty(fignr)
		fignr=nfigure;
		set(fignr,'Tag','lensfigure');
	else
		figure(fignr);
	end
end
if doeplotlens
	if isinf(r1)
		xl1=[x1 x1];
		yl1=[R -R];
	else
		phi1=asin(R/ar1);
		phis1=pi-phi1:phi1/10:pi+phi1;
		xl1=xc1+ar1*cos(phis1);
		yl1=ar1*sin(phis1);
	end
	if isinf(r2)
		xl2=[x2 x2];
		yl2=[-R R];
	else
		phi2=asin(R/ar2);
		phis2=-phi2:phi2/10:phi2;
		xl2=xc2+ar2*cos(phis2);
		yl2=ar2*sin(phis2);
	end
	if ischar(in)	% speciale mogelijkheid
		uit=[xl1 xl2 xl1(1);yl1 yl2 yl1(1)]';
		return
	end
	plot([xl1 xl2 xl1(1)],[yl1 yl2 yl1(1)]);
	grid
	axis equal
	line([x1 x2],[0 0],'linestyle','none','marker','x')
	line([xc1 xc2],[0 0],'linestyle','none','marker','o')
	line([-f f],[0 0],'linestyle','none','marker','+')
end

if isempty(in)
	in=(-4:4)'/9*D;
end

if size(in,1)==1&size(in,2)>1
	if isinf(in(2))
		if size(in,2)>2
			aantal=in(3);
		else
			aantal=7;
		end
		nn0=(aantal-1)/2;
		in=(-nn0:nn0)'/nn0*in(1);
	elseif size(in,2)>2&isinf(in(3))
		if size(in,2)==3
			in(4)=7;
		end
	end
end
switch size(in,2)
	case 1
		Yin=in;
		Hin=0*in;
		Xin=x1+(1-sqrt(1-(Yin/r1).^2))*r1;
		Xs1=x1-Lteken+Hin;
		Ys1=Yin;
	case 2
		Yin=in(:,1);
		Hin=in(:,2);
		Xin=x1+(1-sqrt(1-(Yin/r1).^2))*r1;
		Xs1=x1-Lteken+Yin*0;
		Ys1=Yin-(Xin-Xs1).*sin(Hin);
	case 3
		Xs1=in(:,1);
		Ys1=in(:,2);
		Hin=in(:,3);
		Xin=Xs1;	% init
		Yin=Xin;
		for i=1:length(Xs1)
			[Xin(i),Yin(i)]=getcircpt(xc1,ar1,Xs1(i),Ys1(i),Hin(i));
		end
	otherwise
		if size(in,1)~=1
			error('Dit type ingang is niet mogelijk')
		end
		Hin=in(3:end)';
		if isinf(in(3))
			if in(4)<2|in(4)>floor(in(4))
				error('Verkeerde input')
			end
			hmin=atan((Dia/2+in(2))/in(1));	% (in(1)<0)
			hmax=atan((in(2)-Dia/2)/in(1));
			nn=in(4);
			Hin=hmin+(0:nn-1)/(nn-1)*(hmax-hmin);
			Hin(1)=Hin(1)-Dia/in(1)/1e6;
			Hin(nn)=Hin(end)+Dia/in(1)/1e6;
		end
		aantal=length(Hin);
		Xs1=in(1)+zeros(aantal,1);
		Ys1=in(2)+zeros(aantal,1);
		Xin=Xs1;
		Yin=Xin;
		for i=1:length(Xs1)
			[Xin(i),Yin(i)]=getcircpt(xc1,ar1,Xs1(i),Ys1(i),Hin(i));
		end
end
if any(Xs1>=0)|any(abs(Hin)>=pi/2)
	error('Stralen moeten van links (x<0) naar rechts gaan (-pi/2..pi/2)')
	if any(abs(Yin)>R)
		error('Straal komt niet op lens!!')
	end
end

uit=zeros(4,2,length(Xs1));
hstraal=zeros(length(Xs1),4);
for i=1:length(Xs1)
	xin=Xin(i);
	yin=Yin(i);
	hin=Hin(i);
	xs1=Xs1(i);
	ys1=Ys1(i);

	sphi1=yin/r1;
	phi1=asin(sphi1);
	sphi2=sin(phi1+hin)/nrel;
	phi2=asin(sphi2)-phi1;

	[x2,y2]=getcircpt(xc2,ar2,xin,yin,phi2);
	%phi2=atan2(y2-yin,x2-xin);
	phil2=asin(y2/r2);
	phi3=phil2-asin(sin(phil2-phi2)*nrel);
	x3=x2+Lteken*cos(phi3);
	y3=y2+Lteken*sin(phi3);

	uit(:,:,i)=[xs1 xin x2 x3;ys1 yin y2 y3]';
	hstraal(i,:)=[hin phi2 phi3 phi3];
	if phi3==0|(ys1~=0&hin~=0)
		x0(i)=inf;
	else
		x0(i)=x2-y2/tan(phi3);
		if x0(i)>x3
			uit(end,:,i)=[x0(i) 0];
		end
	end

	if doeplotstraal
		line(uit(:,1,i),uit(:,2,i),'color',[1 0 0])
		if x0(i)<x2
			line([x2 x0(i)],[y2 0],'color',[1 0 0],'linestyle',':')
		end
	end
end

if nargout>4
	if (all(Ys1==0)|all(Hin==0))&all(x0>0)
		% !!!minder efficient en slimmig kan niet!!??
		x0_=x0(~isinf(x0));
		x0min=min(x0_);
		x0max=max(x0_);
		dx0=x0max-x0min;
		x1=max(max(uit(end-1,1,:)),x0min-dx0);
		x2=x0max+dx0;
		x12=x1:dx0/100:x2;
		R=[x12' zeros(length(x12),2)];
		for i=1:length(x12)
			y1=squeeze(uit(end-1,2,:))+(x12(i)-squeeze(uit(end-1,1,:))).*tan(hstraal(:,4));
			R(i,2)=min(y1);
			R(i,3)=max(y1);
		end
		[dmin,imn]=min(R(:,3)-R(:,2));
		dmin=[x12(imn),dmin];
		if doeplotstraal
			line(x12(imn)+[0  0],[-1 1]*D/2)
		end
	end
end

function [x,y]=getcircpt(cx,R,x0,y0,phi)

if isinf(R)
	x=cx;
else
	cphi=cos(phi);
	tphi=tan(phi);
	a=1/cphi^2;
	b=cx+(x0*tphi-y0)*tphi;
	c=cx*cx+y0*y0+x0*x0*tphi^2-2*x0*y0*tphi-R*R;

	D=sqrt(b*b-a*c);
	if (x0-cx)^2+y0^2<R*R
		x=(b+D*sign(cphi))/a;
	elseif cphi>0
		x=(b-D)/a;
	else
		x=(b+D)/a;
	end
end
y=y0+(x-x0)*tan(phi);
