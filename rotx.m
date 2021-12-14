function R=rotx(a)
% ROTX     - rotatiematrix voor verdraaiing langs X-as

r=a*pi/180;
s=sin(r);
c=cos(r);
R=[1 0 0;0 c -s;0 s c];
