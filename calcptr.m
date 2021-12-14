function R=calcptr(T,R0,R)
%calcptr  - Calculates platina resistance value
%       R=calcptr(T[,R0])
%            T in degrees C
%            R0 - resistance value for 0 degC (default 100)
%            R in ohm (in fact units of R0)
%       T=calcptr([],R0,R)
%            reverse calculation
%
%       range : -280-850 degC
%
% ref. tc - guite to thermocouple and resistance thermometry (issue 6.0)
%
% Stijn Helsen - FMTC 2007

persistent RTDrevChar

if ~exist('R0','var')||isempty(R0)
	R0=100;
end

if nargin==3
	% reverse calculation
	if isempty(RTDrevChar)
		T=(-50:200)';	%!!(limited range
		Rt=calcptr(T,1);
		RTDrevChar=polyfit(Rt-1,T,7);
	end
	R=polyval(RTDrevChar,R/R0-1);	% temperature
	return
end

if length(T)>1
	R=(1+3.9083e-3*T-5.775e-7*T.^2-4.183e-12*(T-100).*T.^3).*(T<0)	...
		+(1+3.9083e-3*T-5.775e-7*T.^2).*(T>=0);
elseif T<0
	if T<-200
		warning('CALCPTR:lowTemp','!lower temperature than allowed!! - extrapolation is used')
	end
	R=1+3.9083e-3*T-5.775e-7*T.^2-4.183e-12*(T-100).*T.^3;
else
	if T>850
		warning('CALCPTR:highTemp','!higher temperature than allowed!! - extrapolation is used')
	end
	R=1+3.9083e-3*T-5.775e-7*T.^2;
end
R=R0*R;
