function loopdoorlijnen(X,ind,opties)% LOOPDOOREENLIJNEN - laat bolletjes lopen over lijnen%     loopdoorlijnen(Z,<indexlijst>[,opties])%       met Z een array en indexlijst een n x 2 array met indices voor x en y%  of%     loopdoorlijnen[(opties)]%        neemt lijnen van huidige as%            is het nuttig dit uit te breiden naar huidige figuur?if nargin==0|isempty(X)|~isnumeric(X)	if ~isnumeric(X)		opties=X;	end	l=findobj(gca,'Type','line');	if isempty(l)		error('Ik vind geen geschikte lijnen')	end	L=zeros(1,length(l));	for i=1:length(l)		L(i)=length(get(l(i),'XData'));	end	mL=max(L);	i=find(mL==L);	l=l(i);	X=zeros(mL,length(i)*2);	for i=1:length(l)		X(:,i*2-1)=get(l(i),'XData')';		X(:,i*2)=get(l(i),'YData')';	end	ind=reshape(1:2*length(l),2,length(l))';endif ~exist('opties','var')	opties=[];endS=struct('color',[1 0 0]	...	,'marker','o','markersize',20	...	,'markerfacecolor','none','markeredgecolor','auto'	...	,'erasemode','xor'	...	,'delay',0	...	);Sf=fieldnames(S);if iscell(opties)	i=1;	while i<=length(opties)		if ~ischar(opties{i});			error('Verkeerd gebruik van opties')		end		if strmatch(lower(opties{i}),Sf)			S=setfield(S,lower(opties{i}),opties{i+1});			i=i+1;		else			error('Verkeerd gebruik van opties')		end		i=i+1;	endelseif ~isempty(opties)	error('Verkeerd gebruik van opties')endl=line(X(1,ind(:,1)),X(1,ind(:,2)),'Color',S.color	...	,'Linestyle','none'	...	,'Marker',S.marker,'MarkerSize',S.markersize	...	,'MarkerFaceColor',S.markerfacecolor,'MarkerEdgeColor',S.markeredgecolor	...	,'EraseMode',S.erasemode	...	);figure(gcf);for i=1:size(X,1);	set(l,'XData',X(i,ind(:,1)),'YData',X(i,ind(:,2)));	if S.delay>0		pause(S.delay);	else		drawnow;	endenddelete(l)