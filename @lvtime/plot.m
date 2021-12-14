function varargout=plot(varargin)
%lvtime/plot - plot function handling lvtime-vectors
%   any input (X,Y,X) is converted to double
%   further is any functionallity of plot possible

in=varargin;
for i=1:min(3,nargin)
	if isa(in{i},'lvtime')
		in{i}=double(in{i});
	end
end
varargout=cell(1,nargout);
[varargout{:}]=plot(in{:});
