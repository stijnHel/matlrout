function u=zoektags(c,tag)
% CSWF/ZOEKTAGS - Zoek tag in SWF-object

global SHAPETYPE SWF_versie SWF_x_last
global SWF_tags

if ischar(tag)
	i_tag=strmatch(tag,SWF_tags,'exact');
	if isempty(i_tag)
		error('tag niet gevonden');
	end
	i_tag=i_tag-1;
else
	i_tag=tag;
end
tags=cell(0,2);	% hiermee wordt niets gedaan
U=zeros(0,2);
for i=1:length(c.frames)
	IDs=cat(2,c.frames{i}.tagID);
	j=find(IDs==i_tag);
	if ~isempty(j)
		U(end+1:end+length(j),:)=[i(ones(length(j),1),1) j(:)];
		tags{end+1,1}=i;
		tags{end,2}=j;
		if nargout==0
			fprintf('frame %d: tagsNr',i);
			if length(j)>1
				fprintf('s');
			else
				fprintf(' ');
			end
			fprintf(' %d',j);
			fprintf('\n');
		end
	end
end
if nargout
	u=U;
end
