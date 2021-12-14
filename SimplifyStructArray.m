function S=SimplifyStructArray(S,bCell,bRecursive)
%SimplifyStructArray - Simplify a struct array with one field
%     S=SimplifyStructArray(S[,bCell,bRecursive])

if nargin<2||isempty(bCell)
	bCell=true;
end
if nargin<3||isempty(bRecursive)
	bRecursive=false;
end
if bCell&&iscell(S)
	if isscalar(S)
		S=S{1};
		if bRecursive
			S=SimplifyStructArray(S,bCell,bRecursive);
		end
	elseif bRecursive
		for i=1:length(S)
			S{i}=SimplifyStructArray(S{i},bCell,bRecursive);
		end
	end
	return
end
if ~isstruct(S)
	return
end

fn=fieldnames(S);
if length(fn)~=1
	%warning('No simplification done!')
	if bRecursive
		for iS=1:numel(S)
			for i=1:length(fn)
				S(iS).(fn{i})=SimplifyStructArray(S(iS).(fn{i}),bCell,bRecursive);
			end
		end
	end
	return
end

try
	T=[S.(fn{1})];
	if bRecursive
		T=SimplifyStructArray(T,bCell,bRecursive);
	end
catch err
	DispErr(err)
	warning('Elements couldn''t be combined! - no simplification done')
	return
end
S=T;
