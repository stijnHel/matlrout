function R=rotxr(a)
% ROTXR    - rotatiematrix voor verdraaiing langs X-as (hoek in radialen)

s=sin(a);
c=cos(a);
R=[1 0 0;0 c -s;0 s c];
