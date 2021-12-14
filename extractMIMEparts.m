function Aout=extractMIMEparts(fn,varargin)
%extractMIMEparts - Extracts separate parts from multipart MIME file
%   A=extractMIMEparts(fn,<options>)
%      options:
%          'outDir'
%          'fPre'
%          'bDecode'

outDir=[];
fPre='';
bDecode=false;
bWriteOut=nargout==0;
bUseFilename=false;
bReadPartHead=true;

if nargin>1
	setoptions({'outDir','fPre','bDecode','bWriteOut','bUseFilename','bReadPartHead'}	...
		,varargin{:})
end
if ~bReadPartHead&&bDecode
	error('Wrong combination of options')
end
[fPth,fName]=fileparts(fn);
if bWriteOut
	if ~ischar(outDir)
		outDir=fPth;
	end
end

fid=fopen(fn);
if fid<3
	error('Can''t open the file')
end
l1=fgetl(fid);
l2=fgetl(fid);
x=fread(fid,[1 Inf],'*char');
fclose(fid);

if ~strncmpi(l1,'MIME-Version:',13)
	error('Not starting with MIME-Version?')
end
i=findstr(l2,'boundary=');
if isempty(i)
	error('No boundary given (in second line)')
end
s=l2(i:end);
i=find(s=='"');
if length(i)~=2
	error('Wrong (simply searched) boundary definition')
end
sBoundary=s(i(1)+1:i(2)-1);

ii=findstr(x,sBoundary);
jj=ii;
for i=1:length(ii)
	j=ii(i)-1;
	while x(j)~=10&&x(j)~=13
		j=j-1;
	end
	while x(j)==10||x(j)==13
		j=j-1;
	end
	ii(i)=j;
	j=jj(i)+length(sBoundary);
	while x(j)~=10&&x(j)~=13
		j=j+1;
	end
	while j<=length(x)&&(x(j)==10||x(j)==13)
		j=j+1;
	end
	jj(i)=j;
end
ii(1)=[];
if jj(end)>=length(x)
	jj(end)=[];
else
	ii(end+1)=length(x);
end
A=cell(1,length(ii));
for i=1:length(ii)
	if bReadPartHead
		k=jj(i);
		Spart=struct('location',[],'encoding',[],'type',[],'others',{cell(1,0)});
		while x(k)~=10&&x(k)~=13
			j=k;
			while x(j)~=10&&x(j)~=13
				j=j+1;
			end
			l=x(k:j-1);
			if x(j)==13&&x(j+1)==10
				j=j+1;
			end
			k=j+1;
			m=find(l==':',1);
			if isempty(m)
				warning('EXTRACTMIME:nogoodHeadLine','Wrong header line?')
				break;
			end
			sData=l(1:m-1);
			m=m+1;
			while m<length(l)&&l(m)==' '
				m=m+1;
			end
			switch sData
				case 'Content-Location'
					Spart.location=l(m:end);
				case 'Content-Transfer-Encoding'
					Spart.encoding=l(m:end);
				case 'Content-Type'
					Spart.type=l(m:end);
				otherwise
					warning('EXTRACTMIME:unknownHeadLine','Unknown header line? (%s)',l)
					Spart.others{1,end+1}=l;
			end
		end
		A{2,i}=Spart;
	end
	s=x(k:ii(i));
	A{1,i}=s;
	if bWriteOut
		if bUseFilename
			error('Niet klaar (gebruik filename)')
		else
			f_i=sprintf('%s_part_%d',fName,i);
		end
		fid=fopen(fullfile(outDir,f_i),'w');
		if fid<3
			error('Can''t open file for writing ("%s")',f_i)
		end
		fwrite(fid,s);
		fclose(fid);
		if bDecode&&~isempty(Spart.encoding)&&strcmp(Spart.encoding,'base64')
			if ~isempty(Spart.location)
				k=find(Spart.location=='.',1,'last');
				if ~isempty(k)
					fExt=Spart.location(k:end);
				else
					fExt='.decode';
				end
			else
				fExt='.decode';
			end
			unix(sprintf('openssl base64 -d -in "%s" -out "%s"',fullfile(outDir,f_i),fullfile(outDir,[f_i fExt])));
		end
	end
end

if nargout
	Aout=A;
end
