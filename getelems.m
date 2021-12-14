function [e1,E,I,K]=getelems(e,p)
% GETELEMS - Neemt de elementen uit een matrix, 1 element per rij.
%    [e1,E,I,K]=getelems(e,p)
%         e : de matrix met elementen
%         p : voorwaarde om te selecteren (normaal 0 of 1)
%             indien 1 getal worden uit e waarden genomen die groter zijn dan p
%             indien niet gegeven worden uit e elementen verschillend van 0 genomen
%
%         e1 : de vector van geselecteerde elementen
%         E  : de matrix zonder de geselecteerde elementen
%                        ("rechtse" elementen naar links geschoven)
%         I  : de lijst van indices van geselecteerde elementen
%         K  : een lijst van elementen met "problemen"
%               positieve waarden : rij-nummers van rijen met meerdere elementen
%               negatieve waarden : neg. rij-nummers van rijen zonder element

if ~exist('p')|isempty(p)
	p=e~=0;
elseif length(p)==1
	p=e>p;
end

N=size(e,1);
i=zeros(N,1);
k0=[];
for j=1:N
	k=find(p(j,:));
	if length(k)<1
		k0(end+1)=-j;
	elseif length(k)==1;
		i(j)=k;
	else
		k0(end+1)=j;
		i(j)=k(1);
	end
end
e1=zeros(N,1);
for j=1:N
	if i(j)
		e1(j)=e(j,i(j));
	end
end
if nargout<4
	if ~isempty(k0)
		sZijn={'was','waren'};
		sRij={'rij','rijen'};
		if any(k0<0)
			n=sum(k0<0);
			fprintf('Er %s %d %s zonder geselecteerd element.\n',sZijn{(n>1)+1},n,sRij{(n>1)+1})
		end
		if any(k0>0)
			n=sum(k0>0);
			fprintf('Er %s %d %s met meerdere selecterbare elementen.\n',sZijn{(n>1)+1},n,sRij{(n>1)+1})
		end
	end
else
	K=k0;
end
if nargout>1
	for j=1:length(e)
		if i(j)
			e(j,i(j):end-1)=e(j,i(j)+1:end);
		end
	end
	e(:,end)=[];
	E=e;
	if nargout>2
		I=i;
	end
end
