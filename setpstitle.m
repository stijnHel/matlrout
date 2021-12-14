function setpstitle(fname,titel,fnameChanged,varargin)
%SETPSTITLE - Zet de titel in een ps-document
%         setpstitle(fname,titel)
%  (!file wordt overschreven)
%         setpstitle(fname,titel,fnameChanged)
%         setpstitle(fname,titel,fnameChanged,'text1','text2',...)
%         setpstitle(fname,titel,fnameChanged,{'text1','text2',...})
%             text1, ... worden na titel en voor EndComments weggeschreven

if ~exist('fnameChanged','var')||isempty(fnameChanged)
	fnameChanged=fname;
end
if length(varargin)
	if length(varargin)==1
		opties=varargin{1};
	else
		opties=varargin;
	end
else
	opties='';
end
fid=fopen(fname);
if fid<3
	error('Kan file niet openen');
end

H=cell(1,20);
iH=0;
bLoop=true;
iEnd=0;
while bLoop
	l=fgetl(fid);
	if ~ischar(l)
		warning('!!!Title niet gevonden en onverwacht header-einde!!!!')
		break;
	end
	if strcmp(l(1:min(end,8)),'%%Title:')
		l=['%%Title: ' titel];
		bLoop=false;
		iEnd=1;
	elseif strcmp(deblank(l),'%%EndComments')
		warning('!!Title niet gevonden!!')
		iEnd=2;
		break;
	end
	iH=iH+1;
	H{iH}=l;
end
if ~isempty(opties)	%!!!!test
	if iEnd==1
		i=iH;
	else
		i=iH-1;
	end
	H={H{1:i} opties{:} H{i+1:iH}};
	iH=length(H);
end
x=fread(fid,'*uint8');
fclose(fid);
fid=fopen(fnameChanged,'wt');
if fid<3
	error('Kan file niet openen om te beschrijven')
end
fprintf(fid,'%s\n',H{1:iH});
fwrite(fid,x);
fclose(fid);
