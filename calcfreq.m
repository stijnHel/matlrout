function [f,t,iINC]=calcfreq(e,e0,iSignal,dt,dimin)
% CALCFREQ - Berekent frequentie op basis van stijgende flanken
%    Zoekt doorgangen door een vaste waarde.  Er wordt lineaire
%    interpolatie gebruikt voor "subindex-niveau".
%
%  [f,t]=calcfreq(e[,e0,iSignal,dt,dimin])
%     e  - de input, dit mag een matrix zijn (zie iSignal)
%     e0 - de "doorgangswaarde" default : gemiddelde waarde (!!niet 0!!)
%         als string - waarde wordt geinterpreteerd als fractie tussen min/max genomen
%     iSignal - kolom (of rij) die als signaal genomen wordt
%            (maximale grootte wordt gebruikt als "signaal-data")
%     dt - sampletijd - default : 1 als iSignal==1, anders op basis van
%            eerste kolom (of rij) op basis van eerste 2 punten
%     dimin - minimale afstand (in "index-ruimte") tussen twee
%            opeenvolgende doorgangen (om ruis uit te filteren)
%            default 6

if size(e,1)<size(e,2)
	e=e';
end
if ~exist('iSignal','var')|isempty(iSignal)
	iSignal=size(e,2);
end
if ~exist('e0','var')|isempty(e0)
	e0=mean(e(:,iSignal));
elseif ischar(e0)
	e0=str2num(e0);
	if e0>1
		e0=e0/100;	% procentueel
	end
	mne=min(e(:,iSignal));
	e0=mne+e0*(max(e(:,iSignal))-mne);
end
if ~exist('dt','var')|isempty(dt)
	if iSignal>1
		dt=e(2)-e(1);
		if dt<=0
			error('Onbruikbare sampletijd')
		end
	else
		dt=1;
	end
end
if ~exist('dimin','var')|isempty(dimin)
	dimin=6;
end

iINC=find(e(1:end-1,iSignal)>e0&e(2:end,iSignal)<=e0);
iINC=iINC+(e0-e(iINC,iSignal))./(e(iINC+1,iSignal)-e(iINC,iSignal));

j=find(diff(iINC)<dimin);
k=length(j);
while k>0
	k1=k-1;
	while k1>0
		if j(k)-j(k1)>=dimin
			break;
		end
		k1=k1-1;
	end
	k0=k1+1;
	j1=j(k0);
	j2=j(k)+1;
	iNew=(iINC(j1)+iINC(j2))/2;
	iINC(j1)=iNew;
	iINC(j1+1:j2)=[];
	k=k1;
end

f=1/dt./(diff(iINC));
t=(iINC(1:end-1)+iINC(2:end))*(dt/2);
