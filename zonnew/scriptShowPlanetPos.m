%scriptShowPlanetPos - navigate through planet positions
P={'zon','mercurius','venus','mars','jupiter','saturnus'};
t=calcjd(21,7,2018)+(0:0.02:20);
E=zeros(1,length(P)*2,length(t));
status('Positie-bepaingen',0)
for i=1:length(t)
	for j=1:length(P);E(1,j*2-1:j*2,i)=calcposhemel([1.3 42.8]*pi/180,t(i),P{j})*180/pi;end
	status(i/length(t))
end
status
ST=cell(size(t));for i=1:numel(t);ST{i}=calccaldate(t(i)+1/12,[],true);end
cnavmsrs(permute(E([1 1],:,:),[1 3 2]),[],'kols',2:2:length(P)*2,'kanx',1:2:length(P)*2,'msrs',ST)
xlim([-120 120])
ylim([-10 90])
l=findobj(gcf,'type','line');
set(l(6),'marker','o')
set(l(5),'marker','x')
set(l(4),'marker','+')
set(l(3),'marker','<')
set(l(2),'marker','>')
set(l(1),'marker','>')
legend(P)

l=zeros(1,length(P));
ccc=get(gca,'colororder');
for i=1:length(P);
	l(i)=line(squeeze(E(1,i*2-1,:)),squeeze(E(1,i*2,:))	...
		,'linestyle',':'	...
		,'color',ccc(i,:)	...
		,'tag','Pcurve'	...
		);
end
