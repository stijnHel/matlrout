function S=defSetFcn(S,varargin)
%defSetFcn - Help function for default setting
%        S=defSetFcn(S,...)

if nargin==1
	fprintf('Default settings:\n')
	disp(S)
elseif isscalar(varargin)&&all(varargin{1}(1)~='-?')
	if ~isfield(S,varargin{1})
		error('"%s" appears not to be a valid setting!',varargin{1})
	end
	fprintf('%s: ',varargin{1})
	disp(S.(varargin{1}))
else
	fn=fieldnames(S);
	S=setoptions(fn,S,varargin{:});
	for i=1:length(fn)
		v=S.(fn{i});
		if ischar(v)
			nv=str2num(v); %#ok<ST2NM>
			if isempty(nv)
				S.(fn{i})=v;
			else
				S.(fn{i})=nv;
			end
		end
	end
end
