function i=getkan(e,ne,e2,s)
% GETKAN   - Geeft kanaal-index (in e of e2)
%    i=getkan(ne,s)
%    i=getkan(e,ne,e2,s)
%       if is index voor e of e2 (!!er wordt niet
%              aangegeven bij welke matrix het kanaal hoort)
%!!moet uitgebreid worden - nu is dit case-insensitive
%   dit zou moeten worden zoals in plotmat/plotdat
%     case-insensitive - tenzij meerdere kanalen mogelijk

if nargin==2
	s=ne;
	ne=e;
	e=zeros(0,size(ne,1));
	e2=[];
end

i=fstrmat(lower(ne),lower(s),2);
if isempty(i)
	error('kan kanaal niet vinden')
elseif length(i)>1
	disp(ne(i,:))
	warning('!!!meerdere kanalen gevonden!!')
end
if i(end)>size(e,2)
	i=i-(size(e,2)-1)*(i>size(e,2));
end
