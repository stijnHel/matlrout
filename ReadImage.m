function [X,H,T]=ReadImage(fName,idx,bNoWarning)
%ReadImage - Read Image (from CameraTest)
%    [X,H,T]=ReadImage(fName,idx)
%
% see also ImgFileNavigater (reading the full file(!))

%!!!!!!!if idx given, reading goes wrong
%              ---> changes in "all" should be copied to range!!!!

if nargin<2
	idx=[];
elseif ~isempty(idx)&&any(idx<1)
	error('Sorry - but minimum idx must be 1!')
end
if nargin<3||isempty(bNoWarning)
	bNoWarning=false;
end

cFile=file(fFullPath(fName,false,'.bin'),'r','ieee-be');

% read header
n=cFile.fread(1,'uint32');
if n>32
	error('Wrong start of image file - not a "LV-ImageFileDump"? (%s)',cFile.fName)
end
typ=cFile.fread([1 n],'*char');
if ~strcmp(typ,'imgStream')
	error('Sorry, but this function only allows files of type "imgStream"! (%s)',typ)
end
ver=cFile.fread(1,'uint32')/100;
if ver>3
	warning('Only version 3.00 is known! (version %.2f)',ver)
end
imgTypInt=cFile.fread(1,'uint32');
n=cFile.fread(1,'uint32');
if n>16
	error('Bad image type?!')
end
imgTypString=cFile.fread([1 n],'*char');
if ver>=3
	bSaveCustom = logical(cFile.fread(1,'*uint8'));
end
%fprintf('   filetype: %2d, %s\n',imgTypInt,imgTypString)
fP0=cFile.ftell();
b_8bitData=false;
b_16bitData=false;
switch imgTypInt
	case 0	% Grayscale (U8)
		if strcmp('MONO',imgTypString)
			filePixTyp='uint8';
			b_8bitData=true;
		else
			filePixTyp='uint32';	% old version...
		end
		btPerP=1;
	case 1	% Grayscale (I16)
		filePixTyp='int16';
		b_16bitData=true;
		btPerP=2;
	case 2	% Grayscale (SGL)
		filePixTyp='single';
		btPerP=4;
	case 3	% Grayscale (CSG)
		filePixTyp='uint64';	%!!!!
		btPerP=8;
	case 4	% RGB (U32)
		filePixTyp='uint32';
		btPerP=4;
	case 5	% Grayscale (U32)
		filePixTyp='uint32';
		btPerP=4;
	case 6	% RGB (U64)
		filePixTyp='uint64';
		b_16bitData=true;
		btPerP=8;
	case 7	% Grayscale (U16)
		filePixTyp='uint16';
		b_16bitData=true;
		btPerP=2;
	otherwise
		filePixTyp='uint8';
		warning('Unknown(/wrong?) image type?!')
end

t=lvtime([],cFile);
if ver>1&&ver<=2
	n=cFile.fread(1,'uint8');
	xt=cFile.fread([1 n],'*uint16');	% not used
	if any(imgTypInt==[1,4,7])
		xt(end+1)=cFile.fread(1,'*uint16');
	end
elseif ver>2
	if ~strcmp(imgTypString,'RGB')
		warning('This function is only tested for RGB-data on version>2 data!')
	end
	if double(t)>737835&&double(t)<737835.6658	% (!!) wrongly saved image format
		imgTypInt = 0;
		filePixTyp = 'uint8';
		b_8bitData = true;
		imgTypString = 'MONO';
	end
	n=cFile.fread(1,'uint8');
	xt=cFile.fread([1 n],'*uint16');	% not used
	if any(imgTypInt==[1,4,7])
		xt(end+1)=cFile.fread(1,'*uint16');
	end
end
sizImage=cFile.fread([1,2],'uint32');
if strcmp(imgTypString,'MONO')
	X=cFile.fread(prod(sizImage),['*' filePixTyp]);
	dummy=cFile.fread(1,'uint32');	% why? It just is...
	if dummy>0
		warning('Fill-data not zero?')
	end
elseif ver>1
	X=cFile.fread(prod(sizImage),['*' filePixTyp]);
	dummy=cFile.fread(1,'uint32');	% why? It just is...
elseif all(sizImage>0)	% normal 8-bit RGB-data
	X=cFile.fread(prod(sizImage),'*uint32');
	b_16bitData=false;
	btPerP=4;
	%sizBlock=16+8+prod(sizImage)*4;	% time, size (2xuint32), sizImage uint32
else	% 
	b_16bitData=true;
	sizImage=cFile.fread([1,2],'uint32');
	X=cFile.fread(prod(sizImage),'*uint64');
	btPerP=4;%!!!
	%sizBlock=16+8+8+prod(sizImage)*2*4;	% (twice a size)
end
H=var2struct(ver,imgTypInt,imgTypString);
if ver==2
	[C,Cidx]=ReadCustom(cFile);
	H.C=C;
elseif ver>2&&bSaveCustom
	[C,Cidx]=ReadCustom(cFile);
	H.C=C;
end
fP1=cFile.ftell();
sizBlock=fP1-fP0;


%%%%!!!!!!!! this should be rewritten - with structure this time....!!!

if isempty(idx)	% read all
	if strcmp(imgTypString,'MONO')
		Xraw=cFile.fread([sizBlock,Inf],'*uint8');
		bMore=size(Xraw,1)==sizBlock;
		if bMore
			Xtime=Xraw(1:16,:);
		end
	elseif ver<=1
		Xraw=cFile.fread([sizBlock/btPerP,Inf],['*' filePixTyp]);
		bMore=size(Xraw,1)==sizBlock/btPerP;
		if bMore
			Xtime=Xraw(1:16/btPerP,:);
		end
	else
		Xraw=cFile.fread([sizBlock,Inf],'*uint8');
		bMore=size(Xraw,1)==sizBlock;
		if bMore
			Xtime=Xraw(1:16,:);
		end
	end
	nImgs=size(Xraw,2);
	if bMore
		T=[t lvtime(Xtime)];
		if b_8bitData
			if ver<2
				Xother=Xraw(end-3-prod(sizImage):end-4,:);
				Xall=[X,Xother];
			elseif bSaveCustom
				[H,iX1,iX2]=ReadCustomData(H,Xraw,sizImage,btPerP,Cidx);
				Xother=typecast(reshape(Xraw(iX1:iX2,:),[],1),class(X));
				Xother=reshape(Xother,[],nImgs);
				Xother=swapbytes(Xother);
				Xall=[X,Xother];
			else
				iX2=size(Xraw,1)-4;
				iX1=iX2+1-length(X);
				Xall=[X,Xraw(iX1:iX2,:)];
			end
		elseif strcmp(imgTypString,'MONO')||ver>1
			if ver<2
				iX1=size(Xraw,1)-3-prod(sizImage)*btPerP;
				iX2=size(Xraw,1)-4;
			elseif ver==2||bSaveCustom
				[H,iX1,iX2]=ReadCustomData(H,Xraw,sizImage,btPerP,Cidx);
			else
				H.C = struct();
				Cidx = [];
				[H,iX1,iX2]=ReadCustomData(H,Xraw,sizImage,btPerP,Cidx);
			end
			Xother=typecast(reshape(Xraw(iX1:iX2,:),[],1),class(X));
			Xother=reshape(Xother,[],nImgs);
			Xother=swapbytes(Xother);
			Xall=[X,Xother];
		elseif b_16bitData
			Xother=Xraw(9:end,:);
			Xall=[X,reshape(typecast(Xother(:),'uint64'),[sizImage(2)*sizImage(1),nImgs])];
		else
			Xall=[X,reshape(Xraw(7:end,:),[sizImage(2)*sizImage(1),nImgs])];
		end
		X=Xall;
	else
		T=t;
	end
	H.nImgs=size(X,2);
elseif all(idx==1)
	T=t;
	cFile.fseek(0,'eof');
	fLen=cFile.ftell();
	nImgs=(fLen-fP0)/sizBlock;
	if nImgs>floor(nImgs)
		warning('Not a complete set of images? or varying image size?!')
		nImgs=floor(nImgs);
	end
	H.nImgs=nImgs;
else
	cFile.fseek(0,'eof');
	fLen=cFile.ftell();
	nImgs=(fLen-fP0)/sizBlock;
	if nImgs>floor(nImgs)
		warning('Not a complete set of images? or varying image size?!')
		nImgs=floor(nImgs);
	end
	H.nImgs=nImgs;
	if any(idx>nImgs)
		if all(idx>nImgs)
			error('Sorry, but all requested images were beyond the last image!')
		end
		if ~bNoWarning
			warning('Image beyond the last image was requested!')
		end
		idx=idx(idx<=nImgs);
	end
	
	if b_16bitData
		Xall=zeros(sizImage(2)*sizImage(1),length(idx),'uint64');
	else
		Xall=zeros(sizImage(2)*sizImage(1),length(idx),'uint32');
	end
	if any(idx==1)
		Xall(:,idx==1)=X;
	end
	T=t(1,ones(1,length(idx)));
	for i=1:length(idx)
		if idx(i)~=1
			cFile.fseek(fP0+(idx(i)-1)*sizBlock,'bof');
			T(i)=lvtime([],cFile);
			if b_16bitData
				n1=cFile.fread([1,4],'uint32');	% should always be the same!!!
				if any(sizImage~=n1(3:4))
					error('Sorry, images sizes vary?!!!')
				end
				Xall(:,i)=cFile.fread(prod(sizImage),'*uint64');
			else
				szImg1=cFile.fread([1,2],'uint32');	% should always be the same!!!
				if any(sizImage~=szImg1)
					error('Sorry, images sizes vary?!!!')
				end
				Xall(:,i)=cFile.fread(prod(sizImage),'*uint32');
			end
		end
	end
	X=Xall;
end
cFile.fclose();

if strcmp(imgTypString,'MONO')
	X=permute(reshape(X,sizImage(2),sizImage(1),1,size(X,2)),[2 1 3 4]);
elseif strcmp(imgTypString,'RGB')
	if b_16bitData
		X=reshape(typecast(X(:),'uint16'),4,sizImage(2),sizImage(1),size(X,2));
		X=X([2,3,4],:,:,:);
	else
		X=reshape(typecast(X(:),'uint8'),4,sizImage(2),sizImage(1),size(X,2));
		X=X([3,2,1],:,:,:);
	end
	X=permute(X,[3 2 1 4]);
end
if isfield(H,'C')&&~isempty(H.C)&&~isempty(fieldnames(H.C))
	if isfield(H.C,'IMAQdxReceiveTimestampHigh')&&isfield(H.C,'IMAQdxReceiveTimestampLow')
		TS_H=cat(1,H.C.IMAQdxReceiveTimestampHigh);
		TS_L=cat(1,H.C.IMAQdxReceiveTimestampLow);
		TS=[TS_L(:,[4 3 2 1])';TS_H(:,[4 3 2 1])'];
		H.TS=double(typecast(TS(:),'uint64'))*1e-7;
	end
end

function [C,Cidx]=ReadCustom(cFile)
nCustom=cFile.fread(1,'uint32');
C=cell(2,nCustom);
Cidx=zeros(nCustom,2);
idx=1;
for i=1:nCustom
	nT=cFile.fread(1,'uint32');
	nCi=cFile.fread([1 nT],'uint8=>char');
	idx=idx+4+nT;
	nV=cFile.fread(1,'uint32');
	idx=idx+4;
	nVi=cFile.fread([1 nV],'*uint8');
	Cidx(i)=idx;
	idx=idx+nV;
	Cidx(i,2)=idx-1;
	C{1,i}=nCi;
	C{2,i}=nVi;
end
C=struct(C{:});

function [H,iX1,iX2]=ReadCustomData(H,Xraw,sizImage,btPerP,Cidx)
iX0=SearchPart(Xraw(:,1),typecast(swapbytes(uint32(sizImage)),'uint8')');
iX1=iX0+8;
iX2=iX1+prod(sizImage)*btPerP-1;
C=H.C;
if isempty(fieldnames(C))
	% do nothing
else
	fn=fieldnames(C);
	% check if Xraw(iX2+5:iX2+8,:) is all equal (and equal to length(fieldnames))
	Xcustom=Xraw(iX2+9:end,:);
	C(size(Xraw,2)+1)=C;
	for i=1:size(Xraw,2)
		for j=1:length(fn)
			C(i+1).(fn{j})=Xcustom(Cidx(j):Cidx(j,2),i)';
		end
	end
	H.C=C;
end
