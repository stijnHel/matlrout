function B = FindSSblock(sys,typ,name,varargin)
%FindSSblock - Find Simscape block of a specific type
%   B = FindSSblock(sys,typ[,name])

if isempty(sys)
	sys = gcs;
end
if nargin<3 || isempty(name)
	extra = varargin;
elseif iscell(name)	% multiple named blocks
	B = cell(1,length(name));
	for i = 1:length(name)
		B{i} = FindSSblock(sys,typ,name{i},varargin{:});
	end
	B = [B{:}];
	return
else
	if startsWith(name,[sys,'/'])	% allow a blockname including the model name
					% is this the best solution?
		name(1:length(sys)+1) = [];
	end
	extra = [{'Name',name},varargin];
end
B = find_system(sys,'Type','block','BlockType','SimscapeBlock'	...
	,'MaskType',typ,extra{:});
