function fnOut=struct2var(S,varargin)
%struct2var - Set contents of structure fields to variables
%    [fn=]struct2var(S,...)

bConcat=false;
if ~isstruct(S)
	error('wrong input')
elseif numel(S)~=1
	bConcat=true;
	warning('multiple struct-records are concatenated!')
end
bExtrSimpar = false;
limitVarSet = {};

if ~isempty(varargin)
	setoptions({'bExtrSimpar','limitVarSet'},varargin{:})
end

fn=fieldnames(S);
for f=fn'
	f = f{1};
	if ~isempty(limitVarSet) && ~ismember(f,limitVarSet)
		error('Variable "%s" is not allowed to be set!',f)
	end
	if bConcat
		v=[S.(f)];
	else
		v=S.(f);
		if bExtrSimpar&&isa(v,'Simulink.Parameter')
			v=v.Value;
		end
	end
	assignin('caller',f,v)
end
if nargout
	fnOut=fn;
end
