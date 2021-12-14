function [y,info]=findpersig(x)
%FINDPERSIG - Find periodic part in a signal

iData=[];
hLine=[];
if nargin==0
	hLine=findobj(gca,'type','line');
	if length(hLine)~=1
		error('Geen lijn gevonden')
	end
	xl=get(gca,'xlim');
	xd=get(hLine,'xdata');
	x=get(hLine,'ydata');
	iData=find(xd>=xl(1)&xd<=xl(2));
	x=x(iData);
end
x1=calcperdiffs(x);
%[mn,xperlijst]=findlocalminima(x1,'dxHist',(max(x1)-min(x1))/10);
[mn,xperlijst]=findlocalminima(x1);
if isempty(mn)
	error('Niets gevonden')
end
Dtot=max(x1)-min(x1);

% vervangen van slecht werkende dxHist van findlocalminima
Dmin=Dtot/10;
[mnmn,i]=min(mn);
i0=i;
while i<length(mn)
	if max(x1(xperlijst(i):xperlijst(i+1)))-max(mn(i:i+1))<Dmin
		if mn(i)<mn(i+1)
			mn(i+1)=[];
			xperlijst(i+1)=[];
		else
			mn(i)=[];
			xperlijst(i)=[];
		end
	else
		i=i+1;
	end
end
i=i0;
while i>1
	if max(x1(xperlijst(i):xperlijst(i-1)))-max(mn(i-1:i))<Dmin
		if mn(i)<mn(i-1)
			mn(i-1)=[];
			xperlijst(i-1)=[];
		else
			mn(i)=[];
			xperlijst(i)=[];
		end
	end
	i=i-1;
end
xpmax=length(x)*.85;
mn(xperlijst>xpmax)=[];
xperlijst(xperlijst>xpmax)=[];
mn(xperlijst<10)=[];
xperlijst(xperlijst<10)=[];
i=length(mn);
while i&&xperlijst(i)>length(x)*.4
	i=i-1;
end
while i
	[j,del]=findclose(xperlijst(i+1:end),xperlijst(i)*2-1);
	if del>10
		xperlijst(i)=[];
		mn(i)=[];
	end
	i=i-1;
end
minmn=min(mn);
mnlim=max(Dtot/1e3,minmn*5);
xperlijst(mn>mnlim)=[];
mn(mn>mnlim)=[];
if length(mn)==1
	xper=xperlijst;
else
	di=diff(xperlijst);
	meandi=mean(di);
	stddi=std(di);
	xperlijst2=(xperlijst-1)./(1:length(xperlijst));
	xper=mean(xperlijst2);
	if stddi/meandi<5e-3
		if std(xperlijst2)>max(3,stddi)
			warning('!!??Er is iets onverwachts met het bepalen van de periode!!')
			%xper=meandi;
		end
	else
		Nlast=round((xperlijst(end)-1)/(xperlijst(1)-1));
		xper=(xperlijst(end)-1)/Nlast;
		N=(xperlijst-1)/xper;
		if all(abs(N-round(N))>.01)
			warning('Dit is voorlopig te moeilijk voor mij...')
			xper=[];
		end
	end
end
roundper=round(xper);
if isempty(xper)
	y=[];
	ncycli=[];
else
	ncycli=floor(length(x)/xper);
	if ncycli>5
		warning('Dit is gemaakt voor een kleiner aantal cycli - wees voorzichtig met resultaten')
	end
	y=mean(reshape(x(1:ncycli*roundper),roundper,ncycli),2);
	%!niets gedaan met "rest van signaal"
	%!enkel goed voor constante periode!
end
if nargout>1
	info=struct('x',x,'x1',x1,'mn',mn,'xperlijst',xperlijst	...
		,'xper',xper,'nper',roundper,'ncycli',ncycli	...
		,'iData',iData,'hLine',hLine	...
		,'y',y	... voor de volledigheid wordt dit toch ook toegevoegd
		);
end
