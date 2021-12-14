function [R,varargout]=ReadRIFFstruct(fName,varargin)
%ReadRIFFstruct - Read the structure of a RIFF-file
%    R=ReadRIFFstruct(fName)
%    Rmin=ReadRIFFstruct(fName,'-bMinRead')
%            Minimum amount of data to be read
%    R=ReadRIFFstruct(R,frameNr)
%            Update Rminimum (having data about the requested frame)
%    Last two are related to RIFFstream, to start-up quickly.
%        !!!!!!!!!!!this minimum reading is ongoing and not final!!!!

bMinRead=isstruct(fName);

if isstruct(fName)
	varargout=cell(1,max(0,nargout-1));
	[R,varargout{:}]=Update(fName,varargin{:});
	return
end

if nargin>1
	setoptions({'bMinRead'},varargin{:})
end

cF=file(fFullPath(fName));

nChunks=0;

fPos=0;
chID=cF.fread([1 4],'*char');
if bMinRead
	CHUNKS=struct('ID',[],'typ',[],'pos',[],'len',[],'D',[]);
else
	CHUNKS=struct('ID',cell(1,10000),'typ',[],'pos',[],'len',[],'D',[]);
	cStat=cStatus('Reading the full structure of the RIFF-file',0);
end
while ~isempty(chID)
	nChunks=nChunks+1;
	CHUNKS(nChunks).ID=chID;
	CHUNKS(nChunks).pos=fPos;
	l=cF.fread(1,'uint32');
	CHUNKS(nChunks).len=l;
	if strcmpi(chID,'riff')
		if bMinRead
			typ=deblank(cF.fread([1 4],'*char'));
			if ~strcmpi(typ,'avi')
				error('Expected an AVI-chunk! (and no "%s")',typ)
			end
			CHUNKS=ReadIndex(cF,l);
			break
		else
			CHUNKS(nChunks).typ=deblank(cF.fread([1 4],'*char'));
			CHUNKS(nChunks).D=ReadChunks(cF,l,false);
		end
	else
		warning('Unexpected!');
	end
	if rem(l,2)
		l=l+1;
	end
	fseek(cF.fid,fPos+8+l,'bof');
	fPos=cF.ftell();
	chID=cF.fread([1 4],'*char');
	if ~bMinRead
		cStat.status(fPos/cF.length())
	end
end
if ~bMinRead
	cStat.close()
end
CHUNKS=CHUNKS(1:nChunks);
R=CHUNKS;

function [CHUNKS,bStop]=ReadChunks(cF,len,bEarlyStop)
nRead=0;
bStop=false;
if bEarlyStop
	CHUNKS=struct('ID',cell(1,3),'typ',[],'pos',[],'len',[],'D',[]);
else
	CHUNKS=struct('ID',cell(1,10000),'typ',[],'pos',[],'len',[],'D',[]);
end
nChunks=0;
fPos=cF.ftell();
chID=cF.fread([1 4],'*char');
while ~isempty(chID)
	l=cF.fread(1,'uint32');
	if l+8+nRead>len
		warning('trying to read after the current chunk!')
		% to do with alignment? (happens with RIFF - only?)
		break
	end
	%fprintf('%s (%12d %10d): %10d\n',chID,fPos,nRead,l)
	if ~strcmpi(chID,'junk')	% discard junk-chunks
		nChunks=nChunks+1;
		CHUNKS(nChunks).ID=chID;
		CHUNKS(nChunks).pos=fPos+nRead;
		CHUNKS(nChunks).len=l;
		if strcmpi(chID,'list')
			CHUNKS(nChunks).typ=cF.fread([1 4],'*char');
			[D,bStop]=ReadChunks(cF,l-4,bEarlyStop);
			if strcmpi(chID,'list')&&strcmpi(CHUNKS(nChunks).typ,'info')
				Bi=strncmpi('i0',{D.ID},2);
				if any(Bi)
					i=find(Bi);
					xml=deblank([D(i).D]);
					XML=readxml({xml},false,true,true);
					D(i(2:end))=[];
					i=i(1);
					D(i).ID='XML';
					D(i).pos=-1;
					D(i).len=0;
					D(i).D=XML;
				end
			end
			CHUNKS(nChunks).D=D;
			if bStop
				break
			end
		else
			[CHUNKS(nChunks).D,nE]=ReadChunk(cF,chID,l);
			if bEarlyStop&&strcmpi(chID,'indx')
				bStop=true;
				break
			end
			nRead=nRead+nE;
		end
	end
	if rem(l,2)
		l=l+1;
	end
	nRead=nRead+8+l;
	if nRead>len-8	% (!to do with different requirements for alignment?)
		break
	end
	fseek(cF.fid,fPos+nRead,'bof');
	chID=cF.fread([1 4],'*char');
end
CHUNKS=CHUNKS(1:nChunks);

function [D,nbExtra]=ReadChunk(cF,chID,l)
global CHUNKNOWN
if isempty(CHUNKNOWN)
	CHUNKNOWN=struct('ID',cell(1,0),'fPos',[]);
end
nbExtra=0;
nDataMax=1024;
if strcmpi(chID,'avih')
	I=cF.fread([1 15],'uint32');
	D=struct(	...
		'dwMicroSecPerFrame',I(1)	...
		,'dwMaxBytesPerSec',I(2)	...
		,'dwPaddingGranularity',I(3)	...
		,'dwFlags',I(4)	...
		,'dwTotalFrames',I(5)	...
		,'dwInitialFrames',I(6)	...
		,'dwStreams',I(7)	...
		,'dwSuggestedBufferSize',I(8)	... 
		,'dwWidth',I(9)	...
		,'dwHeight',I(10));
elseif strcmp(chID,'strh')
	x=cF.fread([1 l],'*uint8');
	D=struct(	...
		'fccType',char(x(1:4))	...
		,'fccHandler',char(x(5:8))	...
		,'dwFlags',typecast(x(9:12),'uint32')	...
		,'wPriority',typecast(x(13:14),'uint16')	...
		,'wLanguage',typecast(x(15:16),'uint16')	...
		,'dwInitialFrames',typecast(x(17:20),'uint32')	...
		,'dwScale',typecast(x(21:24),'uint32')	...
		,'dwRate',typecast(x(25:28),'uint32')	...
		,'dwStart',typecast(x(29:32),'uint32')	...
		,'dwLength',typecast(x(33:36),'uint32')	...
		,'dwSuggestedBufferSize',typecast(x(37:40),'uint32')	...
		,'dwQuality',typecast(x(41:44),'uint32')	...
		,'dwSampleSize',typecast(x(45:48),'uint32')	...
		,'rect',typecast(x(49:56),'int16')	...
		);
elseif strcmp(chID,'strf')
	x=cF.fread([1 l],'*uint8');
	D=struct(	...
		'biSize',typecast(x(1:4),'uint32')	...
		,'biWidth',typecast(x(5:8),'uint32')	...
		,'biHeight',typecast(x(9:12),'uint32')	...
		,'biPlanes',typecast(x(13:14),'uint16')	...
		,'biBitCount',typecast(x(15:16),'uint16')	...
		,'biCompression',char(x(17:20))	...
		,'biSizeImage',typecast(x(21:24),'uint32')	...
		,'biXPelsPerMeter',typecast(x(25:28),'uint32')	...
		,'biYPelsPerMeter',typecast(x(29:32),'uint32')	...
		,'biClrUsed',typecast(x(33:36),'uint32')	...
		,'biClrImportant',typecast(x(37:40),'uint32')	...
		);
elseif strcmpi(chID,'indx')
	x=cF.fread(l,'*uint8');
	D=struct('wLongsPerEntry',double(typecast(x(1:2),'uint16'))	...
		,'bIndexSubType_0',x(3)	...
		,'bIndexType',x(4)	...
		,'nEntriesInUse',double(typecast(x(5:8),'uint32'))	...
		,'chunkID',char(x(9:12)')	...
		,'dwReserved',typecast(x(13:24),'uint32')'	....
		);
	ix=24+D.nEntriesInUse*D.wLongsPerEntry*4;
	D.aIndex=reshape(typecast(x(25:ix),'uint32'),D.wLongsPerEntry,[])';
elseif strncmpi(chID,'ix',2)
	x=cF.fread(l,'*uint8');
	D=struct('wLongsPerEntry',typecast(x(1:2),'uint16')	...
		,'bIndexSubType_0',x(3)	...
		,'bIndexType',x(4)	...
		,'nEntriesInUse',typecast(x(5:8),'uint32')	...
		,'chunkID',char(x(9:12)')	...
		,'qwBaseOffset',typecast(x(13:20),'uint64'));	% reserved not stored
	ix=24+D.nEntriesInUse*8;
	D.dwOffdwSize=reshape(typecast(x(25:ix),'uint32'),2,[])';
elseif strcmpi(chID,'idx1')
	idx1=cF.fread([4,floor(l/16)],'uint32');
	D=struct('ID',idx1(1,:)	...
		,'flags',idx1(2,:)	...
		,'offset',idx1(3,:)	...
		,'length',idx1(4,:));
	if rem(l,16)	%!!
		nbExtra=rem(l,16);
		cF.fseek(nbExtra,'cof');
	end
elseif strcmpi(chID,'meta')||strncmpi(chID,'i0',2)
	D=cF.fread([1 l],'*char');
	D(D==0)=[];
elseif strcmpi(chID(3:4),'db')
	D=cF.fread([1 min(nDataMax,l)],'*uint8');
else
	if false	% keep track of not implemented types
		if isempty(CHUNKNOWN)||~any(strcmp(chID,{CHUNKNOWN.ID}))
			CHUNKNOWN(1,end+1).ID=chID;
			i=length(CHUNKNOWN);
		else
			i=find(strcmp(chID,{CHUNKNOWN.ID}));
		end
		CHUNKNOWN(i).fPos(1,end+1)=cF.ftell();
	end
	D=cF.fread([1 min(nDataMax,l)],'*uint8');
end

function R=ReadIndex(cF,l)
%ReadIndex - used as "minimal struct-reading"
R=ReadChunks(cF,l,true);
R.totalFrames=R.D(1).D.dwTotalFrames;
R.length=R.D(2).D(1).D.dwLength;
R.musPerFrame=R.D(1).D.dwMicroSecPerFrame;
R.width=R.D(1).D.dwWidth;
R.height=R.D(1).D.dwHeight-1;	%???!!
R.indx=R.D(end).D(end).D.aIndex;	%?!!
R.idxStart=double(R.indx(:,1:2))*[1;2^32];
R.ix00=[];
R.file=cF;
R=Update(R,1);	% Make sure the first ix00 is read

function [R,Ximage,xHead]=Update(R,varargin)
R.file.fopen(false);	% Make sure the file is open!
if isnumeric(varargin{1})
	frameNr=varargin{1};
	iFrame=frameNr;
	iIX00=1;
	while true
		if iIX00>length(R.ix00)
			R.file.fseek(R.idxStart(iIX00),'bof');
			I=fread(R.file,[1 2],'uint32');
			chID=char(typecast(uint32(I(1)),'uint8'));
			if ~strcmpi(chID,'ix00')
				error('something is going wrong - ix00 expected!!!')
			end
			ix00=ReadChunk(R.file,chID,I(2));
			if iIX00==1
				R.ix00=ix00;
			else
				R.ix00(iIX00)=ix00;
			end
		end
		if iFrame>R.ix00(iIX00).nEntriesInUse
			iFrame=iFrame-R.ix00(iIX00).nEntriesInUse;
			iIX00=iIX00+1;
			if iIX00>length(R.idxStart)
				iIX00=iIX00-1;
				nFramesFound=frameNr-iFrame;
				warning('Less frames found than expected (%d<->%d)'	...
					,nFramesFound,R.totalFrames)
				R.totalFrames=nFramesFound;
				iFrame=R.ix00(iIX00).nEntriesInUse;
				break
			end
		else
			break
		end
	end
else
	error('Not implemented functionality!')
end
if nargout>1
	if nargout>2
		R.file.fseek(double(R.ix00(iIX00).qwBaseOffset)	...
			+double(R.ix00(iIX00).dwOffdwSize(iFrame)),'bof');
		xHead=R.file.fread([1 764],'*uint8');
	else
		R.file.fseek(double(R.ix00(iIX00).qwBaseOffset)	...
			+double(R.ix00(iIX00).dwOffdwSize(iFrame))+764,'bof');
	end
	Ximage=R.file.fread([R.width,R.height],'*uint16')';
end
