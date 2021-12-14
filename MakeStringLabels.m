function s = MakeStringLabels(s)
%MakeStringLabels - Make label-compatible strings (when TeX formatting is used)
%       s = MakeStringLabels(s)
%
% does this already exist?

if iscell(s)
	for i=1:length(s)
		s{i} = MakeStringLabels(s{i});
	end
	return
end

cEscape = '\_^&';	% '\' must be first!

for i = 1:length(cEscape)
	s = strrep(s,cEscape(i),['\',cEscape(i)]);
end
