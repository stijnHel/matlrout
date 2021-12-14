function CopyFunctions(pth,files,tgt)
%CopyFunctions - Copy functions (m-files) to another directory
%   Main use (or targetted use): result from GetUsedFunc, copy files from
%   one directory to "helpfcns" directory..
%
%          CopyFunctions(pth,files,tgt)
%          CopyFunctions([pth,files],tgt)   one output of GetUsedFunc
%
%  add CopyFunctions({files},tgt) and use "which" to find location and extension
%
%  if no extension, '.m' is added(!)
%
%  see also GetUsedFun

if nargin==2
	tgt=files;
	files=pth.files;
	pth=pth.dir;
end

if ~exist(tgt,'dir')
	error('Sorry, target must be an existing directory!')
end

for i=1:length(files)
	file_i = files{i};
	if ~any(file_i=='.')
		file_i = [file_i '.m']; %#ok<AGROW>
	end
	copyfile(fullfile(pth,file_i),tgt)
end
