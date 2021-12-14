function [ID,sl]=listtags(c)
% CSWF/LISTTAGS - Geeft een lijst van de gebruikte tags
%  [ID,sl]=listtags(c)
%     ID : ID's (met bijhorend aantal keren voorgekomen)
%     sl : stringlijst van ID's

global SWF_tags

ID=zeros(0,2);
for i=1:length(c.frames)
	f=c.frames{i};
	ID1=cat(1,f.tagID);
	ID2=unique(ID1);
	if isempty(ID)
		ID3=ID2;
	else
		ID3=setdiff(ID2,ID(:,1));
		ID4=intersect(ID(:,1),ID2);
		for j=1:length(ID4)
			k=find(ID(:,1)==ID4(j));
			ID(k,2)=ID(k,2)+sum(ID1==ID4(j));
		end
		ID1(ismember(ID1,ID4))=[];
	end
	n=hist(ID1,[-1;ID3])';
	ID=[ID;ID3 n(2:end)];
end
if nargout==0
	for i=1:size(ID,1)
		fprintf('%3d %-19s : %d\n',ID(i,1),SWF_tags{ID(i,1)+1},ID(i,2));
	end
elseif nargout>1
	sl=SWF_tags(ID(:,1)+1);
end
