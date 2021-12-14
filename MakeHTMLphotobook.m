function dOut=MakeHTMLphotobook(d,fOut,fTypes,imgOpts,varargin)
%MakeHTMLphotobook - Makes a photobook with filenames of images
%     MakeHTMLphotobook(d,fOut)
%     MakeHTMLphotobook(dirName,fOut)
%     MakeHTMLphotobook(...,true[,<img-opts>])	% select only image-files
%     MakeHTMLphotobook(...,{extension list}[,<img-opts>)	% only select these extensions

if ischar(d)
	dName=d;
	d=dirrecurs(dName);
	if nargin<3||isempty(fTypes)
		fTypes=true;
	end
	if dName(end)~=filesep
		dName(end+1)=filesep;
	end
	for i=1:length(d)
		d(i).name=[dName d(i).name];
	end
end
if exist('fTypes','var')&&~isempty(fTypes)
	if isnumeric(fTypes)||islogical(fTypes)
		if fTypes
			fTypes={'.gif','.png','.jpeg','.jpg','.bmp'};
		else
			fTypes=[];
		end
	end
else
	fTypes=[];
end
if ~isempty(fTypes)
	B=false(1,length(d));
	for i=1:length(d);
		[~,~,fext]=fileparts(d(i).name);
		B(i)=any(strcmpi(fext,fTypes));
	end
	d=d(B);
end
if ~exist('imgOpts','var')||~ischar(imgOpts)
	imgOpts='';
end
baseDir=[];
if ~isempty(varargin)
	setoptions({'baseDir'},varargin{:})
end

fid=fopen(fOut,'w');
if fid<3
	error('Can''t open the file')
end

fprintf(fid		...
	,'<html><head><title>photobook - %d images</title></head>\n<body>\n'	...
	,length(d));
for i=1:length(d)
	fprintf(fid,'%s<br>\n<img src="',d(i).name);
	if ischar(baseDir)
		fprintf(fid,'%s/',baseDir);
	end
	fprintf(fid,'%s"',d(i).name);
	if ~isempty(imgOpts)
		fprintf(fid,' %s',imgOpts);
	end
	fprintf(fid,'><br>\n');
end
fprintf(fid,'</body></html>');
fclose(fid);
if nargout>0
	dOut=d;
end
