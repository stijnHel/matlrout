function [R,a]=rotzz(Z1)
% ROTZZ    - rotatie-matrix van kleinste rotatie van Z naar Z1

if max(abs(Z1(1:2)))==0
	% Geen rotatie
	R=eye(3);
	return
end

a=atan2(sqrt(sum(Z1(1:2).^2)),Z1(3));	% iets nauwkeuriger
%Z1=Z1(:)/sqrt(sum(Z1.^2));	% ??nodig?.
%a=acos(Z1(3));
X1=cross(Z1,[0;0;1]);
b=atan2(X1(2),X1(1));

R=rotzr(b)*rotxr(-a)*rotzr(-b);
a=a/pi*180;
