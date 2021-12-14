function [dc,td,ti]=calcdc(fnaam,ne,varargin)
% CALCDC - Leest metingen van PWM-stroom en berekent duty-cycle
%     [dc,td,ti]=calcdc(fnaam);
%     [dc,td,ti]=calcdc(e,ne[,options]);

doeplot=nargout==0;
L=0.4;
[iTimeChan]=[];
[iPWMchan]=[];
[t]=[];
if nargin>2
	setoptions({'doeplot','L','iTimeChan','iPWMchan','t'},varargin{:})
end
if ischar(fnaam)
	[em,nem,~,~,G]=leesalg(fnaam);
elseif isnumeric(fnaam)
	if length(fnaam)==1
		[em,nem,~,~,G]=leesTDMS(fnaam);
	else
		em=fnaam;
		nem=ne;
	end
else
	error('???input calcdc???!!!')
end
bTimeUsed=false;
if isempty(t)
	if isempty(iTimeChan)
		if size(em,2)>1
			iTimeChan=1;
			t=em(:,iTimeChan);
			bTimeUsed=true;
		else
			t=timevec(G,em);
		end
	else
		t=em(:,iTimeChan);
		bTimeUsed=true;
	end
end
if isempty(iPWMchan)
	if bTimeUsed
		iPWMchan=2;
	else
		iPWMchan=1;
	end
end
PWM=em(:,iPWMchan);

ie=find(PWM(2:end,1)>L&PWM(1:end-1,1)<=L);
ti=t(ie,1)+(L-PWM(ie,1))./(PWM(ie+1,1)-PWM(ie,1)).*(t(ie+1,1)-t(ie,1));
ie=find(PWM(2:end,1)<L&PWM(1:end-1,1)>=L);
td=t(ie,1)+(L-PWM(ie,1))./(PWM(ie+1,1)-PWM(ie,1)).*(t(ie+1,1)-t(ie,1));
if ti(1)>td(1)
	td(1)=[];
end
if length(ti)>length(td)
	ti(end)=[];
end
dc=(td(1:end-1)-ti(1:end-1))./diff(ti)*100;
if doeplot
	nfigure
	subplot 211
	plot(t,PWM);grid
	subplot 212
	plot(ti(1:end-1),dc);grid
end
