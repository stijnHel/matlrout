function t=gettagdata(c,i,j)
% CSWF/GETTAGDATA - Geeft tag-data uit SWF-object
%   t=gettagdata(c,[i,j])
%   t=gettagdata(c,i,j)

if nargin==2
	j=i(2);
	i=i(1);
end
t=c.frames{i}(j).tagData;
