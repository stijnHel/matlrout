function mVer = GetMatFileVersion(fName)
%GetMatFileVersion - Extract MAT-file version
%     mVer = GetMatFileVersion(fName)

fid = fopen(fName);
if fid<3
	if exist(fName,'file')
		error('Can''t open the file?!')
	else
		error('File doesn''t exist!')
	end
end

s = fread(fid,[1 14],'*char');
fclose(fid);

if strcmp(s,'MATLAB 5.0 MAT')
	mVer = 'ver 5 .. 7';
elseif strcmp(s,'MATLAB 7.3 MAT')
	mVer = 'ver 7.3';
elseif startsWith(s,'MATLAB')
	mVer = 'MAT ???';
else
	mVer = 'no MAT or MAT <5';
end
