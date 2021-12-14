function A=calcasurf(S)
%CALCASURF - Berekent oppervlakte van een "surface"

error('niets klaar')
A=0;
switch S.type
case 'sphere'
	if isfield(S(i).D,'yzRmax')
		A=pi*S(i).D.yzRmax^2;	% ?geen andere begrenzing?
	elseif isfield(S(i).D,'polygone')
	else
	end
	warning('Niet klaar')
case 'surf'
end
