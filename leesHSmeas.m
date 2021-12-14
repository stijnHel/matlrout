function [e,ne,de,e2,gegs,SET]=leesHSmeas(fname,varargin)
%leesHSmeas - Reads a HS-measurement from labview (raw binary format)
%   [e,ne,de,e2,gegs]=leesHSmeas(fname[,start,lengte,kans,options])
%
%  made for files writing to 16-bit signed integer data format with
%  "setting file" (HSmeas.vi)

if ~exist(fname,'file')
	fname=zetev([],fname);
	if ~exist(fname,'file')
		error('Can''t open the file')
	end
end
[pth,fn]=fileparts(fname);
datafile=fullfile(pth,fn);
setfile=[datafile '.set'];

start=[];
lengte=[];
kans=[];
scaled=[];
options={};
tSignal=true;
bReverseScale=true;	% ?sometimes one, sometimes the other is needed???

if nargin>1&&(ischar(varargin{1})||iscell(varargin{1}))
	if iscell(varargin{1})
		options=varargin{1};
	else
		options=varargin;
	end
elseif nargin>1
	start=varargin{1};
	if nargin>2
		lengte=varargin{2};
		if nargin>3
			kans=varargin{3};
			if nargin>4
				scaled=varargin{4};
				if nargin>5
					options=varargin(5:end);
				end
			end
		end
	end
end

if ~isempty(options)
	setoptions({'kanx','start','lengte','scaled','tSignal','bReverseScale'}	...
		,options{:})
end
if isempty(scaled)
	scaled=true;
end
if isempty(tSignal)
	tSignal=true;
end

fid=fopen(setfile,'r','ieee-be');
if fid<3
	error('settings file can''t be opened (%s)',setfile)
end
n1=fread(fid,1,'uint32');
S1=fread(fid,n1,'uint16');
if n1>length(S1)
	fclose(fid);
	error('Problem reading settings file - type definition can''t be read')
end
n2=fread(fid,1,'uint32');
S2=fread(fid,n2,'uint8');
fclose(fid);
if n2>length(S2)
	error('Problem reading settings file - data can''t be read')
end
[SD,ST]=readLVtypeString(S1,S2);
S=lvData2struct(SD);
if isfield(S,'chanCal')
	if isequal(fieldnames(S.chanCal),{'x1'})
		S.chanCal=cat(2,S.chanCal.x1);	%!!!???
	end
	s=cat(2,S.chanCal.AI_DevScalingCoeff);
	AIres=cat(2,S.chanCal.AI_Resolution);
	if length(unique(AIres))>1
		warning('HSMEAS:diffRes','!!made for single resolutions!!')
	end
	AIres=median(AIres);
else
	s=S.AI_DevScalingCoeff;
	AIres=S.AI_Resolution;
end
if bReverseScale
	s=s(end:-1:1,:);
end

% read the data file
blocksize = S.lBlock;
nSignals = S.NumChans;
if AIres<=16
	nBytes=2;
	rType='int16';
else
	nBytes=4;
	rType='int32';
end

fid=fopen(datafile,'r','ieee-be');
if fid<3
	error('Can''t open the datafile (%s)!',datafile)
end
fseek(fid,0,'eof');
lFile=ftell(fid);
fseek(fid,0,'bof');

if isempty(start)
	start=0;
end
numSamples=lFile/nBytes/nSignals;
if numSamples>floor(numSamples)
	warning('HSMEAS:varBlockSize','??not an integral number of blocks??!')
	numSamples=floor(numSamples);
end
if isempty(lengte)
	lengte=numSamples;
elseif lengte<0
	start=numSamples+lengte;
	lengte=-lengte;
end
if ~isempty(kans)
	if any(kans<1|kans>nSignals)
		warning('FMTClxXMLread:unknownChannels','Unkown channels are requested!')
		kans=kans(kans>=1&kans<=nSignals);
	end
end
e = read_datafile(fid,blocksize,nSignals,numSamples,start,lengte,kans,rType);
if scaled
	%if numel(s)==2
	%	e=(e+s(1))*s(2);
	%else
	%	e=(e+s(ones(size(e,1),1),:))*diag(s(2,:));
	%end
    for i=1:size(s,2)
        e(:,i)=polyval(s(:,i),e(:,i));
    end
end
fSample=S.fSample;
if fSample==0
	fSample=S.AI_Sample_Rate;
end
if tSignal
	e=[(0:length(e)-1)'/fSample e];
end
if nargout>1
	ne=cellstr(reshape(sprintf('k%02d',1:nSignals),3,[])');
	if tSignal
		ne={'t',ne{:}};
		de={'t','-'};
		de(3:length(ne))=de(2);
	else
		de={'-'};
		de(2:length(ne))=de(1);
	end
	e2=[];
	gegs=S;
	gegs.fullDataFile=datafile;
	gegs.numSamples=numSamples;
	gegs.start=start;
	gegs.lengte=lengte;
	if nargout>5
		SET=struct('Stype',S1,'Sdata',S2,'ST',{ST},'SD',{SD});
	end
end

function e = read_datafile(fid,blocksize,nChannel,nSamp	...
	,start,lengte,kanalen,rType)

if rem(nSamp,blocksize)
	warning('FMTClxXMLread:notFullBlockRequested','!!!!number of samples not a whole number of blocks!!!!')
	nSamp=nSamp-rem(nSamp,blocksize);
end
start=max(start,0);
lengte=min(lengte,nSamp-start);

firstBlock=floor(start/blocksize);
offset=firstBlock*blocksize;
if offset>0
	fseek(fid,offset,'bof');
end
nBlocksToRead=ceil((start+lengte-1)/blocksize)-firstBlock;

e = fread(fid,blocksize*nChannel*nBlocksToRead,rType);
fclose(fid);

%% resize data
if nChannel==1
	e=e(:);
else
	e=reshape(e,blocksize,nChannel,nBlocksToRead);
end
if ~isempty(kanalen)
	e=e(:,kanalen,:);
	nChannel=length(kanalen);
end
if nChannel>1
	i=(0:nBlocksToRead-1)'*nChannel;
	j=1:nChannel;
	i=i(:,ones(1,nChannel))+j(ones(1,nBlocksToRead),:);
	e=reshape(e(:,i),blocksize*nBlocksToRead,nChannel);
end
iStart=rem(start,blocksize);
if iStart||size(e,1)>lengte
	e=e(iStart+1:iStart+lengte,:);
end
