function [s,sn]=gettaglist(c)
% CSWF/GETTAGLIST - Geeft lijst van aanwezige tags
%    [s,sn]=gettaglist(c)

global SWF_tags

l=[];
for i=1:length(c.frames)
	l=union(l,cat(2,c.frames{i}.tagID));
end
if nargout
	s=l;
	if nargout>1
		sn=SWF_tags(l+1);
	end
elseif isempty(l)
	fprintf('Geen tags aanwezig (!!!!)\n');
else
%	a=cell(2,length(l));
%	a{1,:}=deal(num2cell(l));
	cl=num2cell(l);
	sl=SWF_tags(l+1);
	clsl={cl{:};sl{:}};
	fprintf('%3d : %s\n',clsl{:})
end
