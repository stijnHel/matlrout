function splitfile(longFile,splitFile,NlinMax)
%splitfile - split text files in multiple fixed length files
%   splitfile(longFile,splitFile[,NlinMax])

if nargin<3
	NlinMax=10000;
end

fid=fopen(longFile,'rt');
if fid<3
	error('can''t open file')
end

nFiles=0;
nLines=0;
fid2=0;
while ~feof(fid)
	l=fgetl(fid);
	if ~ischar(l)
		break;
	end
	if nLines==0
		nFiles=nFiles+1;
		fid2=fopen(sprintf(splitFile,nFiles),'wt');
		if fid2<3
			error('Can''t open write file')
		end
	end
	fprintf(fid2,'%s\n',l);
	nLines=nLines+1;
	if nLines>NlinMax
		fclose(fid2);
		fid2=0;
		nLines=0;
	end
end
if fid2>0
	fclose(fid2);
end
fclose(fid);

