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

if ~isempty(varargin)
	setoptions({'bExtrSimpar'},varargin{:})
end

fn=fieldnames(S);
for f=fn'
	if bConcat
		v=[S.(f{1})];
	else
		v=S.(f{1});
		if bExtrSimpar&&isa(v,'Simulink.Parameter')
			v=v.Value;
		end
	end
	assignin('caller',f{1},v)
end
if nargout
	fnOut=fn;
end
