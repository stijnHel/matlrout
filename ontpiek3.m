function [y,x_out]=ontpiek3(x_in,HPfilt,opties)
%ONTPIEK3 - Verwijdert pieken op derde manier (basis : std-afwijking)
%     y=ontpiek3(x[,HPfilt[,opties]])
%        x mag een matrix zijn.  De kleinste dimensie wordt beschouwd
%           als deze voor aparte kanalen.
%   punten die verder dan N_STD keer standaardafwijking tov gemiddelde
%        worden verwijderd
%   verwijderde punten worden vervangen door bepaling op basis van punten
%        N_NEIG punten verwijderd zijn van weggehaalde punt
%        als geen dicht bij gelegen punten gevonden worden, worden ze NaN
%   mogelijkheid (nog niet voorzien) is er om het zoeken naar te
%        verwijderen punten te doen na een highpass-filter
%
%   HPfilt : high-pass filter
%       struct('B',B,'A',A) : filter-definition (to be used with filter)
%       k : first order high-passfilter ("forgetfactor")
%           k=0 : filter gives diff(x)
%           k=1 : no filter
%   opties kunnen gedrag nog veranderen :
%       cell-vector met paren :
%            n_std : laat toe te verwijderen gebied te veranderen
%            n_neig : laat toe het aantal te wijzigen 
%
%  Deze methode werkt, met de gepaste filter-parameters goed, maar kan wel
%  soms traag lopen, wanneer veel punten vervangen moeten worden.  Bij
%  langdurige pieken (langer dan de helft van N_NEIG) kunnen ongewenste
%  effecten optreden.  Ook met kleine waarden van N_STD, of met verre van
%  gaussiaanse ruis op het signaal, kunnen mogelijk minder gewenste
%  resultaten verkregen worden.

bTran=false;
x=x_in;
if size(x,1)<size(x,2)
	x=x';
	bTran=true;
end

n=length(x);
y=x;
if exist('HPfilt','var')&&~isempty(HPfilt)
	x=x-x(ones(1,n),:);
	if isstruct(HPfilt)
		x=filter(HPfilt.B,HPfilt.A,x);
	elseif length(HPfilt)==1
		x1=x(1,:);
		for i=2:n
			x2=x(i,:);
			x(i,:)=x(i-1,:)*HPfilt+(x2-x1);
			x1=x2;
		end
	end
end

N_STD=5;	% remove points outside 5 sigma limits
N_NEIG=10;	% distance of neighbouring points

if exist('opties','var')
	sOpt={'N_STD','N_NEIG'};
	for i=1:2:length(opties)
		j=strmatch(upper(opties{i}),sOpt,'exact');
		if ~isempty(j)
			assignval(sOpt{j},opties{i+1});
		else
			error('Onbekende optie')
		end
	end
end

m=mean(x);
s=std(x);

for iCol=1:size(x,2)
	iRemove=find(x(:,iCol)<m(iCol)-N_STD*s(iCol)|x(:,iCol)>m(iCol)+N_STD*s(iCol));
	y(iRemove,iCol)=NaN;

	% vervangen punten gebruiken voor volgende bepalingen of niet?
	%    nu niet
	for j=iRemove(:)'
		i1=max(j-N_NEIG,1):j-1;
		i2=j+1:min(j+N_NEIG,n);
		k1=find(~isnan(y(i1,iCol)));
		k2=find(~isnan(y(i2,iCol)));
		if isempty(k1)
			if isempty(k2)
				% niets
			else % ~isempty(k2)
				y(j,iCol)=y(j+k2(1),iCol);
			end
		else % ~isempty(k1)
			if isempty(k2)
				y(j,iCol)=y(i1(k1(end)),iCol);
			else
				k1=[i1(k1)';i2(k2)'];
				y1=y(k1,iCol);
				p=polyfit(k1-j,y1-m(iCol),1);
				y(j,iCol)=polyval(p,0)+m(iCol);
			end
		end
	end
end

if bTran
	y=y';
end
if nargout>1
	if bTran
		x_out=x';
	else
		x_out=x;
	end
end
