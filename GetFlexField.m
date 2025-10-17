function [v,field] = GetFlexField(S,field)
%GetFlexField - Get field from a structure, with "name flexibility"
%        the fieldname doesn't need to be fully correct
%    v = GetFlexField(S,field)
%          same as getfield (or S.(field)) if it exist
%          otherwise a name with different (upper/lower) case or abreviated is allowed
%    [v,field] = GetFlexField(S,field) - to get the exact field
%
% only works for scalar structs (on purpose, not requiing

if ~isfield(S,field)
	fn = fieldnames(S);
	j = find(startsWith(fn,field,"IgnoreCase",true));
	if length(j)>1
		j = find(strcmpi(field,fn));
		if length(j)~=1
			j = find(startsWith(field,fn));
		end
		if isempty(j)
			error('Field not found')
		elseif length(j)>1
			fprintf('        %s\n',fn{j})
			error('Multiple possibilities for field "%s",field')
		end
	end
	field = fn{j};
end
v = S.(field);
