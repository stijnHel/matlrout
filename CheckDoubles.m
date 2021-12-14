function CheckDoubles(baseDir)
%CheckDoubles - Check double (m-)files in the matlab path
%     CheckDoubles(baseDir) (default current directory)

if nargin==0
	baseDir=pwd;
end

d=dir(fullfile(baseDir,'*.m'));
for i=1:length(d)
	w=which('-all',d(i).name);
	if length(w)>1
		fprintf('%s:\n',d(i).name);
		fprintf('      %s\n',w{:});
		fprintf('\n');
	end
end
