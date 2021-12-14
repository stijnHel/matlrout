function R=rotxyz_r(a)
% ROTXYZ_R - rotatiematrix voor verdraaiing langs X-, dan Y-, dan Z-as
%    R = rotxyz_r([rx,ry,rz])
%         rx, ry, rz angles in radians

R=rotzr(a(3))*rotyr(a(2))*rotxr(a(1));
