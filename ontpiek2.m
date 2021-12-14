function [ontpiekt,n]=ontpiek2(e,limPiek,minmax,varargin)
% ONTPIEK2 - Verwijdert pieken uit meting
%          [ontpiekt,i]=ontpiek2(e,limPiek,minmax[,options]);
%
%    Deze versie is een snelle eenvoudige manier die de vector doorloopt,
%      en wanneer er een hoge sprong gezien wordt, wordt de laatste waarde
%      overgenomen.  Deze methode werkt goed wanneer een continue varierend
%      signaal met pieken gegeven wordt.  Pieken mogen over meerdere
%      opeenvolgende punten verspreid zijn.  Maar deze methode werkt
%      helemaal niet goed wanneer relatief grote stappen in het signaal
%      zitten.  Dan kan deze stap vervangen worden door een konstant lopend
%      signaal.
%   Wanneer limPiek niet gegeven wordt, wordt een waarde genomen van 1/10
%      van het bereik van het signaal (max()-min()).
% Er wordt vermeden dat hele stukken weggehaald worden, door een maximaal
%    aantal opeenvolgende waarden te gebruiken.
%    aan te passen via optie 'NdelMax', standaard 10

NdelMax=10;
bIndexOut2=true;	% to be backward compatible default true
if ~isempty(varargin)
	setoptions({'NdelMax','bIndexOut2'},varargin{:})
end

nKan=min(size(e));
if nKan~=1
	ins={};	% additional inputs
	if nargin>1
		ins{1}=limPiek;
		if nargin>2
			ins{2}=minmax;
		end
	end
	ontpiekt=e;
	n=cell(1,nKan);
	for i=1:nKan
		if size(e,1)==nKan
			[ontpiekt(i,:) n{i}]=ontpiek2(e(i,:),ins{:});
		else
			[ontpiekt(:,i) n{i}]=ontpiek2(e(:,i),ins{:});
		end
	end
	return
end
if ~exist('minmax','var')||isempty(minmax)
	minmax=[min(e) max(e)];
end
if ~exist('limPiek','var')||isempty(limPiek)
	limPiek=diff(minmax)/10;
	if limPiek==0
		limPiek=1;
	end
end


Ntot=length(e);
ontpiekt=e;
j=1;
while ontpiekt(j)<minmax(1)||ontpiekt(j)>minmax(2)
	j=j+1;
	if j>N-1
		error('Te veel waarden buiten het geldig gedeelte');
	end
end
if j>1
	ontpiekt(1:j-1)=ontpiekt(j);
end
x0=ontpiekt(1);
b=false(Ntot,1);
li=0;
i=j;
while i<=Ntot
	if ontpiekt(i)<minmax(1)||ontpiekt(i)>minmax(2)||abs(ontpiekt(i)-x0)>limPiek
		li=li+1;
		if li>NdelMax
			i0=i+1-li;
			ontpiekt(i0:i-1)=e(i0:i-1);
			b(i0:i-1)=false;
			i=i0;
			li=0;
			x0=ontpiekt(i);
		else
			ontpiekt(i)=x0;
			b(i)=true;
		end
	else
		x0=ontpiekt(i);
		li=0;
	end
	i=i+1;
end
if nargout>1
	if bIndexOut2
		n=find(b);
	else
		n=b;
	end
end

