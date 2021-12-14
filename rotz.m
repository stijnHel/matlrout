function R=rotz(a)
% ROTZ     - rotatiematrix voor verdraaiing langs Y-as

r=a*pi/180;
s=sin(r);
c=cos(r);
R=[c -s 0;s c 0;0 0 1];
