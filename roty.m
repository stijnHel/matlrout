function R=roty(a)
% ROTY     - rotatiematrix voor verdraaiing langs Y-as

r=a*pi/180;
s=sin(r);
c=cos(r);
R=[c 0 s;0 1 0;-s 0 c];
