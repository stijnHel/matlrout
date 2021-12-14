function Td=CalcDewPointT(T,RH)
%CalcDewPointT - Calculates dew point temperature (from T and RH)
%       Td=CalcDewPointT(T,RH)
%
%           T : temperature in [degree C]
%           RH: relative humidity in [%]
%
%           Td: result in [degree C]
%
%   Based on Sensirion documenation

Tm=243.12;
m=17.62;

k=(log10(RH)-2)/0.4343+(m*T)./(Tm+T);
Td=Tm*k./(m-k);

% other calculation, with the same result
%k2=log(RH/100)+m*T/(Tm+T);
%Td2=Tm*k2/(m-k2);
