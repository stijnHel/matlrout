function [fListOut,fNew,fDeleted,sBranch,fAlreadyAdded,fAlreadyNew,fAlreadyDeleted] = CommitModifiedGITfiles(sComment,bPush,bPull,varargin)
%CommitModifiedGITfiles - Commit modified files on git
%     CommitModifiedGITfiles(sComment,bPush,bPull)
%     [fList,fNew,fDeleted,branch] = CommitModifiedGITfiles()	 - only gives the list of changed files
%             if bPush is given (and true) push is done after commit
%             if bPull is given (and true) repository is pulled before pushing

discardFiles = {};

options = varargin;
if nargin>1
	if ischar(bPush)
		if nargin>2
			options = [{bPush,bPull},options];
		else
			options = [{bPush},options];
		end
		bPush = [];
		bPull = [];
	else
		if nargin>2
			if ischar(bPull)
				options = [{bPull},options];
				bPull = [];
			end
		else
			bPull = [];
		end
	end
else
	bPush = [];
	bPull = [];
end
[filesToAdd] = {};
[fileExtension] = [];
if ~isempty(options)
	setoptions({'bPush','bPull','discardFiles','filesToAdd','fileExtension'},options{:})
end
if isempty(bPush)
	bPush = false;
end
if isempty(bPull)
	bPull = false;
end

[status,sGIT] = dos('git status');
if status
	warning('Status didn''t return zero?! (%d)',status)
end
[fList,fNew,fDeleted,sBranch,fAlreadyAdded,fAlreadyNew,fAlreadyDeleted] = GetFiles(sGIT,fileExtension);

if ~isempty(discardFiles)
	if ischar(discardFiles)
		discardFiles = {discardFiles};
	end
	B = false(size(fList));
	for i=1:length(discardFiles)
		B = B | contains(fList,discardFiles{i});
	end
	if any(B)
		fprintf('Discarded files: ')
		ii = find(B);
		if length(ii)>1
			fprintf('"%s", ',fList{ii(1:end-1)})
		end
		fprintf('"%s"\n',fList{ii(end)})
		fList(B) = [];
	end
end

if nargout
	fListOut = fList;
end
if nargout<3
	fprintf('Current branch: %s\n',sBranch)
end
if nargin && ~isempty(sComment) && any(sComment=='"') && ~contains(sComment,'\"')
	sComment = strrep(sComment,'"','\"');
end
if isempty(fList)&&isempty(filesToAdd)
	warning('Up to date - nothing done to the repository!')
elseif nargin&&~isempty(sComment)
	for i=1:length(fList)
		dos(['git add "',fList{i},'"']);
		fprintf('            %s added.\n',fList{i})
	end
	if ischar(filesToAdd) && ~isempty(filesToAdd)
		filesToAdd = {filesToAdd};
	end
	for i=1:length(filesToAdd)
		dos(['git add "',filesToAdd{i},'"']);
		fprintf('            %s added as new file.\n',filesToAdd{i})
	end
	dos(['git commit -m "',strtrim(sComment),'"']);
	if bPush
		if nargin>2&&bPull
			dos('git pull');
		end
		dos('git push');
	end
end

function [fList,fNew,fDeleted,sBranch,fAlreadyAdded,fAlreadyNew,fAlreadyDeleted] = GetFiles(sGIT,fileExtension)
ii = [0 find(sGIT==10) length(sGIT)+1];

fList = cell(1,length(ii)-3);
nFlist = 0;
fNew = cell(1,length(ii)-3);
nNew = 0;
fDeleted = {};
fAlreadyAdded = {};
fAlreadyNew = {};
fAlreadyDeleted = {};

typ = '';
nEmpty = 0;
for i=1:length(ii)-1
	l = sGIT(ii(i)+1:ii(i+1)-1);
	lTrimmed = strtrim(l);
	if isempty(lTrimmed)
		nEmpty = nEmpty+1;
		if ~isempty(typ)
			typ = '';
		end
	else
		nEmpty = 0;
	end
	if startsWith(l,'On branch')
		sBranch = l(11:end);
	elseif startsWith(lTrimmed,'Changes to be committed:')
		typ = 'staged';
	elseif startsWith(lTrimmed,'Changes not staged for commit:')
		typ = 'notstaged';
	elseif startsWith(lTrimmed,'Untracked files:')
		typ = 'untracked';
	elseif isempty(typ)
		% do nothing
	elseif strcmp(typ,'staged')
		if startsWith(lTrimmed,'modified:')
			fAlreadyAdded{1,end+1} = l; %#ok<AGROW> 
		elseif startsWith(lTrimmed,'new file:')
			fAlreadyNew{1,end+1} = strtrim(lTrimmed(11:end)); %#ok<AGROW> 
		elseif startsWith(lTrimmed,'deleted:')
			fAlreadyDeleted{1,end+1} = strtrim(lTrimmed(10:end)); %#ok<AGROW> 
		elseif lTrimmed(1)~='('
			warning('Unexpected line! ("%s")',l)
		end
	elseif strcmp(typ,'notstaged')
		if startsWith(lTrimmed,'modified:')
			l = strtrim(lTrimmed(11:end));
			nFlist = nFlist+1;
			fList{nFlist} = l;
		elseif startsWith(lTrimmed,'deleted:')
			fDeleted{1,end+1} = strtrim(lTrimmed(10:end)); %#ok<AGROW> 
		elseif lTrimmed(1)~='('
			warning('Unexpected line! ("%s")',l)
		end
	elseif strcmp(typ,'untracked')
		if lTrimmed(1)~='('
			nNew = nNew+1;
			fNew{nNew} = lTrimmed;
		end
	else
		warning('Not implemented? (%s)',typ)
	end
end		% for all lines
fList = fList(1:nFlist);
fNew = fNew(1:nNew);
if ~isempty(fileExtension)
	B = endsWith(fList,fileExtension);
	fList = fList(B);
	B = endsWith(fNew,fileExtension);
	fNew = fNew(B);
end
