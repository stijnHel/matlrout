function [fIDout,fNames,fDirs] = GetOpenFiles()
%GetOpenFiles - Get open files - file index and paths
%    [fIDout,fNames,fDirs] = GetOpenFiles()

fID = fopen('all');

fNames = {};
fDirs = {};

if nargout
	fIDout = [];
end
if isempty(fID)
	if nargout
		fprintf('No open files\n')
	end
	return
end
fNames = cell(size(fID));
fDirs = fNames;
for i=1:length(fID)
	fNames{i} = fopen(fID);
	fDirs{i} = fileparts(fNames{i});
end
fDirs = unique(fDirs);
if nargout==0
	fprintf('%d files open in %d directories:\n',length(fID),length(fDirs))
	printstr('[%2d]',fID,'%s',fNames)
end
