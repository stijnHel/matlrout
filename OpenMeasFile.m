function fid=OpenMeasFile(fName,varargin)
%OpenMeasFile - Open a measurement file
%  After writing the code many times, finally in a separate function...
%   fid=OpenMeasFile(fName[,...])
%     it's allowed to give a dir-struct (result of dir-function) as an
%     input.  (Only one element is allowed.)
%          additional inputs are "sent" to fopen as additional arguments.
%
% Tries first to open it directly, than via zetev

% ?also try to open from the MATLAB path?

if isstruct(fName)
	if ~isfield(fName,'name')||~isscalar(fName)
		error('Wrong struct-input - a dir-struct is expected')
	end
	fName=fName.name;
end
fid=fopen(fName,varargin{:});
if fid<3
	fName=zetev([],fName);
	fid=fopen(fName,varargin{:});
	if fid<3
		error('Can''t open the file')
	end
end
