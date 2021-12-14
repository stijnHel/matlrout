function conv2bit(ax,carr)
% CONV2BIT - Converteert data in grafiek naar vlaggen
%    conv2bit(ax,carr)
%      ax : as voor de conversie (als niet gegeven huidig actieve as)
%      carr : gebruikt data als bits
%         als carr niet gegeven of leeg :
%           als 1 kanaal (en sig OK) --> carr=1
%              anders carr=0 (aparte lijnen worden getest op ~=0)
%              sig OK : maximaal 16 bits, en geen decimale data
%     (!!) oorspronkelijke lijnen worden verwijderd bij carr(!!)
%          bij carr==0 worden de lijnen vervangen

if ~exist('ax','var')
	ax=[];
end
if ~exist('carr','var')
	carr=[];
end
if isempty(ax)
	ax=gca;
end
l=findobj(ax,'Type','line');
if  isempty(l)
	error('Geen lijnen gevonden')
end
if isempty(carr)
	if length(l)==1
		y=get(l,'ydata');
		if min(y)<0|max(y)>65535|any(y-floor(y)~=0)
			carr=0;
		else
			carr=1;
		end
	else
		carr=0;
	end
end
if carr
	%???gebruik van plotcarr???
	nb=0;
	for i=1:length(l)
		x=get(l(i),'xdata');
		y=get(l(i),'ydata');
		delete(l(i))
		if min(y)<0|max(y)>65536|any(y-floor(y)~=0)
			error('verkeerde data')
		end
		while any(y)
			line(x,nb+rem(y,2)*0.9)
			nb=nb+1;
			y=floor(y/2);
		end
	end
else
	nb=0;
	for i=1:length(l)
		y=get(l(i),'ydata');
		set(l(i),'ydata',nb+(y~=0)*0.9)
		nb=nb+1;
	end
end
set(ax,'ytick',0:nb-1,'ylim',[-0.5 nb])
