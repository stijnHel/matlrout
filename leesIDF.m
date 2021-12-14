function [e,ne,de,e2,gegs]=leesIDF(fn,varargin)
%leesIDF  - Reads dSpace IDF-file
%    [e,ne,de,e2,gegs]=leesIDF(fn);

fid=fopen(zetev([],fn));
if fid<3
	fid=fopen(fn);
	if fid<3
		error('Can''t open the file')
	end
end
x=fread(fid,[1 Inf],'*uint8');
fclose(fid);
hString=char(x(1:40));
iX=40;
if ~strncmp(hString,'TRACE In',8)
	error('Wrong file start for IDF-file')
end
[N1,iX]=GetNum(x,iX,'uint32',16);
[N2,iX]=GetNum(x,iX,'uint16',4);

nChan=N1(2);	% right guess? (nChan + X-channel)
nData=N1(3);
blockSize=double(N2(1));	% right guess?
CHAN=struct('name',cell(1,nChan),'unit',[],'type',[]);
Bok=true(1,nChan);
bNOK=false;
for i=1:nChan
	[s,iX]=GetString(x,iX);
	[d,iX]=GetString(x,iX);
	[typ,iX]=GetNum(x,iX,'uint16',2);
	if isempty(s)||typ==65536
		Bok(i)=false;
		bNOK=true;
	else
		CHAN(i).name=s;
		CHAN(i).unit=d;
		CHAN(i).type=typ;
	end
end
if bNOK
	CHAN=CHAN(Bok);
	nChan=length(CHAN);
end
[N3,iX]=GetNum(x,iX,'uint16',10);
nBlock=N3(4);	% !guessed!
tOffset=datenum(1900,1,-1);
cBLOCKS=cell(2,nBlock);
for iBlock=1:nBlock
	[s,iX]=GetString(x,iX);
	cBLOCKS{1,iBlock}=s;
	[nFld,iX]=GetNum(x,iX,'uint16',4);
	if nFld(2)~=0
		warning('LEESIDF:UnexpNum','unexpected number when reading blocks (%d - %d)',nFld)
	end
	nFld=nFld(1);
	FIELDS=cell(2,nFld);
	for iFld=1:nFld
		[FIELDS{1,iFld},iX]=GetString(x,iX);
		[typ,iX]=GetNum(x,iX,'uint16',4);
		if typ(2)~=0
			warning('LEESIDF:UnexpNum','unexpected number when reading fields (%d - %d)',typ)
		end
		typ=typ(1);
		switch typ
			case 3	% (?)uint32
				[data,iX]=GetNum(x,iX,'uint32',4);
			case 5	% double
				[data,iX]=GetNum(x,iX,'double',8);
			case 7	% date/time (datenum-value)
				[data,iX]=GetNum(x,iX,'double',8);
				data=datestr(data+tOffset);
			case 8	% string
				[data,iX]=GetString(x,iX);
			otherwise
				error('Unknown data type (%d)!',typ)
		end
		FIELDS{2,iFld}=data;
	end	% for iFld
	cBLOCKS{2,iBlock}=struct(FIELDS{:});
end	% for iBlock
BLOCKS=struct(cBLOCKS{:});
nXraw=length(x)-iX;
if rem(nXraw,blockSize)
	warning('LEESIDF:notFullBlock','not full blocks?')
	nXraw=nXraw-rem(nXraw,blockSize);
end
if nXraw/blockSize~=nData
	warning('!!!!')
end
X=reshape(x(iX+1:iX+nXraw),blockSize,[]);
i0=0;
e=zeros(nData,nChan);
iRD16=[7 8 5 6 3 4 1 2];
for i=1:nChan
	switch CHAN(i).type
		case 4
			e(:,i)=typecast(reshape(X(i0+1:i0+8,:),[],1),'double');
			i0=i0+8;
		case 5
			e(:,i)=typecast(reshape(X(i0+iRD16,:),[],1),'double');
			i0=i0+8;
		case 15
			i0=i0+1;
			e(:,i)=double(X(i0,:));
		otherwise
			warning('LEESIDF:unknownChanType','Unknown channel type!')
			i0=i0+8;
	end
end

ne={CHAN.name};
de={CHAN.unit};
e2=[];
gegs=struct('CHAN',CHAN,'BLOCKS',BLOCKS		...
	,'hString',hString,'N1',N1,'N2',N2,'N3',N3);

function [a,iX]=GetNum(x,iX,typ,nBytes)
bSwap=false;
a=typecast(x(iX+1:iX+nBytes),typ);
if bSwap
	a=swapbytes(a); %#ok<UNRCH>
end
iX=iX+double(nBytes);

function [s,iX]=GetString(x,iX)
[n,iX]=GetNum(x,iX,'uint16',2);
s=char(x(iX+1:iX+n));
iX=iX+double(n);
