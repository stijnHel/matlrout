function X=ReadSpeedgoatDAT(fName,varargin)
%ReadSpeedgoatDAT - Read DAT-file created by speedgoat
%
%    X=ReadSpeedgoatDAT(fName)
%
%       Created without info about fileformat - just hacking...

lDataMax = 2^32;
skipSamples = 0;
bMultiBlock = true;

if nargin>1
	setoptions({'lDataMax','skipSamples','bMultiBlock'},varargin{:})
end

fFull = fFullPath(fName);
fid = fopen(fFull);
if fid<3
	error('Can''t open the file (%s)',fFull)
end
fseek(fid,0,'eof');
lFile = ftell(fid);
fseek(fid,0,'bof');
n=fread(fid,[1 5],'uint32');
hSize=n(3);
H=fread(fid,[1 hSize-20],'*uint8');
nChannels=n(5);
idxChannels=[0 find(H==0)];
channels=cell(1,nChannels);
for i=1:nChannels
	channels{i}=char(H(idxChannels(i)+1:idxChannels(i+1)-1));
end

nSamplesTot = (lFile-ftell(fid)) / (8*nChannels);
if nSamplesTot>floor(nSamplesTot)
	warning('Is file broken?')
	nSamplesTot = floor(nSamplesTot);
end
nSamples = nSamplesTot;
if skipSamples>0
	fseek(fid,skipSamples*8*nChannels,'cof');
	nSamples = nSamples-skipSamples;
end
nBlocks = 1;
if nSamples*8*nChannels>lDataMax
	nSamplesNew = floor(lDataMax/nChannels/8);
	if bMultiBlock
		nBlocks = ceil(nSamples/nSamplesNew);
	end
	warning('Data is truncated (%d --> %d)',nSamples,nSamplesNew)
	nSamples = nSamplesNew;
end

X = var2struct(channels,n);
X.data = fread(fid,[nChannels,nSamples],'double')';
if nBlocks>1
	for iBlock = 2:nBlocks
		X.(sprintf('data%d',iBlock)) = fread(fid,[nChannels,nSamples],'double')';
	end
end
fclose(fid);
