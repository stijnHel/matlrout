function extractMatfromMsg(msgFile,tgtFile)
%extractMatfromMsg - Extract mat-file from message file (outlook mail message)
%     extractMatfromMsg(msgFile,tgtFile)
%
%    for tgtFile, give file without extension
%       if multiple files found, _<nr> is added to the filename
%
% created to extract data received via mail but blocked by outlook
%
%   This program is not made with a lot of knowledge of the msg-file
%   structure or the .mat-file structure.  It's made and tested with some
%   file, ..., without any guarantee.

fid=fopen(msgFile);
if fid<3
	error('Can''t open the file')
end

s=fread(fid,[1 Inf],'*uint8');
fclose(fid);

ii=findstr(s,'MATLAB');

if isempty(ii)
	error('I couldn''t find any mat-file')
end

if length(ii)>1
	warning('EMatFMsg:multiple','Multiple file found!')
end

ff=[1 cumprod(256+[0 0 0])]';
for i=1:length(ii)
	j=ii(i);
	c=s(j+128);
	if c<14||c>15
		warning('EMatFMsg:badVersion','Only works for MATLAB 5.0 files (-v5, -v7)')
	else
		l=double(s(j+132:j+135))*ff;
		if l+j+136>length(s)
			warning('EMatFMsg:wrongLength','Found length is too long - wrong assumptions made')
		else
			if length(ii)>1
				fName=[tgtFile '_' num2str(i)];
			else
				fName=tgtFile;
			end
			fid=fopen([fName '.mat'],'w');
			if fid<3
				error('Target file can''t be created.')
			end
			fwrite(fid,s(j:j+l+135));
			fclose(fid);
			fprintf('File "%s.mat" created.\n',fName)
		end
	end
end
