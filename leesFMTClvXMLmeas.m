function [e,ne,de,e2,gegs]=leesFMTClvXMLmeas(fname,start,lengte,kans)
%leesFMTClvXMLmeas - Reads a FMTC-style measurement from labview
%   [e,ne,de,e2,gegs]=leesFMTClvXMLmeas(fname)

bAddTime=false;

if isnumeric(fname)
	if fname<0
		d=direv('*.xml','sort');
		fname=-fname;
	else
		d=direv('*.xml');
	end
	if fname<0||fname>length(d)
		error('Can''t find the file you requested')
	end
	fpth=zetev;
	fname=zetev([],d(fname).name);
else
	[fpth,fnm,fext]=fileparts(fname);
	if isempty(fext)
		fname=[fname '.xml'];
	end
	if isempty(fpth)
		fpth=zetev;
		fname=zetev([],fname);
	else
		if ~exist(fpth,'dir')
			fpth=zetev([],fpth);
			if ~exist(fpth,'dir')
				error('Can''t find the path (not locally, not in evdir)')
			end
			fname=zetev([],fname);
		end
		fpth(end+1)=filesep;
	end
end
mis = readFMTCxml(fname);
%mis = VA_xml2mis(fname);

% read the data file
datafilename = [fpth mis.DataFile];
blocksize = mis.BlockSize;
nSignals = mis.NumberOfSignals;

fid=fopen(datafilename,'r');
if fid<3
	error('Can''t open the datafile!')
end
fseek(fid,0,'eof');
lFile=ftell(fid);
fclose(fid);
if mis.NumberOfSamples<0
	warning('!!wrong NumberOfSamples in xml-file (negative)!!');
	mis.NumberOfSamples=floor(lFile/8/blocksize/nSignals)*blocksize;
elseif mis.NumberOfSamples*nSignals*8>lFile
	warning('!!wrong NumberOfSamples in xml-file (too high)!!');
	mis.NumberOfSamples=floor(lFile/8/blocksize/nSignals)*blocksize;
elseif mis.NumberOfSamples*nSignals*8<lFile
	warning('!!lower NumberOfSamples in xml-file than length of datafile??');
end

if nargin<4
	kans=[];
	if nargin<3
		lengte=[];
		if nargin<2
			start=[];
		end
	end
end
if isempty(start)
	start=0;
end
if isempty(lengte)
	lengte=mis.NumberOfSamples;
end
if ~isempty(kans)
	if any(kans<1|kans>nSignals)
		warning('FMTClxXMLread:unknownChannels','Unkown channels are requested!')
		kans=kans(kans>=1&kans<=nSignals);
	end
end
e = read_datafile(datafilename,blocksize,nSignals,mis.NumberOfSamples,start,lengte,kans);
if bAddTime
	e=[(0:length(e)-1)'/mis.SamplingRate e];
end
if nargout>1
	if isfield(mis,'signals')
		%ne={'t' mis.data.signal.name};
		%de={'s' mis.data.signal.units};
		ne={mis.signals.name};
		de={mis.signals.units};
	else
		ne=[cellstr(reshape(sprintf('k%02d',1:mis.NumberOfSignals),3,[])')]';
		de={'-'};
		de(1:length(ne))=de(1);
	end
	if bAddTime
		ne=['t' ne];
		de=['s' de];
	end
	e2=[];
	gegs=mis;
	gegs.fullDataFile=datafilename;
end

function e = read_datafile(datafilename,blocksize,nChannel,nSamp	...
	,start,lengte,kanalen)

if rem(nSamp,blocksize)
	warning('FMTClxXMLread:notFullBlockRequested','!!!!number of samples not a whole number of blocks!!!!')
	nSamp=nSamp-rem(nSamp,blocksize);
end
start=max(start,0);
lengte=min(lengte,nSamp-start);

fid = fopen(datafilename,'r','ieee-be');
if fid<3
	error('Can''t open the datafile')
end

firstBlock=floor(start/blocksize);
offset=firstBlock*blocksize;
if offset>0
	fseek(fid,offset,'bof');
end
nBlocksToRead=ceil((start+lengte-1)/blocksize)-firstBlock;

e = fread(fid,blocksize*nChannel*nBlocksToRead,'double');
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
