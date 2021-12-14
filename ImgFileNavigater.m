function ImgFileNavigater(d,varargin)
%ImgFileNavigater - Navigation through images
%   Mainly using navimgs, but making it possible to navigate through files
%        ImgFileNavigator(d)

if nargin==0||isempty(d)
	d=direv('*.bin','sortd');
elseif ischar(d)
	f=getmakefig('ImgFileNavigator',false,false);
	if strcmpi(d,'save')
		if nargin>1
			fName=varargin{1};
		else
			dirList=getappdata(f,'dirList');
			fileNr=getappdata(f,'fileNr');
			[~,fN]=fileparts(dirList(fileNr).name);
			fName=fullfile(dirList(fileNr).folder,[fN,'.png']);
		end
		hImg=getappdata(f,'NAVIMGShImg');
		X=get(hImg,'CData');
		imwrite(X,fName)
		return
	elseif exist(d,'dir')
		zetev(d)
		d=direv('*.bin');
	else
		d=direv(d);
	end
elseif isnumeric(d)
	f=getmakefig('ImgFileNavigator',false,false);
	if isempty(f)
		error('Can''t find the figure')
	end
	ReadFile(f,d)
	return
end

fileNr=1;
[f,bN]=getmakefig('ImgFileNavigator');
if bN
	navimgs(randn(3,3,2))	% to make sure that navimgs is started
	navimgs('addkeyimg',30,@(~,~) KeyNav(f,1))	% up - previous file
	navimgs('addkeyimg',31,@(~,~) KeyNav(f,-1))	% 
	navimgs('addkeyimg',28,@(~,~) KeyNav(f,[0,-1]))
	navimgs('addkeyimg',29,@(~,~) KeyNav(f,[0,1]))
	navimgs('addkeyimg','?',@(~,~) FindNumImgs(f))
	navimgs('addkeyimg','r',@(~,~) ResetNumImgs(f))
	navimgs('addkeyimg',{'F1'},@(~,~) ImgInfo(f))
else
	ResetNumImgs(f)
end
if isempty(d)
	error('Sorry, but no files found!')
end
setappdata(f,'dirList',d)
ReadFile(f,fileNr)

function ReadFile(f,fileNr,bLast)
d=getappdata(f,'dirList');
bStatus=d(fileNr).bytes>3e7;
if bStatus
	status('Reading image file')
end
X=getappdata(f,'NAVIMGSdata');
H0=getappdata(f,'imgHeader');
typX=class(X);
sizX=length(X);
X=[];setappdata(f,'NAVIMGSdata',X)	% for memory saveing reasons
[X,H,T]=ReadImage(d(fileNr));
bNewType=false;
if sizX<10
	bNewType=true;
elseif H0.ver~=H.ver||H0.imgTypInt~=H.imgTypInt
	bNewType=true;
elseif ~strcmp(typX,class(X))	% only for old images
	bNewType=true;
end
if bNewType
	if strcmp(H.imgTypString,'RGB')
		if isa(X,'uint16')&&max(X(:))<4096
			setappdata(gcf,'imgPixScale',16);
		elseif isappdata(f,'imgPixScale')
			rmappdata(gcf,'imgPixScale');
		end
	elseif H.imgTypInt==0
		colormap(gray(256))
	elseif H.imgTypInt==1
		colormap(gray(4096))
	elseif H.imgTypInt==7
		colormap(gray(65536))
	else
		warning('Unknown image type?!')
	end
end
setappdata(f,'imgHeader',H)
setappdata(f,'imgTime',T)	% not (yet) used!
if bStatus
	status
end
if size(X,4)>1
	navimgs(X)
	if nargin>2&&bLast
		navimgs last
	end
else
    if isa(X,'uint16')&&size(X,3)>1
    	h=image(X*16);
    else
    	h=image(X);
    end
	setappdata(f,'NAVIMGSn',1);
	setappdata(f,'NAVIMGSidx',1);
	setappdata(f,'NAVIMGShImg',h)
	setappdata(f,'NAVIMGSdata',X)
	title 1/1
end
axis equal
axis off
setappdata(f,'fileNr',fileNr)
SetXLabel(f)

function KeyNav(f,dI)
fileNr=getappdata(f,'fileNr');
d=getappdata(f,'dirList');

if isscalar(dI)
	fileNr=fileNr+dI;
	if fileNr<1
		fileNr=length(d);
	elseif fileNr>length(d)
		fileNr=1;
	end
	ReadFile(f,fileNr)
else
	n=getappdata(f,'NAVIMGSn');
	idx=getappdata(f,'NAVIMGSidx');
	idx=idx+dI(2);
	if idx<1
		if fileNr>1
			ReadFile(f,fileNr-1,true)
		end
	elseif idx>n
		if fileNr<length(d)
			ReadFile(f,fileNr+1)
		end
	elseif dI(2)>0
		navimgs next
		SetXLabel(f)
	else
		navimgs previous
		SetXLabel(f)
	end
end

function SetXLabel(f)
d=getappdata(f,'dirList');
fileNr=getappdata(f,'fileNr');
s=sprintf('%d/%d',fileNr,length(d));
N=getappdata(f,'NumImgs');
if ~isempty(N)
	n=getappdata(f,'NAVIMGSn');
	if n==1
		i=sum(N(1:fileNr));
	else
		idx=getappdata(f,'NAVIMGSidx');
		i=sum(N(1:fileNr-1))+idx;
	end
	s=[s sprintf(' (%d/%d)',i,sum(N))];
end
xlabel([s ': ' d(fileNr).name]	...
	,'visible','on','interpreter','none')

function ResetNumImgs(f)
setappdata(f,'NumImgs',[])

function FindNumImgs(f)
N=getappdata(f,'NumImgs');
if isempty(N)
	d=getappdata(f,'dirList');
	N=zeros(1,length(d));
	SIZ=zeros(length(d),3);
	MX=zeros(1,length(d));
	TYP=cell(1,length(d));
	VER=zeros(1,length(d));
	TYPSTR=cell(1,length(d));
	TYPINT=zeros(1,length(d));
	Bok=true(1,length(d));
	status('Reading all file',0)
	for i=1:length(d)
		try
			[X,H]=ReadImage(d(i),1);
			N(i)=H.nImgs;
			siz=size(X);
			SIZ(i,1:length(siz))=siz;
			MX(i)=max(X(:));
			TYP{i}=class(X);
			VER(i)=H.ver;
			TYPSTR{i}=H.imgTypString;
			TYPINT(i)=H.imgTypInt;
		catch err
			fprintf('******error with file %d/%d: %s******\n',i,length(d),d(i).name)
			DispErr(err)
			Bok(i)=false;
		end
		status(i/length(d))
	end
	status
	if ~all(Bok)
		d=d(Bok);
		setappdata(f,'dirList',d);
		SIZ=SIZ(Bok,:);
		MX=MX(Bok);
		TYP=TYP(Bok);
		VER=VER(Bok);
		TYPSTR=TYPSTR(Bok);
		TYPINT=TYPINT(Bok);
	end
	setappdata(f,'NumImgs',N)
	IMGdata=var2struct(SIZ,MX,TYP,VER,TYPSTR,TYPINT);
	setappdata(f,'IMGdata',IMGdata)
	SetXLabel(f)
else
	warning('Image files are not read again (to save time!).')
end
fNimg=getmakefig('figNimages');
l=plot(N);grid
title 'Number of images in a file'
xlabel 'file number'
navfig
setappdata(fNimg,'mainImgFig',f)
set(l,'ButtonDownFcn',@NimgLineClicked)

function NimgLineClicked(l,ev)
ax=ancestor(l,'axes');
fN=ancestor(ax,'figure');
f=getappdata(fN,'mainImgFig');
nFiles=length(getappdata(f,'dirList'));
disp(ev)
pt=get(ax,'CurrentPoint');
fileNr=min(nFiles,max(1,round(pt(1))));
figure(f)
ReadFile(f,fileNr)

function ImgInfo(f)
fileNr=getappdata(f,'fileNr');
dirList=getappdata(f,'dirList');
NAVIMGSn=getappdata(f,'NAVIMGSn');
NAVIMGSidx=getappdata(f,'NAVIMGSidx');
h=getappdata(f,'NAVIMGShImg');
X=get(h,'Cdata');
fprintf('file %d/%d, image %d/%d - %s\n',fileNr,length(dirList)	...
	,NAVIMGSidx,NAVIMGSn,dirList(fileNr).name)
fprintf('      image of type %s, size: ',class(X))
disp(size(X))
fprintf('      range: %d - %d\n',min(X(:)),max(X(:)))
T=getappdata(1,'imgTime');
if length(T)>2
	dt=diff(T);
	fprintf('      avg frame rate: %.2f fps (mean dt: %.1f ms, median dt: %.1f ms, %.1f ms)\n'	...
		,1/mean(dt),[mean(dt),median(dt),std(dt)]*1000)
end
fprintf('      header info:\n')
disp(getappdata(f,'imgHeader'))
