function [uit,uit2]=m2txt(snd)
% M2TXT   - Morse naar tekst-omzetting

mortab = [	...
		1 2 0 0;	... a
		2 1 1 1;	... b
		2 1 2 1;	... c
		2 1 1 0;	... d
		1 0 0 0;	... e
		1 1 2 1;	... f
		2 2 1 0;	... g
		1 1 1 1;	... h
		1 1 0 0;	... i
		1 2 2 2;	... j
		2 1 2 0;	... k
		1 2 1 1;	... l
		2 2 0 0;	... m
		2 1 0 0;	... n
		2 2 2 0;	... o
		1 2 2 1;	... p
		2 2 1 2;	... q
		1 2 1 0;	... r
		1 1 1 0;	... s
		2 0 0 0;	... t
		1 1 2 0;	... u
		1 1 1 2;	... v
		1 2 2 0;	... w
		2 1 1 2;	... x
		2 1 2 2;	... y
		2 2 1 1 	... z
		];

snd=snd(:);
s=abs(snd(2:end-2)-snd(1:end-3))+abs(snd(3:end-1)-snd(1:end-3))+abs(snd(4:end)-snd(1:end-3));
cst=s==0;
if ~cst(1)
	cst=[ones(2,1);cst];
end
if ~cst(end)
	cst(end+1)=1;
end

i=find(diff(cst));
di=diff(i);

if rem(length(di),2)
	di(end+1)=0;
end
di=reshape(di,2,length(di)/2)';
if length(di)<8
	error('Ik hoopte een langere tekst te krijgen.  Dit werkt nog niet')
end
lm=mean(di(1:end-1,1));
j=find(di(1:end-1,1)<lm);
ld=mean(di(j,1));
sld=std(di(j,1));
if sld/ld>0.1
	warning('!Grote variatie op dot-lengte');
end
j=find(di(1:end-1,1)>lm);
ls=mean(di(j,1));
sls=std(di(j,1));
if sls/ld>0.1
	warning('!Grote variatie op stroke-lengte');
end
[n,x]=hist(di(:,2),100);
ni=find(n>2);
if any(diff(ni)==1)
	j=find(diff(ni)==1);
	while ~isempty(j)
		n(j(1)+1)=n(j(1))+n(j(1)+1);
		n(j(1))=0;
		j(1)=[];
	end
	ni=find(n>2);
end
if length(ni)~=3
	fprintf('%6.0f\n',x(ni));
	warning('Ik weet niet goed wat te doen met de lege ruimtes');
	lb=x(ni(1))*1.2;
	lb1=lb*1.2;
else
	lb=mean([x(ni(1)) x(ni(2))]);
	lb1=mean([x(ni(2)) x(ni(3))]);
end

gel=(di(:,1)>(ld+ls)/2)+1;
spatie=(di(:,2)>lb)+(di(:,2)>lb1);
spatie(end)=1;

j=[0;find(spatie)];
dj=diff(j);
if any(dj)>4
	error('Te lange constructies')
end
t='';
mtxt=zeros(length(j)-1,4);
stxt=blanks(length(j)-1);
for k=1:length(j)-1
	mtxt(k,1:dj(k))=gel(j(k)+1:j(k+1))';
	l=find(all((mortab==mtxt(k*ones(size(mortab,1),1),:))'));
	if ~isempty(l)
		t(end+1)=setstr('a'-1+l);
	else
		t(end+1)='?';
	end
	stxt(k)=t(end);
	if spatie(j(k+1))>1
		t(end+1)=' ';
	end
end

if nargout
	uit=di;
	if nargout>1
		uit2=struct('i',i,'di',di	...
			,'ld',ld,'ls',ls,'sld',sld,'sls',sls	...
			,'lb',lb,'lb1',lb1	...
			,'gel',gel,'spatie',spatie,'mtxt',mtxt,'txt',t);
	end
else
	nfigure
	plot(snd);grid
	for k=2-cst(i(1)):2:length(i)-1
		line([i(k) i(k+1)],[1.1 1.1],'color',[1 0 0])
	end
	fprintf('%s\n',t)
	for k=1:length(stxt)
		text(i(j(k+1)),1.2,stxt(k),'Horizontalalignment','left','VerticalAlignment','bottom')
	end
end
