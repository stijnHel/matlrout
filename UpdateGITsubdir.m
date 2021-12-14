function UpdateGITsubdir(pth)
%UpdateGITsubdir - Update GIT directories
%      UpdateGITsubdir()  - update the git-directories under current dir
%      UpdateGITsubdir(path) - update git-directories under path

if nargin==0 || isempty(pth)
	pth = pwd;
end

if isfolder(fullfile(pth,'.git'))
	fprintf('This is a git-directory! This is updated, not the directories under this one.\n')
	UpdateGIT(pth)
else
	d = dir(pth);
	for i=1:length(d)
		if d(i).isdir && ~strcmp(d(i).name,'.') && ~strcmp(d(i).name,'..')	...
				&& isfolder(fullfile(pth,d(i).name,'.git'))
			UpdateGIT(fullfile(pth,d(i).name))
		end
	end
end

function UpdateGIT(pth)
cPth = pwd;
cd(pth)
fprintf('Updating (pulling) "%s"\n',pth)
dos('git pull');
cd(cPth)
