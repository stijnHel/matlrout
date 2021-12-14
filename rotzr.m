function R=rotzr(a)
% ROTZR    - rotatiematrix voor verdraaiing langs Y-as (hoek in radialen)

s=sin(a);
c=cos(a);
R=[c -s 0;s c 0;0 0 1];
