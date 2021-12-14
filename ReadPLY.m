function X=ReadPLY(fName)
%ReadPLY  - Read PLY file ("Stanford Triangle Format" - 3D data)
%    X=ReadPLY(fName)

fid=fopen(fFullPath(fName));
if fid<3
	error('Can''t open the file!')
end

x=fread(fid,[1 Inf],'*uint8');
fclose(fid);

C=cell(1,100);
Dspec=struct('type',cell(1,10),'n',[],'prop',[]);
nDspec=0;
nC=0;
ix=1;
iErr=0;
bLoop=true;
v=[];
while iErr==0&&bLoop
	i1=ix;
	while x(ix)~=10
		ix=ix+1;
		if x(ix)==0	% shouldn't happen!
			iErr=1;
			warning('Error in reading header!')
			break
		end
	end
	l=char(x(i1:ix-1));
	nC=nC+1;
	C{nC}=l;
	if nC==1
		if ~strcmp(l,'ply')
			warning('File doesn''t start with the required "ply"!')
			iErr=2;
		end
	elseif nC==2
		if ~strncmp(l,'format ',7)
			warning('File doesn''t specify the format!')
			iErr=3;
			break
		end
		[dataFormat,n,err,iNxt]=sscanf(l(8:end),'%s',1);
		if n~=1
			warning('Error in format type (%s)',err)
			iErr=4;
			break
		end
		v=sscanf(l(7+iNxt:end),'%g');
	else
		[w,n,err,iNxt]=sscanf(l,'%s',1);
		if n~=1
			warning('Error in element/property (%s - %s)',l,err)
			iErr=5;
			break
		end
		switch w
			case 'end_header'
				bLoop=false;
			case 'element'
				nDspec=nDspec+1;
				[typ,~,~,iNxt1]=sscanf(l(iNxt:end),'%s',1);
				Dspec(nDspec).type=typ;
				iNxt=iNxt+iNxt1;
				N=sscanf(l(iNxt:end),'%d',1);
				Dspec(nDspec).n=N;
				Dspec(nDspec).prop=struct('typ',{},'name',[],'list',[]);
			case 'property'
				[typ,~,~,iNxt1]=sscanf(l(iNxt:end),'%s',1);
				iNxt=iNxt+iNxt1;
				[w,~,~,iNxt1]=sscanf(l(iNxt:end),'%s',1);
				iNxt=iNxt+iNxt1;
				if strcmp(typ,'list')
					[typ,~,~,iNxt1]=sscanf(l(iNxt:end),'%s',1);
					iNxt=iNxt+iNxt1;
					name=sscanf(l(iNxt:end),'%s',1);
					Dspec(nDspec).prop(1,end+1).typ='list';
					Dspec(nDspec).prop(end).name=name;
					Dspec(nDspec).prop(end).list={w,typ};
				else
					Dspec(nDspec).prop(1,end+1).typ=typ;
					Dspec(nDspec).prop(end).name=w;
				end
			case 'comment'
			otherwise
				warning('Unknown data line type (%s)',l)
				iErr=6;
				break
		end
	end
	ix=ix+1;
end

C=C(1:nC);
Dspec=Dspec(1:nDspec);
D=cell(1,nDspec);

if startsWith(dataFormat,'binary','IgnoreCase',true)
	if ~endsWith(dataFormat,'little_endian','IgnoreCase',true)
		warning('The format is not little endian - this is not foreseen!!!!')
	end
	for i=1:nDspec
		nBytes=zeros(1,length(Dspec(i).prop));
		TYP=cell(1,length(nBytes));
		bList=false;
		for j=1:length(nBytes)
			[nB,typ]=GetType(Dspec(i).prop(j).typ,Dspec(i).prop(j).list);
			if isscalar(nB)
				nBytes(j)=nB;
			else
				bList=true;
				nBytes(j)=nB(1)+nB(2)*x(ix);	%!!!!!!!!!!!!!!!
				if nB(1)>1
					error('Sorry, the number of bytes for number of points is expected to be 1!')
				end
			end
			TYP{j}=typ;
		end
		nB=sum(nBytes);
		ixN=ix+nB*Dspec(i).n;
		iD=0;
		if bList
			if length(nBytes)~=1
				error('Sorry, I expected that a list was the single property of an element, if it exists!')
			elseif ixN>length(x)+1
				error('Trying to read beyond the end of the file?!')
			elseif any(x(ix:nB:ixN-1)~=x(ix))
				error('Sorry, with a list, it''s expected that all elements have the same number of points!')
			end
			nPts=double(x(ix));
			dRaw=reshape(x(ix:ixN-1),nB,[]);
			dRaw(1,:)=[];
			D_i=reshape(typecast(dRaw(:),TYP{1}{2}),nPts,[]);
		else
			dRaw=reshape(x(ix:ixN-1),nB,[]);
			D_i=zeros(size(dRaw,2),length(nBytes));
			for j=1:length(nBytes)
				iDn=iD+nBytes(j);
				if ischar(TYP{j})
					D_i(:,j)=typecast(reshape(dRaw(iD+1:iDn,:),[],1),TYP{j});
				else
				end
				iD=iDn;
			end
		end
		D{i}=D_i;
		ix=ixN;
	end
elseif startsWith(dataFormat,'ascii','IgnoreCase',true)
	for i=1:nDspec
		bList=strcmp(Dspec(i).type,'face');
		% just copied from binary version - and than used towards a known file!!!!!!
		if bList
			nElem = sscanf(char(x(ix:min(end,ix+10))),'%d',1);
			siz = [1+nElem Dspec(i).n];
			[D_i,n,~,iNxt] = sscanf(char(x(ix:end)),'%g',siz);
			if ~all(D_i(1,:)==D_i(1))
				warning('Sorry, with a list, it''s expected that all elements have the same number of points!')
			end
			D_i(1,:) = [];
		else
			siz = [length(Dspec(i).prop) Dspec(i).n];
			[D_i,n,~,iNxt] = sscanf(char(x(ix:end)),'%g',siz);
		end
		if prod(siz)~=n
			warning('Not everything read?! ([%dx%d] (%d) <--> %d)',siz(1),siz(2),prod(siz),n)
		end
		D{i} = D_i';
		ix = ix+iNxt;
	end
else
	error('Sorry, dataformat %s is not implemented')
end

X=var2struct(D,C,v,Dspec,dataFormat);
if iErr
	X.err=iErr;
end

function [nB,typ]=GetType(sTyp,tList)
switch sTyp
	case 'char'
		nB=1;
		typ='int8';
	case 'uchar'
		nB=1;
		typ='uint8';
	case 'short'
		nB=2;
		typ='int16';
	case 'ushort'
		nB=2;
		typ='uint16';
	case 'int'
		nB=4;
		typ='int32';
	case 'uint'
		nB=4;
		typ='uint32';
	case 'float'
		nB=4;
		typ='single';
	case 'double'
		nB=8;
		typ='double';
	case 'list'
		[nCnt,typCnt]=GetType(tList{1});
		[nT,typD]=GetType(tList{2});
		nB=[nCnt nT];
		typ={typCnt,typD};
	otherwise
		error('Unknown data type! (%s)',sTyp)
end
