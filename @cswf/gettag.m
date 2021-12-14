function t=gettag(c,i,j)
% CSWF/GETTAG - Geeft tag uit SWF-object
%    t=gettag(c,[i j])
%    t=gettag(c,i,j)

global SWF_tags

if nargin==2
	j=i(2);
	i=i(1);
end
t=c.frames{i}(j);
if nargout==0
	fprintf('%3d : %-19s (len %d)\n',t.tagID,SWF_tags{t.tagID+1},t.tagLen);
end
