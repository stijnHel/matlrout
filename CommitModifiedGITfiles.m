function [fListOut,fNew,sBranch] = CommitModifiedGITfiles(sComment,bPush,bPull,varargin)
%CommitModifiedGITfiles - Commit modified files on git
%     CommitModifiedGITfiles(sComment,bPush,bPull)
%     [fList,fNew,branch] = CommitModifiedGITfiles()	 - only gives the list of changed files
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
if ~isempty(options)
	setoptions({'bPush','bPull','discardFiles','filesToAdd'},options{:})
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
[fList,fNew,sBranch] = GetFiles(sGIT);

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

function [fList,fNew,sBranch] = GetFiles(sGIT)
ii = [0 find(sGIT==10) length(sGIT)+1];

fList = cell(1,length(ii)-3);
nFlist = 0;
fNew = cell(1,length(ii)-3);
nNew = 0;

typ = '';
nEmpty = 0;
for i=1:length(ii)-1
	l = sGIT(ii(i)+1:ii(i+1)-1);
	lTrimmed = strtrim(l);
	if startsWith(l,'On branch')
		sBranch = l(11:end);
	elseif isempty(typ)
		if startsWith(lTrimmed,'modified:')
			typ = 'modified';
			l = strtrim(lTrimmed(11:end));
			if ~isempty(l)
				nFlist = nFlist+1;
				fList{nFlist} = l;
			end
		elseif startsWith(lTrimmed,'Untracked files:')
			nEmpty = 0;
			typ = 'untracked';
		end
	elseif isempty(l)
		if strcmp(typ,'untracked')
			nEmpty = nEmpty+1;
			if nEmpty>1
				typ = '';
			end
		else
			typ = '';
		end
	elseif strcmp(typ,'modified')
		if startsWith(lTrimmed,'modified:')
			l = strtrim(lTrimmed(11:end));
			nFlist = nFlist+1;
			fList{nFlist} = l;
		else
			warning('Unexpected line! ("%s")',l)
		end
	elseif strcmp(typ,'untracked')
		nNew = nNew+1;
		fNew{nNew} = strtrim(l);
	else
		warning('Not implemented? (%s)',typ)
	end
end		% for all lines
fList = fList(1:nFlist);
fNew = fNew(1:nNew);
