function b = isDirStruct(S)
%isDirStruct - determine if a struct is a result of dir (or derived)
%     b = isDirStruct(S)
%
%  All fields of dir must exist, extra fields are allowed

b = isstruct(S) && isfield(S,'name') && isfield(S,'folder')	...
	&& isfield(S,'date') && isfield(S,'bytes') && isfield(S,'isdir')	...
	&& isfield(S,'datenum');

if b && ~isempty(b)
	% some extra checks (not all...)
	b = ischar(S(1).name) && ischar(S(1).date) && isnumeric(S(1).datenum);
end
