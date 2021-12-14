function saveHSmeas(fname,E,SET,varargin)
%saveHSmeas - Writes a HS-measurement (raw binary format)
%   saveHSmeas(fname,E,SET)
%
%  made for replacements of HSmeas-files written by labView program

[fpth,fn,fext]=fileparts(fname);
if isempty(fext)
	fMEAS=fname;
	fSET=[fname '.set'];
elseif strcmpi(fext,'.set')
	fSET=fname;
	fMEAS=fname(1:end-4);
else
	error('only made for ".set-files"!')
end
S=lvData2struct(SET.SD);
i=strmatch('rawDataFile',SET.ST(:,4),'exact');
if isempty(i)
	warning('HSMEAS:rawDATAfile','No rawDataFile field found!')
else
	SET.SD{i}=fn;
end

fid=fopen(fSET,'w','ieee-be');
if fid<3
	error('Can''t open the file')
end
fwrite(fid,length(SET.Stype),'uint32');
fwrite(fid,SET.Stype,'uint16');
writeLVdata(SET.ST,SET.SD,fid);
fclose(fid);

scaled=true;
bReverseScale=true;	% ?sometimes one, sometimes the other is needed???

if ~isempty(varargin)
	setoptions({'scaled','bReverseScale'}	...
		,varargin{:})
end

if isfield(S,'chanCal')
	chan=S.chanCal;
	if isequal(fieldnames(chan),{'x1'})
		chan=cat(2,chan.x1);	%!!!???
	end
	s=cat(2,chan.AI_DevScalingCoeff);
	AIres=cat(2,chan.AI_Resolution);
	if length(unique(AIres))>1
		warning('HSMEAS:diffRes','!!made for single resolutions!!')
	end
	AIres=median(AIres);
else
	error('not found scaling data');
end
if bReverseScale
	s=s(end:-1:1,:);
end

blocksize = S.lBlock;
nSignals = S.NumChans;
if size(E,2)==nSignals+1
	E(:,1)=[];	% probably time data
elseif size(E,2)~=nSignals
	error('number of signals doesn''t match input array!')
end
% all supposed to be signed(!)
if AIres<=16
	nBytes=2;
	rType='int16';
else
	nBytes=4;
	rType='int32';
end

if size(E,1)==1
	E=E';
end
numSamples=size(E,1);
if rem(numSamples,blocksize)
	nNum=ceil(numSamples/blocksize)*blocksize;
	for i=1:nSignals
		E(numSamples+1:nNum,i)=E(numSamples,i);
	end
end
if scaled
	iMin=-2^(nBytes*8-1);
	iMax=-iMin-1;
	iR=iMin:max(256^nBytes/1000,1):iMax;
	if iR(end)<iMax
		iR(end)=iMax;
	end
	for i=1:size(s,2)
		vR=polyval(s(:,i),iR);
		pr=polyfit(vR,iR,size(s,1)-1);
		E(:,i)=polyval(pr,E(:,i));
	end
end
E=cast(E,rType);

E = reshapeData(E,blocksize,nSignals);
fid=fopen(fMEAS,'w','ieee-be');
if fid<3
	error('Can''t open the datafile (%s)!',fMEAS)
end
fwrite(fid,E,rType);
fclose(fid);

function E = reshapeData(E,blocksize,nChannel)
nBlocks=size(E,1)/blocksize;
if nChannel>1
	E=reshape(E,blocksize,nBlocks*nChannel);
	i=(1:nBlocks:nBlocks*nChannel)';
	j=0:nBlocks-1;
	i=i(:,ones(1,nBlocks))+j(ones(1,nChannel),:);
	E=E(:,i);
end
