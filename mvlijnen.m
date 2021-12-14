function mvlijnen(figVan,figNaar,opties)
% MVLIJNEN - Verplaatst lijnen van een figuur naar een andere
%    mvlijnen(figVan,figNaar,opties)
%      opties : (als gegeven)
%         cell-vector met paren van "optie-naam","optie-gegeven"
%         mogelijkheden :
%            lijn-gegevens (matlab-gegevens)
%            'dx' : verplaatst de lijnen met een zekere waarde
%                   volgens x-as
%            'dy' : verplaatst de lijnen met een zekere waarde
%                   volgens y-as
n=length(get(figVan,'Children'));
if n>3
	nc=2;
	nr=ceil(n/2);
else
	nc=1;
	nr=n;
end
if ~exist('opties','var')
	opties={};
elseif ~iscell(opties)
	opties={};
elseif rem(length(opties),2)
	error('Verkeerde input voor opties')
end
for i=1:n
	figure(figVan);
	subplot(nr,nc,i);
	l=get(gca,'children');
	figure(figNaar);
	subplot(nr,nc,i);
	set(l,'parent',gca);
	for j=1:2:length(opties)
		switch opties{j}
		case 'dx'
			for k=1:length(l)
				set(l(k),'XData',get(l(k),'XData')+opties{j+1})
			end
		case 'dy'
			for k=1:length(l)
				set(l(k),'YData',get(l(k),'YData')+opties{j+1})
			end
		otherwise
			set(l,opties{j},opties{j+1})
		end
	end
end
