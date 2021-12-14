function varargout=testfunio(varargin)
% simpele functie ivm testen van oproep van functie (voor callbackfcn)

global LASTFUNIO FUNIOPRINTcontents
LASTFUNIO=varargin;
if isempty(FUNIOPRINTcontents)
	FUNIOPRINTcontents=false;
end

fprintf('testfunio : %d in, %d out\n',nargin,nargout)
for i=1:nargin
	vi=varargin{i};
	cvi=class(vi);
	fprintf('    %d: %s',i,cvi)
	if FUNIOPRINTcontents
		sz=size(vi);
		if isnumeric(vi)||islogical(vi)
			if isscalar(vi)
				fprintf(': %g',vi)
			else
				fprintf('[%d',sz(1))
				fprintf('x%d',sz(2:end))
				fprintf(']')
			end
			fprintf('\n')
		else
			switch cvi
				case 'char'
					if ismatrix(vi)&&sz(1)==1&&sz(2)<50
						fprintf(': "%s"',vi)
					else
						fprintf('[%d',sz(1))
						fprintf('x%d',sz(2:end))
						fprintf(']')
					end
					fprintf('\n')
				case 'struct'
					fprintf(':\n')
					disp(vi)
				otherwise
					fprintf('\n')
			end		% switch cvi (= class(varargin{i}))
		end
	else	% if FUNIOPRINTcontents
		fprintf('\n')
	end		% if FUNIOPRINTcontents
end		% for i
if nargout
	varargout=cell(1,nargout);
end
