function vset=getv(c,t,v,x)
% CRIJCYCLUS/GETV - Bepaalt targetsnelheid
%   target toerental wordt gegeven in m/s(!!!!)

vset=interp1(c.Vlijst(:,1),c.Vlijst(:,2),t);
