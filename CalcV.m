function [V,Tv,A,PTm1,PTm2] = CalcV(T,P,dx)
%CalcV    - Calculate velocity over fixed(/minimal) distance
%   [V,Tv,A,Pm1,Pm2] = CalcV(T,P,dx)
%      T,P: time (vector) and position
%      dx: minimal distance
%      
%      V,Tv: distance (scale is "P-scale" / "T-scale")
%          if T: datetime ==> T is converted to time in seconds
%      A: angle (radians) of direction
%      Pm1, Pm2: two ways to calculate mean position

warning('Not ready!!!!! - until now, "close to useless"....')

if isa(T,'datetime')
	T = datenum(T)*86400;
end
Tv = T;
V = zeros(size(T));
A = zeros(length(V),2);
PTm1 = zeros(length(T));
PTm2 = PTm1;

Dcum = [0;cumsum(sqrt(sum(diff(P).^2,2)))];
iPt1 = 1;
i = find(Dcum>=dx,1);
if isempty(i)
	error('Sorry, P-range is too short compared to distance resolution!')
end
for iPt2 = i:length(T)
	while iPt2-iPt1>1 && Dcum(iPt2)-Dcum(iPt1)>dx
		iPt1 = iPt1+1;
	end
	% put data on iPt2 or something in between??!!!!
	dP = P(iPt2,:)-P(iPt1,:);
	A(iPt2) = atan2(dP(2),dP(1));
	V(iPt2) = sqrt(sum(dP.^2))/(T(iPt2)-T(iPt1));
	Tv(iPt2) = mean(T([iPt1,iPt2]));
	% Pm1 - middle point between P1,P2
	% Pm2 - (?)weighted average point between t1,t2?
end
% extend beginning/ending parts?
