function [options,removed] = RemoveOptions(options,delList)
%RemoveOptions - Remove options from a list of options
%
%          options = RemoveOptions(options,delList)
%
% see also: setoptions

if isempty(options) || isempty(delList)
	removed = {};
	return
elseif ischar(options)
	options = {options};
elseif iscell(options)&&iscell(options{1})
	if ~isscalar(options)
		error('Wrong options?!')
	end
	options = options{1};
end

if ischar(delList)
	delList = {delList};
end

removed = {};
options = setoptions({},options,'-bCleanedList');
i = 1;
while i<length(options)
	bKeep = true;
	B = strncmpi(options{i},delList,length(options{i}));
	if any(B)
		if sum(B)>1
			if sum(strcmpi(options{i},delList))==1	...
					|| sum(strncmp(options{i},delList,length(options{i})))==1
				bKeep = false;
			end
		else
			bKeep = false;
		end
	end
	
	if bKeep
		i=i+2;
	else
		removed(1,end+1:end+2) = options(i:i+1);
		options(i:i+1) = [];
	end
end
