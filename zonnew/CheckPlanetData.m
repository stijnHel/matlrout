function D = CheckPlanetData(p,v)
%CheckPlanetData - Check cPlanet for planets (compare with vsop87)
%   D = CheckPlanetData(p[,v])
%       p: planet name
%       v: cPlanet-object (created using p if not given)

if nargin<2 || isempty(v)
	v = cPlanet(p);
end

t = (calcjd(1,1,2000):10:calcjd(1,1,2030))';

P87 = calcvsop87(p,t);
R = P87(:,3)*unitcon('AU');
Q87 = R.*[[cos(P87(:,1)),sin(P87(:,1))].*cos(P87(:,2)),sin(P87(:,2))];

P = zeros(size(Q87));
for i=1:length(t)
	P(i,:) = v.CalcPos(t(i));
end

dP = P-Q87;
dP_rms = rms(dP);
err = rms(dP_rms)/rms(R);

D = var2struct(t,R,P87,Q87,P,dP,dP_rms,err);
