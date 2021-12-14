function Pout=plotplan(T,el)
%plotplan - plot positie van planten (in cirkelvormige banen!)

if ~exist('el','var') || isempty(el)
	el={'mercurius','venus','aarde','mars','jupiter','saturnus','uranus','neptunus'};
end
phi=0:pi/30:pi*2+100*eps;
P=zeros(length(el),3);
if ~exist('T','var') || isempty(T)
	T=clock;
	T=T([3 2 1 4 5 6]);
	T(4)=T(4)-1;
	if T(2)>=3 || T(2)<=10	% super simpele zomertijd-bepaling
		T(4)=T(4)-1;
	end
elseif length(T)>6
	getmakefig plotplan
	plot(0,0,'x');grid
	axis equal
	L=zeros(length(el),3);
	D=el;
	for i=1:length(el)
		L(i,1)=line(0,0,'color',[0 1 0],'linestyle','--');
		L(i,2)=line(0,0,'color',[1 0 0],'marker','x');
		L(i,3)=text(0,0,el{i});
		[PP,D{i},dt]=calcbaan(el{i},T(1));
		line(PP(:,1),PP(:,2),'linestyle',':','userdata',[T(1) dt])
	end
	PP=zeros(2,length(el),length(T));
	P=zeros(length(el),3);	% en waarom wordt dit nu gebruikt?
	for iT=1:length(T)
		for i=1:length(el)
			P(i,:)=calcvsop87(D{i},T(iT));
			x=cos(P(i,1))*P(i,3);
			y=sin(P(i,1))*P(i,3);
			PP(1,i,iT)=x;
			PP(2,i,iT)=y;
			set(L(i,1),'XData',cos(phi)*P(i,3),'YData',sin(phi)*P(i,3));
			set(L(i,2),'XData',x,'YData',y);
			set(L(i,3),'position',[x,y]);
		end
		t1=calccaldate(T(iT));
		title(datestr(t1([3 2 1 4 5 6])))
		if false
			pause(0.02);
		else
			drawnow
		end
		if iT==1
			set(gca,'XLimMode','manual','YLimMode','manual')
		end
	end
	if nargout
		Pout=PP;
	end
	return
end

for i=1:length(el);P(i,:)=calcvsop87(el{i},T);end
plot(P(:,3).*cos(P(:,1)),P(:,3).*sin(P(:,1)),'x');grid
axis equal
for i=1:length(el);line(cos(phi)*P(i,3),sin(phi)*P(i,3),'color',[0 1 0],'linestyle','--');end
for i=1:length(el);text(P(i,3)*cos(P(i,1)),P(i,3)*sin(P(i,1)),el{i});end

function [P,D,dt]=calcbaan(el,T0)
P=zeros(length(el),2);
D=calcvsop87(el,'zoek');
t=T0;
dt=1;
p1=calcvsop87(D,t);
p2=calcvsop87(D,t+dt);
dp=p2(1)-p1(1);
if dp<-4
	dp=dp+2*pi;
elseif dp>4 || dp<0
	error('Er loopt iets fout')
end
dt=dt*2*pi/dp/300;
P(1,1)=p1(3)*cos(p1(1));
P(1,2)=p1(3)*sin(p1(1));
nch=0;
iP=1;
d=1;
while nch<2
	t=t+dt;
	p2=calcvsop87(D,t);
	iP=iP+1;
	P(iP,1)=p2(3)*cos(p2(1));
	P(iP,2)=p2(3)*sin(p2(1));
	if d*(p2(1)-p1(1))<=0
		nch=nch+1;
		d=p2(1)-p1(1);
	end
end
P=P(1:iP,:);
