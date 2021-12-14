function S=var2struct(varargin)
%var2struct - Set contents of variables to a structure
%    S=var2struct({variable-name list})
%  or
%    S=var2struct(variable-name list)
%  or
%    S=var2struct(variable-value list)

if iscell(varargin{1})&&nargin==1
	bVarName=true;
	varlist=varargin{1};
else
	varlist=varargin;
	bVarName=all(cellfun(@ischar,varlist(:)));
end
if size(varlist,1)>1
	varlist=varlist(:)';
end
for i=1:length(varlist)
	if bVarName
		varlist{2,i}=evalin('caller',varlist{1,i});
	else
		varName=inputname(i);
		if isempty(varName)
			if ischar(varlist{1,i})
				varlist{2,i}=evalin('caller',varlist{1,i});
			else
				error('Expressions are not allowed! (#%d)',i)
			end
		else
			varlist{2,i}=varlist{1,i};
			varlist{1,i}=varName;
		end
	end
	if iscell(varlist{2,i})
		varlist{2,i}=varlist(2,i);	% make a 1x1 cell to make sure struct is a scalar struct
	end
end
S=struct(varlist{:});
