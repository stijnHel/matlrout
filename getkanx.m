function [y,x]=getkanx(e,ne,e2,s)
% GETKANX  - Geeft kanaal (uit e of e2)
%    [y[,x]]=getkan(e,ne[,e2],s)

if nargin==3
	s=e2;
	e2=[];
end

i=fstrmat(lower(ne),lower(s),2);
if isempty(i)
	error('kan kanaal niet vinden')
elseif length(i)>1
	j=fstrmat(lower(ne),lower(s),2);
	if ~isempty(j)
		i=j;
	end
	j=fstrmat(lower(ne(i,:)),lower(s));
	if ~isempty(j)
		i=i(j);
	end
	if length(i)>1
		disp(ne(i,:))
		error('!!!meerdere kanalen gevonden!!')
	end
end
if i>size(e,2)
	y=e2(:,i-size(e,2)+1);
	if nargin>1
		x=e2(:,1);
	end
else
	y=e(:,i);
	if nargin>1
		x=e(:,1);
	end
end
