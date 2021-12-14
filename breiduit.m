function X=breiduit(N,tabel)
% BREIDUIT - Uitbreiding (extrapolatie) van een verbruikstabel
%
% sorteer tabel naar stijgende Tmotor
tabel = sortrows(tabel,[1 4]);

Tinterp = [5 9 14 19 28 37 46 55 64 74 83 92 100 110 115 120 125];

index=find(diff(tabel(:,1)));

% sla eerste toerental over
index=[index(2:end) ;length(tabel)];

% interpolatie per toerental
for i=1:length(index)-1
    vrbmot(i,:)=interp1(tabel(index(i)+1:index(i+1),4),tabel(index(i)+1:index(i+1),7),Tinterp);
end

X = [0 Tinterp;N(2:end)' vrbmot];

%  Extrapolatie naar hogere koppels (wegwerken van NaN waar het nodig is, met 
% alle beschikbare informatie

% Maak een indexlijst op van waar de Nan staan
for i=2:size(X,1)
	ll=isnan(X(i,:));
	ind = find(ll==1);
	j = ind(1);
	
	%  Bereken de eerste Nan voor elk toerental, op 
	%  basis van het verbruik bij het maximaal koppel (in tabelvrb)
	Tmax = tabel(index(i),4);
	Tboven = X(1,j);
	Tonder = X(1,j-1);
	vrbmax = tabel(index(i),7);
	vrbonder = X(i,j-1);
	X(i,j) = vrbonder + (vrbmax - vrbonder)/((Tmax-Tonder)/(Tboven-Tonder));
	
	% Zoek dan de eerstvolgende Nan om nog verder aan te vullen.
	%  Sla de index over als er geen Nan te vinden is voor een bepaald toerental
	ll=isnan(X(i,:));
	ind = find(ll==1);
	if ~isempty(ind)
		j = ind(1);
		% Bepaal het verbruik voor de gevonden Nan's  (pure extrapolatie)
		Tboven = X(1,j);
		Tonder = X(1,j-1);
		Tsubonder = X(1,j-2);
		vrbonder = X(i,j-1);
		vrbsubonder = X(i,j-2);
		X(i,j) = vrbonder + (vrbonder - vrbsubonder) * (Tboven - Tonder) / (Tonder - Tsubonder);
	end
end     
