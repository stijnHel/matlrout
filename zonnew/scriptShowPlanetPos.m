%scriptShowPlanetPos - navigate through planet positions
if ~exist('P','var')||isempty(P)||~iscell(P)
	P={'zon','mercurius','venus','mars','jupiter','saturnus'};
end
if ~exist('t','var')||~isnumeric(t)||~isvector(t)||length(t)<500
	t=calcjd(21,7,2018)+(0:0.02:20);
end
E=zeros(1,length(P)*2,length(t));
status('Positie-bepaingen',0)
for i=1:length(t)
	for j=1:length(P);E(1,j*2-1:j*2,i)=calcposhemel([1.3 42.8]*pi/180,t(i),P{j})*180/pi;end
	status(i/length(t))
end
status
ST=cell(size(t));for i=1:numel(t);ST{i}=calccaldate(t(i)+1/12,[],true);end
cN = cnavmsrs(permute(E([1 1],:,:),[1 3 2]),[],'kols',2:2:length(P)*2,'kanx',1:2:length(P)*2,'msrs',ST);
mTypes = {'o','x','+','<','<','>','*'};
xlim([-120 120])
ylim([-10 90])
for i=1:length(cN.hL{1})
	set(cN.hL{1}(i),'Marker',mTypes{rem(i-1,end)+1})
end
legend(P)

l=zeros(1,length(P));
ccc=get(gca,'colororder');
for i=1:length(P)
	l(i)=line(squeeze(E(1,i*2-1,:)),squeeze(E(1,i*2,:))	...
		,'linestyle',':'	...
		,'color',ccc(i,:)	...
		,'tag','Pcurve'	...
		);
end
