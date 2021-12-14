function R=rotyr(a)
% ROTYR    - rotatiematrix voor verdraaiing langs Y-as (hoek in radialen)

s=sin(a);
c=cos(a);
R=[c 0 s;0 1 0;-s 0 c];
