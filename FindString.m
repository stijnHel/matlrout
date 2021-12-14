function [i,sFound]=FindString(List,s)
%FindString - Find best matching string in list
%    Case insensitive, except when needed.
%    Only start of string is enough, except when needed.
%
%      [i,sFound]=FindString(List,s)

i=find(strncmpi(s,List,length(s)));
if length(i)>1
	j=i(strcmpi(s,List(i)));
	if ~isempty(j)
		i=j;
	end
	if length(i)>1
		j=i(strncmp(s,List(i),length(s)));
		if ~isempty(j)
			i=j;
		end
	end
end
if nargout>1
	if isempty(i)
		sFound=[];
	elseif isscalar(i)
		sFound=List{i};
	else
		sFound=List(i);
	end
end
