function [Xout,nX,dX]=plotlphprog(T)
% PLOTLPHPROG - Plot een LPH-testprogramma

global LPHpar

if isempty(LPHpar)
	Tm=[  0    0  900 1000 2000 6000 6400 10000;	...
		  0  100    0  -10  -15  -50  -50   -50;	...
		100  100  100  120  200  200    0   -50;	...
		200  100  100  120  200  200    0   -50;	...
		];
	[TmN,Tmg,TmT]=getmatr(Tm);
	LPHpar=struct('kv',19/1024,'iv_low',2.5,'iv_od',0.43	...
		,'Tm',Tm,'pF',[8 100]	...
		,'TmN',TmN,'Tmg',Tmg,'TmT',TmT	...
		,'Nvg',[0 100 200]	...
		,'NvN',[1400 5500 5500]	...
		,'g100',82	...
	);
end

if isfield(T,'prog')
	if length(T)~=1
		error('Slechts een programma tegelijk laten verwerken aub!!');
	end
	T=T.prog;
elseif ~isfield(T,'stap')
	error('Geen leesbaar programma');
end

p_stap=str2num(strvcat(T.stap));
p_gas=cat(1,T.gas)/LPHpar.g100*100;
p_jmp=cat(1,T.jmp);
p_incr=cat(1,T.incr);
p_alarm=cat(1,T.alarmcond);

i_jmp=find(p_jmp);
i0_jmp=p_stap(i_jmp);
j0_jmp=p_jmp(i_jmp);
j_jmp=j0_jmp;
for i=1:length(i_jmp)
	j_jmp(i)=find(j0_jmp(i)==p_stap);
end
lus=i_jmp>j_jmp;

x_jmp=zeros(1,length(T));
k=1:length(i_jmp);
while ~isempty(k)
	mni=min(i_jmp(k),j_jmp(k));
	[mn,i]=min(mni);
	if sum(mni==mn)>1
		i=find(mni==mn);
		[mx,j]=max(max(i_jmp(k(i)),j_jmp(k(i))));
		i=i(j);
	end
	j=1;
	while 1
		i1=min(i_jmp(k(i)),j_jmp(k(i)));
		i2=max(i_jmp(k(i)),j_jmp(k(i)));
		if any(x_jmp(j,i1:i2))
			j=j+1;
			if j>size(x_jmp,1)
				x_jmp(end+1,:)=0;
			end
		else
			x_jmp(j,i1:i2)=k(i);
			k(i)=[];
			break;
		end
	end
end

Tm=20;
Tt=20;
dt=0.5;
X=zeros(2000,7);
N=900;
v=0;
t=0;
iX=2;
pook=T(1).pook;
gas=p_gas(1);
iprog=1;
reg=T(1).regelVar;
regV=T(1).regelVal;
X(1,:)=[0,gas,N,v,Tm,Tt,iprog];
te=T(1).tijd;
ts=0;
cond=T(1).conditieVar;
status('Bepalen van testprogrammaverloop',0)
liprwarn=0;
while 1
	t=t+dt;
	if iX>size(X,1)
		X=[X;zeros(500,7)];
	end
	switch reg
	case {'','- geen -'}
		[N,v]=SimVeh(pook,gas,N,v,dt);
	case 'Snelheid'
		if v<regV
			gas=100;
			[N,v]=SimVeh(pook,gas,N,v,dt);
			if v>regV
				v=regV;
				gas=min(100,regV/2.1);
				N=GetNSet(pook,gas,v);
			end
		elseif v>regV
			gas=0;
			[N,v]=SimVeh(pook,gas,N,v,dt);
			if v<regV
				v=regV;
				gas=min(100,regV/2.1);
				N=GetNSet(pook,gas,v);
			end
		end
	otherwise
		error('niet voorzien');
	end
	Tm=min(100,Tm+0.5*dt);
	Tt=min(90,Tt+0.2*dt);
	X(iX,:)=[t,gas,N,v,Tm,Tt,iprog];
	switch cond
	case {'','- geen -'}
		c=0;
	case 'Temp koelwater motor'
		c=-1;
		cv=Tm;
	case 'Snelheid'
		c=-1;
		cv=v;
	case 'Temp transmissie 1'
		c=-1;
		cv=Tt;
	otherwise
		error('niet voorzien')
	end
	if c<0
		switch T(iprog).conditie
		case '<'
			c=cv<T(iprog).conditieVal;
		case '>'
			c=cv>T(iprog).conditieVal;
		case '<='
			c=cv<=T(iprog).conditieVal;
		case '>='
			c=cv>=T(iprog).conditieVal;
		end
	end
	if (te>0&t>te)|c
		if iprog==liprwarn
			fprintf('%g s ipv %g s\n',t-ts,T(iprog).tijd);
		end
		if iprog>=length(T)
			break;
		end
		iprog=iprog+1;
		pook=T(iprog).pook;
		reg=T(iprog).regelVar;
		regV=T(iprog).regelVal;
		cond=T(iprog).conditieVar;
		if p_gas(iprog)>=0
			gas=p_gas(iprog);
		end
		ts=t;
		if T(iprog).tijd>0
			te=t+T(iprog).tijd;
		else
			te=-t+T(iprog).tijd*1.5-30;
		end
	elseif all(abs(diff(X(iX-1:iX,2:end)))<1e-5)
		if t<te
			t=te;
		else
			warning(sprintf('stap %d wordt onderbroken omdat geen wijziging meer optreedt.\n',iprog));
			te=t;	% forceren om te stoppen
		end
	elseif te<0&t>-te&iprog>liprwarn
		liprwarn=iprog;
		warning(sprintf('!!!!te lange tijd in stap %d !!!!!',iprog));
	end
	iX=iX+1;
	status(iprog/length(T));
end
status

X=X(1:iX,:);
nfigure
as2=subplot('212');
p2=get(as2,'position');
set(as2,'ylim',[-1.5 2+size(x_jmp,1)],'position',p2+[-0.055 -0.05 0.05 -0.2])
subplot(211)
p1=get(gca,'position');
set(gca,'position',p1+[-0.055 -0.3 0.05 0.32])
[axs,hl1,hl2]=plotyy(X(:,1),X(:,[2 4]),X(:,1),X(:,3));grid
legend([hl1;hl2],'gaspedaal','snelheid','N_motor')
set(get(axs(1),'ylabel'),'string','gas [%], v [km/h]')
set(get(axs(2),'ylabel'),'string','N [1/min]')

axes(as2);
grid
ccc=get(as2,'colororder');

i=1;
while i<=iprog
	j=i+1;
	while j<=iprog&T(j).pook==T(i).pook
		j=j+1;
	end
	k=find(X(:,7)>=i&X(:,7)<j);
	if isempty(k)
		error('Kan stap niet vinden')
	elseif length(k)==1
		k=[max(1,k-1),k];
	end
	if k(1)>1
		k(1)=k(1)-1;
	end
	switch T(i).pook
	case 'P'
		icol=1;
	case 'R'
		icol=2;
	case 'N'
		icol=3;
	case 'D'
		icol=4;
	case 'S'
		icol=5;
	case 'L'
		icol=6;
	end
	line(X(k([1 end]),1),[-1 -1],'color',ccc(icol,:),'linewidth',4)
	i=j;
end

alarmen=[];
i=1;
while i<=iprog
	if p_alarm(i)
		j=i+1;
		while j<=iprog&p_alarm(j)==p_alarm(i)
			j=j+1;
		end
		k=find(X(:,7)>=i&X(:,7)<j);
		if isempty(k)
			error('Kan stap niet vinden')
		elseif length(k)==1
			k=[max(1,k-1),k];
		end
		if k(1)>1
			k(1)=k(1)-1;
		end
		if isempty(alarmen)
			alarmen=p_alarm(i);
			icol=1;
		elseif any(alarmen==p_alarm(i))
			icol=find(alarmen==p_alarm(i));
		else
			alarmen(end+1)=p_alarm(i);
			icol=length(alarmen);
		end
		line(X(k([1 end]),1),[0 0],'color',ccc(icol,:),'linewidth',4)
		text(mean(X(k([1 end]),1)),0,num2str(p_alarm(i)-1),'horizontalal','center','verticalal','bottom')
		i=j+1;
	else
		i=i+1;	% sneller?(zoeken naar eerst volgende)
	end
end

i=1;
while i<=iprog
	if T(i).tipdn
		j=i+1;
		while j<=iprog&T(j).tipdn
			j=j+1;
		end
		k=find(X(:,7)>=i&X(:,7)<j);
		if length(k)==1
			x1=X(k,1)+[0 dt];
		else
			x1=X(k([1 end]),1);
		end
		line(x1,[0.9 0.9],'color',ccc(1,:),'linewidth',4)
		i=j+1;
	else
		i=i+1;	% sneller?(zoeken naar eerst volgende)
	end
end

i=1;
while i<=iprog
	if T(i).tipup
		j=i+1;
		while j<=iprog&T(j).tipup
			j=j+1;
		end
		k=find(X(:,7)>=i&X(:,7)<j);
		if length(k)==1
			x1=X(k,1)+[0 dt];
		else
			x1=X(k([1 end]),1);
		end
		line(x1,[1.1 1.1],'color',ccc(2,:),'linewidth',4)
		i=j+1;
	else
		i=i+1;	% sneller?(zoeken naar eerst volgende)
	end
end
text(0,1,'-','horizontalalignment','left','verticalalignment','top','color',ccc(1,:))
text(0,1,'+','horizontalalignment','left','verticalalignment','bottom','color',ccc(2,:))

for i0=1:size(x_jmp,1)
	i=1;
	while i<=iprog
		if x_jmp(i0,i)
			j=i+1;
			while j<=iprog&x_jmp(i0,j)==x_jmp(i0,i)
				j=j+1;
			end
			k=find(X(:,7)>=i&X(:,7)<j);
			x1=X(k(1),1);
			if k(end)<size(X,1)
				x2=X(k(end)+1,1)-dt;	% vermijd te kort stuk bij "overslaan van constant gedeelte"
			else
				x2=X(k(end),1);
			end
			line([x1 x2],[1 1]+i0,'color',ccc(1+lus(x_jmp(i0,i)),:),'linewidth',4)
			text(mean([x1 x2]),1+i0,num2str(T(i_jmp(x_jmp(i0,i))).aantaljmp),'horizontalal','center','verticalal','bottom','Tag','njmp')
			if lus(x_jmp(i0,i))
				text(x2,1+i0,num2str(i0_jmp(x_jmp(i0,i))),'horizontalal','center','verticalal','top','tag','jmpstart')
				text(x1,1+i0,num2str(j0_jmp(x_jmp(i0,i))),'horizontalal','center','verticalal','middle','tag','jmpend')
			else
				text(x1,1+i0,num2str(i0_jmp(x_jmp(i0,i))),'horizontalal','center','verticalal','top','tag','jmpstart')
				text(x2,1+i0,num2str(j0_jmp(x_jmp(i0,i))),'horizontalal','center','verticalal','middle','tag','jmpend')
			end
			i=j+1;
		else
			i=i+1;	% sneller?(zoeken naar eerst volgende)
		end
	end
end

i=find(p_incr);
for j=1:length(i)
	k=find(X(:,7)==i(j));
	line([0 0]+X(k(1),1),[2 1.6+size(x_jmp,1)],'color',[0 0 0])
end
set(as2,'ytick',[-1 0 1],'yticklab',strvcat('pook','alarm','tip'))
navfig
figmenu

if nargout
	Xout=X;
	if nargout>1
		nX=strvcat('t','gas','Nmoto','v','Tmotor','Ttran','iprog');
		if nargout>2
			dX=strvcat('s','%','rpm','km/h','°C','°C','#');
		end
	end
end

function [N,v]=SimVeh(pook,gas,Nlast,vlast,dt)
global LPHpar

T=interp2(LPHpar.TmN,LPHpar.Tmg,LPHpar.TmT,Nlast,gas);
F=polyval(LPHpar.pF,vlast);
switch pook
case 'N'
	a=T/0.15;
	N=Nlast+a*30/pi*dt;
	a=-F/1200;
	v=vlast+a*3.6*dt;
	if v*vlast<0|abs(v)>abs(vlast)
		v=0;
	end
	if gas<1&(N-900)*(Nlast-900)<0
		N=900;
	end
case {'D','L','S'}
	Nsec=vlast/LPHpar.kv;
	if Nsec*LPHpar.iv_low+100>900
		if gas<1&Nlast<1000
			N=Nlast;
			v=vlast;
		else
			iv=Nlast/Nsec;
			F=T*iv/(LPHpar.kv/3.6*30/pi)-F;
			a=F/1200;
			v=vlast+a*3.6*dt;
			Nset=GetNSet(pook,gas,v);
			if Nlast>Nset
				N=max(Nlast-2000*dt,Nset);
			else
				N=min(Nlast+4000*dt,Nset);
			end
		end
	else
		a=1;
		v=vlast+a*3.6*dt;
		N=Nlast;
	end
case 'R'
	Nsec=vlast/LPHpar.kv;
	if Nsec*LPHpar.iv_low+100>900
		if gas<1&Nlast<1000
			N=Nlast;
			v=vlast;
		else
			iv=LPHpar.iv_low;
			F=T*iv/(LPHpar.kv/3.6*30/pi)-F;
			a=F/1200;
			v=vlast+a*3.6*dt;
			N=v/LPHpar.kv*LPHpar.iv_low;
		end
	else
		a=1;
		v=vlast+a*3.6*dt;
		N=Nlast;
	end
otherwise
	error('Niet voorzien')
end

function Nset=GetNSet(pook,gas,v)
global LPHpar

Nsec=v/LPHpar.kv;
Nset=interp1(LPHpar.Nvg,LPHpar.NvN,gas);
if pook=='S'
	Nset=min(5500,Nset+1000);
end
Nset=max(min(Nset,Nsec*LPHpar.iv_low),Nsec*LPHpar.iv_od);
