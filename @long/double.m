%DOUBLE Converts a long object to double precision.
%
% D=DOUBLE(L) 
%
%
%   Ignacio del Valle Alles (ignacio_del_valle_alles@scientist.com)
%   $Revision: 1.0 $  $Date: 2003/03/26 10:29:20 $
%

function r=double(c)
r=c.decimales.*10.^(c.potencia);