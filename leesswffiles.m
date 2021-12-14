SWFdir='C:\test\swfs';
d=dir([SWFdir filesep '*.swf']);
%for i=1:1
status('lezen van swf-files',0)
for i=1:length(d)
	u=[];
	fprintf('%2d : %s : ',i,d(i).name);
	try
		u=leesswf([SWFdir filesep d(i).name]);
		fprintf('OK (%d,%d)\n',length(u.frames),length(u.frames{1}));
	catch
		fprintf('%s\n',lasterr);
	end
	status(i/length(d))
end
status
