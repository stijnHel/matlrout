function full=fFullPath(fName,bFreeExt,fExt,bRaiseError)
%fFullPath - Find full pathname of a file
%    full=fFullPath(fName[,bFreeExt[,fExt]])
%             bFreeExt: allow free extension
%             fExt : file-extension - added if none is given
%                    can be given without bFreeExt
%      special case:
%         full=fFullPath(<nr>,[],searchSpec)
%              search spec:
%                    file-extension
%                    cell-input as arguments to direv
%              returns a file (or directory) from direv
%
%  If the filename contains a path (relative or absolute), only that path
%     is checked.
%
% Looks in: (in this order)
%       current directory
%       zetev-directory
%       MATLAB-path (only for a given extension)

if nargin<4||isempty(bRaiseError)
	bRaiseError=true;
end

if isstruct(fName)
	if isscalar(fName)
		fName=GetFilenameFromDirStr(fName);
	else
		d=fName;
		full=cell(size(d));
		for i=1:numel(d)
			full{i}=GetFilenameFromDirStr(d(i));
		end
		return
	end
elseif isnumeric(fName)	% special case
	if nargin<3||isempty(fExt)
		sSpec={'*','file','sortd'};
	elseif iscell(fExt)
		sSpec=fExt;
	else
		if fExt(1)~='.'
			fExt=['.' fExt];
		end
		sSpec={['*' fExt],'sortd','file'};
	end
	full=zetev(sSpec,fName);
	return
elseif iscell(fName)
    if isscalar(fName)
        fName=fName{1};
    else
        error('Cell array only allowed for scalar input!')
    end
end

if any(fName=='*')
	d=[];
	if ~isempty(zetev)
		d=direv(fName);
	end
	if isempty(d)
		d=dir(fName);
	end
	if nargin>1&&~isempty(bFreeExt)&&~bFreeExt
		B = false(1,length(d));
		for i=1:length(d)
			[~,~,fExt]=fileparts(d(i).name);
			B(i) = strcmpi(fExt,fExt);
		end
		d=d(B);
	end
	if ~isscalar(d)
		if isempty(d)
			if bRaiseError
				error('No file found!')
			else
				full=[];
				return
			end
		elseif bRaiseError
			printstr({d.name})
			error('Multiple files are found!')
		else
			full = {d.name};
			for i=1:length(d)
				full{i} = fullfile(d(i).folder,full{i});
			end
			return
		end
	end
	fName=d.name;
end

if nargin<2
	bFreeExt=[];
elseif ischar(bFreeExt)
	fExt=bFreeExt;
	bFreeExt=[];
end
if nargin<3
	fExt=[];
end
if isempty(bFreeExt)
	bFreeExt=false;
end

[fPth,~,fExtI]=fileparts(fName);
if isempty(fExtI)&&~isempty(fExt)
	fName=[fName fExt];
end
if ~exist(fName,'file')&&bFreeExt	% (?)
	d=dir([fName '.*']);
	if ~isempty(d)
		full=fName;	% add extension
	elseif ~isempty(fPth)
		error('File not found (with a given path)')
	else
		fName1=zetev([],fName);
		if isempty(fExtI)
			d=dir([fName1 '.*']);
		else
			d=dir(fName1);
		end
		if ~isscalar(d)&&bRaiseError
			if isempty(d)
				error('Can''t find the file')
			else
				printstr(d)
				error('Multiple files found!')
			end
		elseif isempty(d)
			full = [];
		elseif isscalar(d)
			full = fullfile(d.folder,d.name);
		else
			full = {d.name};
			for i=1:length(d)
				full{i} = fullfile(d(i).folder,full{i});
			end
		end
	end
	return
end

if exist(fName,'file')
	full=fName;
elseif exist(zetev([],fName),'file')
	full=zetev([],fName);
elseif ~isempty(fPth)
	error('File not found (with a given path)')
else
	fName1=which(fName);
	if isempty(fName1)
		if bRaiseError
			error('Can''t find the file')
		else
			full=[];
			return
		end
	end
	full=fName1;
end

function fName=GetFilenameFromDirStr(d)
if isfield(d,'folder')
	fName=fullfile(d.folder,d.name);
else
	fName=d.name;
end
