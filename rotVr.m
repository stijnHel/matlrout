function R=rotVr(V,r)
% ROTV     - rotatiematrix voor verdraaiing langs as
%     R=rotV(V,a)
%         V: vector (moet niet genormaliseerd zijn)
%         a in radialen
%     R=rotV(V)
%         zelfde, maar a wordt gehaald uit lengte van V

if length(V)<3
	V(3)=0;
end
normV = sqrt(sum(V.^2));
if abs(normV-1)>1e-10
	V = V/normV;
end
if nargin==1 || isempty(r)
	r = normV;
end
V2 = V.^2;
s = sin(r);
c = cos(r);
R=[ V2(1)+(1-V2(1))*c      V(1)*V(2)*(1-c)-V(3)*s V(1)*V(3)*(1-c)+V(2)*s;
	V(1)*V(2)*(1-c)+V(3)*s V2(2)+(1-V2(2))*c      V(2)*V(3)*(1-c)-V(1)*s;
	V(1)*V(3)*(1-c)-V(2)*s V(2)*V(3)*(1-c)+V(1)*s V2(3)+(1-V2(3))*c];
% (Wikipedia: http://en.wikipedia.org/wiki/Rotation_matrix)
