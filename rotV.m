function R=rotV(V,a)
% ROTV     - rotatiematrix voor verdraaiing langs as
%     R=rotV(V,a)
%         a in graden

V=V/sqrt(sum(V.^2));
if length(V)<3
	V(3)=0;
end
V2=V.^2;
s=sind(a);
c=cosd(a);
R=[ V2(1)+(1-V2(1))*c      V(1)*V(2)*(1-c)-V(3)*s V(1)*V(3)*(1-c)+V(2)*s;
	V(1)*V(2)*(1-c)+V(3)*s V2(2)+(1-V2(2))*c      V(2)*V(3)*(1-c)-V(1)*s;
	V(1)*V(3)*(1-c)-V(2)*s V(2)*V(3)*(1-c)+V(1)*s V2(3)+(1-V2(3))*c];
% (Wikipedia: http://en.wikipedia.org/wiki/Rotation_matrix)
