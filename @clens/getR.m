function R=getR(c)
%clens/getR - Gives the total radius of the lens
%    R=getR(c)
%
% !!! only for spherical lenses !!!

if ~strcmp(c.type,'sferisch')
	error('This is not defined for non-spherical lenses')
end
R=c.S(1).D.yzRmax;
