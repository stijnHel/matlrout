function [pth,bFound] = FindFolder(subdir,pth0,bError,varargin)
%FindPath - Find a folder in higher level directories
%     pth = FindFolder(subdir[,pth0[,bError]])
%        subdir: a local folder name (or file)
%        pth0  : starting path - default: current path
%                if 0 (numeric) ==> start from this file's folder
%        bError: if true (default) then an error is raised if folder is not
%              found.

if nargin<2 || isempty(pth0)
	pth0 = pwd;
elseif isnumeric(pth0)
	pth0 = fileparts(which(mfilename));
end
options = varargin;
if nargin<3
	bError = [];
elseif ischar(bError)
	options = [{bError},options];
	bError = [];
end
[bAppendFolder] = false;
if ~isempty(options)
	setoptions({'bError','bAppendFolder'},options{:})
end

bFound = false;
pth = pth0;
while pth(end)~=filesep
	if exist(fullfile(pth,subdir),'file')	% (file or dir (!))
		%addpath(fullfile(pth,subdir))
		bFound = true;
		break
	end
	pth = fileparts(pth);
end
if bFound
	if bAppendFolder
		pth = fullfile(pth,subdir);
	end
else
	if isempty(bError)
		bError = true;
	end
	if bError
		error('Sorry, I can''t find folder "%s"!',subdir)
	end
end
