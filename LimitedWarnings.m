function LimitedWarnings(label,varargin)
%LimitedWarnings - Give a limited number of warnings of a specific type
%     LimitedWarnings('label','message',<extra arguments>)
%           results in maximum 5 warnings

persistent LIMITED_WARNINGS N_MAX_WARNINGS


if isempty(LIMITED_WARNINGS) && ~isstruct(LIMITED_WARNINGS)
	N_MAX_WARNINGS = 5;
	LIMITED_WARNINGS = struct('label',label,'n',1);
end

B = strcmp({LIMITED_WARNINGS.label},label);
if any(B)
	n = LIMITED_WARNINGS(B).n+1;
	LIMITED_WARNINGS(B).n = n;
	if n<=N_MAX_WARNINGS
		warning(varargin{:})
	end
end