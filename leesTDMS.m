function [e,varargout]=leesTDMS(fname,varargin)
%leesTDMS - Reads a labView TDMS-file
%    [e,ne,de,e2,gegs,D]=leesTDMS(fname[,iStart,maxLen,options])
%         or
%    [e,ne,de,e2,gegs,D]=leesTDMS(fname,options)
%        e : matrix of data (channels in columns)
%        ne : channel names
%        de : channel dimensions
%        e2 : empty (reserved for lower frequency data)
%       gegs : structure with info about the file
%       D : raw data (made for development of this function)
%
%    if no file-extension is given, tdms is assumed if file without
%            extension does not exist
%    opening of file is tried in current directory and in "zetev-directory"
%       (see 'help zetev' for more information)
%    options: pairs of name and values:
%       bConvBlockTime : makes "lvtimes" of timing data (default on
%           but can take a long time)
%       bCData : lv-time data in data-parts converted to lvtime object
%       bCProps : lv-time data in metadata-parts converted to lvtime object
%       bConvert : previous two together (all time data is converted to lvtime)
%       iStart, maxLen : also possible to input them as "options"
%       bReadIndex : normally index-files are not read (as main file) but
%           it is possible to do so.  No data will be read! only the
%           structure of the data is retrieved.
%       bLinChans : combines channel data to one column
%       iDecimateData : decimate data (while reading)
%           does not work for DAQmx-data!
%       decimMethod : a cell-vector, added to arguments of decimate
%       maxRawData : maximum number of data, any type
%       bDontStoreData : read data but don't store data
%              (to be used with fDataFunc)
%       bRawBlocks  : no conversion to measurement data
%                       [D,groups]=leesTDMS(...)
%       bStructured : structured output (groups, ...), same as
%                   bRawBlocks=-1
%       bReadAllNonChanData : if maximum length is given normally all data
%           is not read anymore; using this option non-channel data is
%           still being read
%       fDataFunc : function to process data while reading
%
%remark : iStart and maxLen are used, but only after reading(!) which means
%         that reading the file takes time and memory like reading the full
%         file!

iStart = [];
maxLen = [];
[bConvBlockTime, bScaleChans, bReadData] = deal(true);
[bConvert, bCData, bCProps, bReadIndex, bLinChans, bRawBlocks] = deal(false);
[bReadAllNonChanData, bDontStoreData, bOpenInBE, bTruncBlocks] = deal(false);
[bReadBrokenBlocks] = false;
[bStructured] = [];
iDecimateData = 1;
decimMethod = {};
nMaxD = 1e9;
nDStartData = 0;
nDStopData = 1e9;
maxRawData = 1e12;
nMaxObjects = 500;
[bAutoChannel] = nargout>1;
fDataFunc = [];
[bFixUnequalLengths] = false;
if nargin>1
	options=varargin;
	if isnumeric(options{1})
		iStart=options{1};
		options(1)=[];
		if nargin>2
			maxLen=options{1};
			options(1)=[];
		end
	end
	if ~isempty(options)
		setoptions({'bConvBlockTime','iStart','maxLen'	...
				,'bCData','bCProps','bConvert','bReadIndex'	...
				,'bLinChans','bRawBlocks','iDecimateData','decimMethod'	...
				,'nMaxD','nDStartData','nDStopData','nMaxObjects'	...
				,'bDontStoreData','bStructured','bAutoChannel'	...
				,'bReadAllNonChanData','bScaleChans','fDataFunc'	...
				,'maxRawData','bTruncBlocks','bReadBrokenBlocks','bReadData'	...
				,'bFixUnequalLengths'}	...
			,options{:})
		if ~isempty(bStructured)&&bStructured
			% do nothing
		elseif bRawBlocks<0
			bStructured=true;
		end
	end
end
if bConvert
	bCData=true;
	bCProps=true;
end
if isempty(iStart)
	iStart=0;
end
bDataProcess=~isempty(fDataFunc)&&isa(fDataFunc,'function_handle');
if isempty(maxLen)
	maxLen=1e9;
end
if isstruct(fname)&&isscalar(fname)
	if isfield(fname,'fullname')
		fname = fname.fullname;
	elseif isfield(fname,'folder')
		fname = fullfile(fname.folder,fname.name);
	else
		fname = fname.name;
	end
elseif isnumeric(fname)||~ischar(fname)
	if isscalar(fname)&&isnumeric(fname)
		fname=zetev({'*.tdms','sortd','file'},fname);
	else
		E=cell(length(fname),nargout);
		bCombine=nargout>1;
		cStat=cStatus('Reading multiple files',0);
		for i=1:length(fname)
			if iscell(fname)
				fname_i=fname{i};
			else
				fname_i=fname(i);
			end
			[E{i,:}]=leesTDMS(fname_i);
			if i>1&&nargout<1&&~isequal(E{1,2},E{i,2})
				warning('Not all measurements have equal elements!')
				bCombine=false;
			end		% if combinable
			cStat.status(i/length(fname))
		end		% for i
		cStat.close();
		if bCombine
			try
				e=cat(1,E{:,1});
				varargout=[E(1,2:min(nargout,5)) {E}];	% output: e,ne,de,e2,gegs,E
					% first 5 contain the data of the first file
			catch err
				DispErr(err,'Error while concatenating data!')
				e=E;
				varargout=cell(1,nargout-1);
			end
		elseif nargout==1
			e=E;
		else
			e=E(:,1);
			varargout=E(:,2:end);
		end
		return
	end
end
[~,~,fext]=fileparts(fname);
if isempty(fext)
	if exist(fname,'file')~=2&&exist(zetev([],fname),'file')~=2
		fname=[fname '.tdms'];
	end
elseif ~strcmpi(fext,'.tdms')
	warning('LEESTDMS:WRONGextension','This file expects files with extension ".tdms"!')
end
fid=fopen(fname);
if fid<3
	fname=fFullPath(fname);
	fid=fopen(fname);
	if fid<3
		error('Can''t open the file')
	end
end

tFactor=[1;cumprod(2^32*[1;1;1])]/2^64;
D=struct('version',cell(1,1000),'objects',[],'D',[],'ToC',[],'type',[]	...
	,'IDX',[],'idxChans',[],'idxGroups',[],'nVals',[],'isChanData',false	...
	,'bDAQmxData',[]);
nD=0;
t0=[];
dt=[];
itChan=0;
groups=struct('name',cell(1,1000),'idxD',[]	...
	,'properties',struct,'channel',[]);
nGroups=0;
nChan=0;
Rprops=struct;
numberedGroups=cell(0,2);
bCharDigit=false(1,255);
bCharDigit(abs('0123456789.'))=true;
DAQmxGroup=[];

dataTypeSizes=zeros(1,128);
dataTypeSizes([1 5 26 27 33])=1;
dataTypeSizes([2 6])=2;
dataTypeSizes([3 7 9])=4;
dataTypeSizes([4 10 11 25])=8;
dataTypeSizes(68)=16;
IDX=struct('tdsDataType',cell(1,64),'arrDim',[],'numValues',[]	...
	,'object',[],'chan',[],'group',[],'DAQmx',[]);
nIDX=0;	% initialization (normally not needed)

fseek(fid,0,'eof');
lFile=ftell(fid);
if bDataProcess
	fDataFunc('start',lFile,fid);
end

if lFile>1e6
	cStat=cStatus('Reading TDMS file',0);
else
	cStat=[];
end

fseek(fid,0,'bof');
bVersionWarning=false;
NdataTot=0;
NchanDataTot=0;
DoWarn init
while ~feof(fid)
	if nD>nMaxD
		break
	end
	x=fread(fid,[1 4],'*char');
	if length(x)<4
		break
	end
	if ~strcmp(x,'TDSm')
		if ~bReadIndex
			cCur=ftell(fid);
			if strcmp(x,'TDSh')
				warning('LEESTDMS:INDEXfileNoDATA','This is the index-file, without data----this function can only read the datafile.')
			else
				warning('LEESTDMS:WRONGstart','Wrong start for a TDMS-file-segment')
			end
			fprintf('reading is stopped (pos %d / %d)\n',cCur,lFile)
			break
		end
	end
	ToC=fread(fid,4,'uint8');ToC=ToC(1);	% to make it easy to use BE-files
	bMetaData=bitand(ToC,2)>0;
	bNewObjectList=bitand(ToC,4);
	bRawData=bitand(ToC,8);
	bInterleaved=bitand(ToC,32)>0;
	bBigEndian=bitand(ToC,64)>0;
	bDAQmxData=bitand(ToC,128)>0;
	if bBigEndian&&~bOpenInBE
		if nD>0
			fclose(fid);
			error('Can''t combine big and little endian blocks!')
		end
		bOpenInBE=true;
		cCur=ftell(fid);	% normally ==8
		fclose(fid);
		fid=fopen(fname,'r','ieee-be');
		fseek(fid,cCur,'bof');
	end
	nD=nD+1;
	if nD>length(D)
		D(nD+1000).ToC=[];
	end
	D(nD).ToC=ToC;
	D(nD).bDAQmxData=bDAQmxData;
	version=fread(fid,1,'uint32');
	if (version<4712||version>4713)&&~bVersionWarning
		bVersionWarning=true;
		warning('LEESTDMS:version','Unknown version (%d)',version)
	end
	D(nD).version=version;
	dNext=fread(fid,1,'int64');
	rawDoffset=fread(fid,1,'uint64');
	cCur=ftell(fid);
	if dNext==-1
		fNextPos=lFile;
	else
		fNextPos=cCur+dNext;
		if fNextPos>lFile
			warning('Indicated next position is beyond end of file!!! - broken file writing?')
			fNextPos=lFile;
		end
	end
	fDataPos=cCur+rawDoffset;
	if bMetaData	% metaData
		nObjects=fread(fid,1,'uint32');
		if nObjects>nMaxObjects
			warning('LEESTDMS:MAXobjects','Reading is stopped because nObjects is too big (%d objects)',nObjects);
			break
		end
		Objects=struct('name',cell(1,nObjects),'idxData',[]	...
			,'props',[],'group',[]);
		if bNewObjectList
			nIDX=0;
		end
		iG=-1;
		for iObject=1:nObjects
			Objects(iObject).name=readString(fid);
			sParts=objNameParts(Objects(iObject).name);
			iChannel=0;
			if isempty(sParts)
				iG=-1;
			else
				iG=0;
				iChannel=0;
				group=sParts{1};
				if bCharDigit(abs(group(end)))&&group(1)~='.'
					iC=find(~bCharDigit(abs(group)),1,'last');
					if isempty(iC)
						groupName='_';
						groupNumber=str2double(group);
					else
						groupName=group(1:iC);
						groupNumber=str2double(group(iC+1:end));
					end
					if isempty(numberedGroups)
						iG=nGroups+1;
						numberedGroups={groupName,[groupNumber iG]};
					else
						iG1=find(strcmp(groupName,numberedGroups(:,1)));
						if isempty(iG1)
							iG=nGroups+1;
							numberedGroups{end+1,1}=groupName;
							numberedGroups{end,2}=[groupNumber iG];
						else
							iG2=find(numberedGroups{iG1,2}(:,1)==groupNumber);
							if isempty(iG2)
								iG=nGroups+1;
								numberedGroups{iG1,2}(end+1,:)=[groupNumber iG];
							else
								iG=numberedGroups{iG1,2}(iG2,2);
							end
						end
					end
				end
				if iG==0
					if nGroups==0
						iG=1;
					else
						iG=find(strcmp(group,{groups(1:nGroups).name}));
						if isempty(iG)
							iG=nGroups+1;
						end
					end
				end		% if iG==0
				if iG>nGroups
					nGroups=iG;
					groups(iG).name=group;
				end
				Objects(iObject).group=iG;
				if length(sParts)>1	% channel
					channel=sParts{2};
					channels=groups(iG).channel;
					if isempty(channels)
						channels=struct('name',channel,'idx',[]	...
							,'properties',struct		...
							,'bIsChan',[]	...
							,'unit','-'	...
							,'dt',[]	...
							,'data',{{}});
						iChannel=1;
						nChan=nChan+1;
					else
						b=strcmp(channel,{channels.name});
						if any(b)
							iChannel=find(b);
						else
							channels(1,end+1).name=channel; %#ok<AGROW>
							iChannel=length(channels);
							nChan=nChan+1;
						end
					end
					groups(iG).channel=channels;
				end		% channel
			end		% at least group
			rdIdx=fread(fid,1,'int32');	%(defined to be uint32, but easier to test for -1)
			bIdx=false;
			Objects(iObject).idxData=rdIdx;
			if bDAQmxData&&length(sParts)>1&&rdIdx==version	% !!!!this is pure speculation --- no documentation found!!!!
				DAQmxGroup=group;
				verDAQ=rdIdx;
				rdIdx=fread(fid,1,'int32');	% ? toch datatype (-1 voor DAQmxData?)
				i1=fread(fid,1,'int32');	% arrDim? (==1)
				numValues=fread(fid,1,'uint64');
				idx_nBlocks=fread(fid,1,'int32');
				idx_Blocks=fread(fid,[5,idx_nBlocks],'int32')';
				%idxBlocks: [<type> 0 idx(0,2,..) 0 0]
				%      <type>: 3 int16, 5 int32
				i2=fread(fid,1,'int32');	% always 1?
				if i2~=1
					warning('i2 in DAQmx is not 1!')
				end
				idx_size=fread(fid,1,'int32');
				
				idxDAQmx=struct('verDAQ',verDAQ	...
					,'rd',rdIdx		... always -1(?)
					,'idx',idx_Blocks(:,3)'	...
					,'size',idx_size	...
					,'sig',idx_Blocks(:,5)'		...
					,'blocks',idx_Blocks(:,[2 4]));
				idx=struct('tdsDataType',idx_Blocks(:,1)','arrDim',i1	...
					,'numValues',numValues,'object',iObject		...
					,'chan',iChannel,'group',iG,'DAQmx',idxDAQmx);
				bIdx=true;
				groups(iG).channel(iChannel).idx=idx;
			elseif rdIdx==-1	% no raw data
				% do nothing
			elseif rdIdx==0	% matches previous segment
				idx=groups(iG).channel(iChannel).idx;
				bIdx=true;
			else
				if rdIdx<20
					fclose(fid);
					error('idx-data expected to be at least 20 bytes!')
				end
				tdsDataType=fread(fid,1,'int32');
				arrDim=fread(fid,1,'uint32');	% should be one
				numValues=fread(fid,1,'uint64');
				%for variable length data types (strings,...)
				%    totSizeBytes=fread(fid,1,'uint64');
				idx=struct('tdsDataType',tdsDataType,'arrDim',arrDim	...
					,'numValues',numValues,'object',iObject		...
					,'chan',iChannel,'group',iG,'DAQmx',[]);
				bIdx=true;
				groups(iG).channel(iChannel).idx=idx;
				if rdIdx>20
					if rem(rdIdx,4)
						idxExtra=fread(fid,[1 (rdIdx-20)/4],'*int32');
					else
						idxExtra=fread(fid,[1 rdIdx-20],'*uint8');
					end
					Objects(iObject).idxData={rdIdx idxExtra};
				end
			end
			if bIdx
				if bNewObjectList
					nIDX=nIDX+1;
					IDX(nIDX)=idx;
				else
					bIDX=[IDX(1:nIDX).group]==idx.group	...
						&[IDX(1:nIDX).chan]==idx.chan;
					if any(bIDX)
						IDX(bIDX).numValues=idx.numValues;
					else
						nIDX=nIDX+1;
						IDX(nIDX)=idx;
					end
				end
			end
			numProps=fread(fid,1,'int32');
			props=cell(numProps,2);
			bIsChan=false;
			for iProp=1:numProps
				name=readString(fid);
				dType=fread(fid,1,'int32');
				value=ReadData(fid,1,dType,bCProps);
				props{iProp,2}=name;
				props{iProp,1}=value;
				if strcmp(name,'wf_increment')
					if iDecimateData>1
						dt1=value*iDecimateData;
					else
						dt1=value;
					end
					if iChannel
						groups(iG).channel(iChannel).dt=dt1;
					end
					if isempty(dt)
						dt=dt1;
					else
						dt=unique([dt;dt1]);
					end
				elseif strcmp(name,'NI_ChannelName')
					bIsChan=true;
				elseif strcmp(name,'NI_UnitDescription')
					groups(iG).channel(iChannel).unit=value;
				end
			end	% for  iProp
			if numProps>0
				Objects(iObject).props=lvData2struct(props,'-bCreateArr');
				[groups,Rprops]=AddFields(Objects(iObject).props	...
					,groups,Rprops,iChannel,iG,fname);
			end
			if iChannel>0
				b=groups(iG).channel(iChannel).bIsChan;
				if isempty(b)
					b=bIsChan;
				else
					b=b|bIsChan;
				end
				groups(iG).channel(iChannel).bIsChan=b;
			end
			if bIdx&&iG>0
				if isempty(groups(iG).idxD)
					groups(iG).idxD=nD;
				elseif groups(iG).idxD(end)<nD
					groups(iG).idxD(1,end+1)=nD;
				end
			end
		end	% for iObject
		D(nD).IDX=IDX(1:nIDX);
		D(nD).objects=Objects;
	else	% no metadata
		groups(iG).idxD(1,end+1)=nD;
	end
	D(nD).idxChans=[IDX(1:nIDX).chan];
	D(nD).idxGroups=[IDX(1:nIDX).group];
	numVlist=[IDX(1:nIDX).numValues];
	D(nD).nVals=numVlist;
	D(nD).isChanData=false;
	cCur=ftell(fid);
	if cCur~=fDataPos
		fseek(fid,fDataPos,'bof');
	end
	if bRawData&&bDAQmxData	% rawData - DAQmx
		if fNextPos>fDataPos&&sum(numVlist)>0
			D(nD).type=[IDX.tdsDataType];
			nB1=IDX(1).DAQmx.size;
			nPt=floor((fNextPos-fDataPos)/nB1);
			if bReadData
				D1=fread(fid,[nB1 nPt],'*uint8');
				D(nD).D=cell(1,length(numVlist));
				%!!!!!!!!!!not correct in case of multiple signals for one channel!!!
				for iChan=1:length(numVlist)
					nSig=length(IDX(iChan).tdsDataType);
					D2=zeros(nPt,nSig);
					for iS=1:nSig
						switch IDX(iChan).tdsDataType(iS)
							case 2
								nB=2;
								sType='uint16';
							case 3
								nB=2;
								sType='int16';
							case 4	% guess!!!!
								nB = 4;
								sType='uint32';
							case 5
								nB=4;
								sType='int32';
							otherwise
								fclose(fid);
								error('Unknown type (%d) in DAQmx data',D(nD).type(iChan))
						end
						D2(:,iS)=typecast(reshape(	...
							D1(IDX(iChan).DAQmx.idx(iS)+(1:nB),:),nPt*nB,1),sType);
					end
					D(nD).D{iChan}=D2;
				end
				if bDataProcess
					fDataFunc('data',D(nD).D,nD,Objects);
				end
				if bDontStoreData
					D(nD).D=[];
				end
			else	% don't read data
				D(nD).D = struct('nB',nB1,'nPt',nPt,'numV',num2cell(numVlist));	% store data size
			end
		end
		cCur=ftell(fid);
		if fNextPos~=cCur
			fseek(fid,fNextPos,'bof');	% DAQmx-data not read well??
		end
	elseif bRawData && nIDX>0	% rawData
		tdsDataType={IDX(1:nIDX).tdsDataType};
		Nblocks=cellfun('length',tdsDataType);
		if any(Nblocks>1)
			fclose(fid);
			error('multiple data-blocks per channel is not yet forseen!')
		end
		tdsDataType=[tdsDataType{:}];
		D(nD).type=tdsDataType;
		if bReadData
			if ~all(tdsDataType==tdsDataType(1))
				D(nD).D=cell(1,length(tdsDataType));
				for iC=1:length(tdsDataType)
					D(nD).D{iC}=ReadData(fid,[numVlist(iC) 1],tdsDataType(iC),bCData);
				end
				cCur=ftell(fid);
				if fNextPos~=cCur
					warning('Multiple blocks not yet implemented in case of multiple types')
					fseek(fid,fNextPos,'bof');
				end
			else
				bLinData=false;
				if length(numVlist)>1
					if all(numVlist==numVlist(1))
						if bInterleaved
							%!!!!!not tested!!!!
							valSize=[length(numVlist) numVlist(1)];
						else
							valSize=[numVlist(1) length(numVlist)];
						end
					else
						bLinData=true;
						valSize=[sum(numVlist),1];
					end
				else
					valSize=numVlist;
				end
				nValTot=sum(numVlist);
				NdataTot=NdataTot+nValTot;
				if (NchanDataTot>=maxLen*nChan&&dataTypeSizes(tdsDataType(1))>0	...
						&&(~bReadAllNonChanData||D(nD).isChanData))	...
						||NdataTot>=maxRawData
					fseek(fid,dataTypeSizes(tdsDataType(1))*nValTot,'cof');
				else
					D(nD).D=ReadData(fid,valSize,tdsDataType(1),bCData);
				end
				if D(nD).isChanData
					NchanDataTot=NchanDataTot+nValTot;
				end
				if bInterleaved&&~isempty(D(nD).D)		% OK?
					D(nD).D=D(nD).D';
				end
				if bDataProcess
					fDataFunc('data',D(nD).D,nD,Objects);
				end
				if bDontStoreData
					D(nD).D=[];
				end
				cCur=ftell(fid);
				if fNextPos~=cCur
					nBlocks=(fNextPos-cCur)/(cCur-fDataPos)+1;
					bSeek=false;
					bReadPart=false;
					if bTruncBlocks&&floor(nBlocks)<nBlocks
						if ~bReadBrokenBlocks
							warning('#blocks truncated! (%.3f --> %d)',nBlocks,floor(nBlocks))
						end
						nBlocks=floor(nBlocks);
						bSeek=true;
						bReadPart=bReadBrokenBlocks;
						%(!) in case of bInterleaved ==> still readable blocks!
					end
					if nBlocks<=1||round(nBlocks)~=nBlocks
						warning('LEESTDMS:MISSEDdata','!!?missed data - wrong position in file : %d <-> %d (%d)'	...
							,cCur,fNextPos,fNextPos-cCur)
						bSeek=true;
					elseif nValTot>0	%&&~bInterleaved
						if (nChan>0&&NchanDataTot>=maxLen*nChan&&dataTypeSizes(tdsDataType(1))>0)	...
								||NdataTot>=maxRawData	% skip data
							if D(nD).isChanData
								NchanDataTot=NchanDataTot+(nBlocks-1)*nValTot;
							end
							NdataTot=NdataTot+(nBlocks-1)*nValTot;
							fseek(fid,(nBlocks-1)*dataTypeSizes(tdsDataType(1))*nValTot,'cof');
						else	% don't skip data
							if ~bDontStoreData
								% reserve memory
								if bLinData
									D(nD).D(1,min([nBlocks,maxRawData,maxLen]))=0;
								else
									D(nD).D(min([numVlist(1)*nBlocks,maxRawData,maxLen]),1)=0;
								end
							end
							for iB=2:nBlocks
								iBi=(iB-1)*numVlist(1)+1:iB*numVlist(1);
								D1=ReadData(fid,valSize,tdsDataType(1),bCData);
								if bInterleaved
									D1=D1';
								end
								if ~bDontStoreData&&iBi(end)<=size(D(nD).D,1)
									if numel(D1)<prod(valSize)
										warning('??!broken TDMS-file??!')
										D1(valSize(1),1)=0;
									end
									if bLinData
										D(nD).D(:,iBi)=D1;
									else
										D(nD).D(iBi,:)=D1;
									end
								end
								if bDataProcess
									fDataFunc('data',D1,nD,Objects);
								end
							end		% for iB
						end		% not if skip data
					end		% if nBlocks>1
					if bReadPart
						warning('Part of block is read, but with very temporary solution!!!!!!')
						valSize(2)=(fNextPos-ftell(fid))/8/valSize(1);	%!!!!!!!!!!!
						D1=ReadData(fid,valSize,tdsDataType(1),bCData);
						if bInterleaved
							D1=D1';
						end
						%iBi=nBlocks*valSize(2)+1:nBlocks*valSize(2)+size(D1,2);
						D(nD).D=[D(nD).D;D1];
					end
					if bSeek
						fseek(fid,fNextPos,'bof');
					end
				end		% if multiple data blocks
				if bLinData		% restructure data(?!)
				end
				if nD>nDStopData||nD<nDStartData
					D(nD).D=[];
				else
					if iDecimateData>1&&bIsChan
						DD=D(nD).D;
						nC=size(DD,2);
						if iscell(decimMethod)
							if ~isa(DD,'double')
								DD=double(DD);
							end
							D(nD).D=decimate(DD(:,1),iDecimateData,decimMethod{:});
							if nC>1
								D(nD).D(1,nC)=0;
								for ii=2:nC
									D(nD).D(:,ii)=decimate(DD(:,ii),iDecimateData,decimMethod{:});
								end
							end
						else
							fclose(fid);
							error('unknown (or not-yet-implemented) decimation method')
						end
					end
					if tdsDataType(1)==68&&numVlist(1)>0	% timestamp
						if isempty(t0)
							if D(nD).isChanData
								itChan=chanNr;
							else
								itChan=-nD;
							end
							if isnumeric(D(nD).D)
								t0=D(nD).D(1,:);
								if ~isa(t0,'double')
									t0=double(t0);
								end
							else
								t0=lvtime(D(nD).D(1));
							end
						end
						if isnumeric(D(nD).D)
							D1=D(nD).D;
							nD1=size(D1,1);
							if ~isa(D1,'double')
								D1=double(D1);
							end
							D1=D1-t0(ones(1,nD1),:);
							D(nD).D=D1*tFactor;
						else
							D(nD).D=D(nD).D-t0;
						end
					end
				end		% hold data
			end		% single data type
		else	% don't read data
			szBlock = BlockSize(numVlist,tdsDataType);
			nBlocks = floor((fNextPos-cCur)/szBlock);
			nPt = numVlist*nBlocks;
			D(nD).D = struct('numV',num2cell(numVlist),'nPt',num2cell(nPt));
			fseek(fid,fNextPos,'bof');
		end
	end		% if rawData
	if ~isempty(cStat)
		cStat.status(cCur/lFile)
	end
end		% while ~feof
if fid
	fclose(fid);
end
if ~isempty(cStat)
	cStat.close();
end
if bDataProcess
	fDataFunc('end');
end
D=D(1:nD);
groups=groups(1:nGroups);

Dstruct=struct('group',groups,'properties',Rprops,'version',D(1).version);
for iG=1:nGroups
	groups(iG).nBlocks=zeros(1,length(groups(iG).channel));
	for iC=1:length(groups(iG).channel)
		groups(iG).channel(iC).data=cell(1,length(groups(iG).idxD));
	end
end
for iD=1:nD
	id=0;
	bLoop = true;
	bAdd = false;
	while bLoop && id<size(D(iD).D,1)
		% !!!!!!!!!!!!!!!!!!!!!!!
		% this loop (while bLoop ...) is added to solve a problem of not
		% correctly using all data of a block
		% This is not optimal!!!!
		% !!!!!!!!!!!!!!!!!!!!!!!
		for iS=1:length(D(iD).idxChans)
			iG=D(iD).idxGroups(iS);
			iC=D(iD).idxChans(iS);
			if bAdd
				iB=groups(iG).nBlocks(iC);
			else
				iB=groups(iG).nBlocks(iC)+1;
				groups(iG).nBlocks(iC)=iB;
			end
			if D(iD).nVals(iS)
				if iscell(D(iD).D)
					D1=D(iD).D{iS};
					bLoop = false;
				elseif isstruct(D(iD).D)	% (currently) only if ~bReadData
					D1 = D(iD).D;
					if ~isscalar(D1) && iS<=length(D1)
						D1 = D1(iS);
					end
					bLoop = false;
				elseif size(D(iD).D,2)>1||nChan==1	%!!nChan==1 added!!
					D1=D(iD).D(:,iS);
					bLoop = false;
				else
					%!!!!interleaved data!!!! --- is this possible?
					idn=id+D(iD).nVals(iS);
					if idn>length(D(iD).D)
						idn = length(D(iD).D);
					end
					D1=D(iD).D(id+1:idn);
					id=idn;
				end
				if bAdd
					groups(iG).channel(iC).data{iB} = [groups(iG).channel(iC).data{iB};D1];
				else
					groups(iG).channel(iC).data{iB} = D1;
				end
			end
		end		% for iS
		bAdd = true;
	end %	while still data to add
end		% for iD
for iG=1:nGroups
	channels=groups(iG).channel;
	for iC=1:length(channels)
		if bReadData
			channels(iC).nData=cellfun('size',channels(iC).data,1);
			channels(iC).data=cat(1,channels(iC).data{:});
			if bScaleChans&&isfield(channels,'properties')	...
					&&isfield(channels(iC).properties,'NI_Scaling_Status')	...
					&&strcmp(channels(iC).properties.NI_Scaling_Status,'unscaled')
				try
					channels(iC).data=ScaleNIdata(channels(iC));
					channels(iC).properties.NI_Scaling_Status='scaled';
				catch err
					DispErr(err)
					warning('LEESTDMS:scalingError','Error in scaling data!')
				end
			end
		else
			nData = 0;
			for i = 1:length(channels(iC).data)
				if isstruct(channels(iC).data{i})
					nData = nData+channels(iC).data{i}.nPt;
				end
			end		% for i
			channels(iC).nData = nData;
		end %	 don't read data
	end		% for iC
	Dstruct.group(iG).channel=channels;
	groups(iG).channel=channels;
end		% for iG
chanInfo=[];
if bStructured
	e=Dstruct;
	return
elseif bRawBlocks
	e=D;
	if nargout>1
		varargout={groups,Dstruct};
		if nargout>3
			warning('LEESTDMS:RAWoneOut','With rawBlocks only two outputs!')
			varargout{nargout-1}=[];
		end
	end
	DoWarn exit
	return
else	% get measurement data from channels
	if bAutoChannel&&nGroups==1&&~isempty(groups.channel)
		nData=cellfun('length',{groups.channel.data});
		if isscalar(nData)||all(nData==nData(1))
			% force channels to be "channel"
			for i=1:length(Dstruct.group.channel)
				Dstruct.group.channel(i).bIsChan=true;
			end
		end
	end
	channels=cell(1,nGroups);
	for iG=1:nGroups
		if ~isempty(Dstruct.group(iG).channel)
			channels{iG}=Dstruct.group(iG).channel([Dstruct.group(iG).channel.bIsChan]);
		end
	end
	if isempty(channels)
		chanNames={};
		nChan=0;
		de={};
		chanData={};
	else
% 		if any(cellfun(@isempty,channels))
% 			if length(channels)>1
% 				warning('Combining empty channels??')
% 			end
% 		end
		channels=[channels{:}];
		chanNames={channels.name};
		nChan=length(channels);
		if bLinChans
			uChanNames=unique(chanNames);
			if length(uChanNames)<nChan
				nChan=length(uChanNames);
				iChan=zeros(1,nChan);
				for i=1:nChan
					bC=strcmp(uChanNames{i},chanNames);
					iChan(i)=find(bC,1);
					channels(iChan(i)).data=cat(1,channels(bC).data);
				end
				channels=channels(iChan);
			end
			chanNames=uChanNames;
		end
		if isempty(dt)
			dt=[channels.dt];
		end
		de={channels.unit};
		chanData={channels.data};
	end
end
nData=cellfun('length',chanData);
DoWarn exit
if nargout>7
	warning('LEESTDMS:TOOmuchARGUMENTS','Too much output arguments ---- last arguments are empty')
end
varargout=cell(1,nargout-1);
unData=unique(nData);
if bFixUnequalLengths
	if length(unData)>1
		if unData(end)/unData(1)<1.001
			warning('Almost the same number of signal data - should be combined')
		elseif length(unData)>2
			n1 = unData(1);
			n2 = unData(end);
			rn2 = n2./unData;
			if all(unData/n1<1.002 | rn2<1.001)
				bN1 = unData/n1<1.001;
				bN2 = ~bN1 & rn2<1.001;
				warning('Two sets of signals could be made out of signals with %d number of lengths!',length(unData))
			end
		end
	end
end
if ~bReadData
	e = [];
elseif any([D.bDAQmxData])
	% only DAQmx channels!
	iG=find(strcmp(DAQmxGroup,{Dstruct.group.name}));
	if length(iG)~=1
		warning('LEESTDMS:badDAQMXgroups','Unexpected results when processing DAQmx-data')
		chanData=chanData(~cellfun(@isempty,chanData));
		e=CombineChanData(chanData);
	else
		try
			e=[Dstruct.group(iG).channel.data];
		catch err
			e={Dstruct.group(iG).channel.data};
			DispErr(err,'An error occured while combining data to one block!')
		end
	end
elseif length(unData)==1
	if iStart>0
		for i=1:nChan
			chanData{i}(1:iStart,:)=[];
		end
	end
	for i=1:nChan
		if nData(i)>maxLen
			chanData{i}(maxLen+1:end,:)=[];
		end
	end
	e=CombineChanData(chanData);
elseif length(unData)==2&&length(nData)==nChan
	iHSchan=find(nData==unData(2));	% longest (probably fastest) data
	if iStart>0
		for i=iHSchan
			chanData{i}(1:iStart)=[];
			nData(i)=nData(i)-iStart;
		end
	end
	for i=1:nChan
		if nData(i)>maxLen
			chanData{i}(maxLen+1:end)=[];
		end
	end
	e=CombineChanData(chanData(iHSchan));
	varargout{3}=cat(2,chanData{nData==unData(1)});	% shortest data
	dt=[min(dt) max(dt)];
	chanNames=chanNames([iHSchan setdiff(1:nChan,iHSchan)]);
	de=de([iHSchan setdiff(1:nChan,iHSchan)]);
elseif ~isempty(chanData)||nargout>1
	e=chanData;
else
	e=D;	% is this a risk?
end
if nargout>1
	varargout{1}=chanNames;
	if nargout>2
		varargout{2}=de;
		if nargout>4
			if isnumeric(t0)&&length(t0)==4
				t0=lvtime(t0,true);
			end
			if bConvBlockTime
				T=gettimes(D);
			else
				T=[];
			end
			if isempty(t0)&&~isempty(T)
				t0=T(1);
			end
			if ~isempty(channels)
				chanInfo=rmfield(channels,'data');
			end
			udt=unique(dt);
			if isscalar(udt)
				dt=udt;
			elseif (max(dt)-min(dt))/mean(dt)<1e-15
				warning('(?!)Very small difference between min/max sampling time! (%g%%)'	...
					,(max(dt)-min(dt))/mean(dt)*100)
				dt=mean(dt);
			end
			varargout{4}=struct('version',D(1).version	...
				,'measInfo',Rprops		...
				,'chanInfo',chanInfo	...
				,'t0',t0,'dt',dt,'itChan',itChan	...
				,'tBlocks',T,'groups',groups	...
				,'nData',max(nData)	...
				);
			if nargout>5
				varargout{5}=D;
				if nargout>6
					varargout{6}=Dstruct;
				end
			end
		end
	end
end

function D=CombineChanData(C)
if length(C)==1
	D=C{1};
else
	cC=C;
	for i=1:length(C)
		cC{i}=class(C{i});
	end
	if length(unique(cC))>1
		for i=1:length(C)
			C{i}=double(C{i});
		end
	end
	D=cat(2,C{:});
end

function s=readString(fid)
l=fread(fid,1,'int32');
if l<=0
	s='';
	if l<0
		warning('LEESTDMS:NEGATIVEstringLENGTH','!!!!!only positive string lengths are possible')
	end
else
	s=fread(fid,[1 l],'*char');
end

function value=ReadData(fid,siz,dType,bConvert)
% see also readLVtypeString
bToDouble=false;
if ~isscalar(dType)
	fclose(fid);
	error('Something is going wrong with type?!')
end
if dType>255
	% is 3rd byte the size (in bytes) of one element?
	%warning('Type $%08x?!',dType)
	dType=bitand(dType,255);
end
switch dType
	case 0
		% void
		value=[];
	case 1
		value=fread(fid,siz,'*int8');
		bToDouble=true;
	case 2
		value=fread(fid,siz,'*int16');
		bToDouble=true;
	case 3
		value=fread(fid,siz,'*int32');
		bToDouble=true;
	case 4
		value=fread(fid,siz,'*int64');
		bToDouble=true;
	case 5
		value=fread(fid,siz,'*uint8');
		bToDouble=true;
	case 6
		value=fread(fid,siz,'*uint16');
		bToDouble=true;
	case 7
		value=fread(fid,siz,'*uint32');
		bToDouble=true;
	case 8
		value=fread(fid,siz,'*uint64');
		bToDouble=true;
	case 9
		value=fread(fid,siz,'*single');
		bToDouble=true;
	case 10
		value=fread(fid,siz,'double');
	case 11
		value=fread(fid,[16 prod(siz)],'uint8');	%   !!!extended
		zS=floor(value(1,:)/128);
		zE=rem(value(1,:),128)*256+data(2);
		zM=[72057594037927936,281474976710656,1099511627776,4294967296,16777216,65536,256,1]	...
			*value(10:-1:3,:)/2^64+1;
		value=reshape((-1)^zS*zM*2^(zE-16383),siz(1),siz(2));
	case 12
		value=fread(fid,[2,prod(siz)],'single');
		value=value(1,:)+1i*value(2,:);
		value=reshape(value,siz);
	case 13
		value=fread(fid,[2,prod(siz)],'double');
		value=value(1,:)+1i*value(2,:);
		value=reshape(value,siz);
	case 14		% !!!! extended !!!!
		value=fread(fid,[2,prod(siz)],'single');
		value=value(1,:)+1i*value(2,:);
		value=reshape(value,siz);
	case 25	% single with unit!!!!!!!!
		value=fread(fid,siz,'double');
	case 26	% double with unit!!!!!!
		value=fread(fid,siz,'*int8');
		bToDouble=true;
	case 27	% extFloat with unit!!!!!!
		value=fread(fid,siz,'*int8');
		bToDouble=true;
	case 32	% string
		if prod(siz)==1
			value=readString(fid);
		else
			if isscalar(siz)
				siz=[1 siz];
			end
			value=cell(siz);
			nB=fread(fid,siz,'uint32');
			s=fread(fid,[1 nB(end)],'*char');
			iL=0;
			for iS=1:prod(siz)
				value{iS}=s(iL+1:nB(iS));
				iL=nB(iS);
			end
		end
	case 33	% boolean
		value=fread(fid,siz,'*int8');
		bToDouble=true;
	case 68	% timestamp
		bReshape = false;
		if length(siz)==2
			if siz(1)~=1
				bReshape = true;
				sizOrig = siz;
				siz = [4 prod(siz)];
				%fclose(fid);
				%error('reading timestamps is only implemented for vectors, not for arrays')
			else
				siz(1)=4;
			end
		else
			siz=[4 siz];
		end
		value=fread(fid,siz,'*uint32')';
			% better to read it as uint8 to avoid problems with endian!
		if bConvert
			value=lvtime(value,true);
			if bReshape
				value = reshape(value,sizOrig);
			end
		elseif bReshape
			value = reshape(value,[4 sizOrig]);
		end
	otherwise
		fclose(fid);
		error('Unknown data type (%d)!!!',dType)
end
if bToDouble&&numel(value)<5
	value=double(value);
end

function sz = BlockSize(siz,dTypes)
% Calculate the size of one block (to determine number of blocks saved
%   without reading the data)

S = zeros(1,length(dTypes));
for i=1:length(dTypes)
	dType = dTypes(i);
	if dType>255
		% is 3rd byte the size (in bytes) of one element?
		%warning('Type $%08x?!',dType)
		dType=bitand(dType,255);
	end
	switch dType
		case {0}
			S(i) = 0;
		case {1,5,33}		% (u)int8, boolean
			S(i) = 1;
		case {2,6}		% (u)int16
			S(i) = 2;
		case {3,7,9}	% (u)int32, single
			S(i) = 4;
		case {4,8,10,12,25}	% (u)int64, double, single complex
			S(i) = 8;
		case {11,13,68}	% extended, double complex, timestamp
			S(i) = 16;
		case 14		% extended complex
			S(i) = 32;
	end
	S(i) = S(i)*siz(i);
end
sz = sum(S);

function t=gettimes(D)
% function to retrieve times of TDMS-blocks
%    t=gettimes(D)
t=[];
try
	t=lvtime([0 0 0 0]);
	t=t(ones(1,length(D)));
	B=false(1,length(D));
	for iD=1:length(D)
		b=false;
		O=D(iD).objects;
		for iO=1:length(O)
			O1=O(iO);
			if isfield(O1.props,'wf_start_time')
				t1=O1.props.wf_start_time;
				b=~isempty(t1)&&any(t1~=0);
				if b
					break
				end
			end
			if ~b&&isfield(O1.props,'NI_ExpTimeStamp')
				t1=O1.props.NI_ExpTimeStamp;
				b=true;
				break;
			end
		end
		B(iD)=b;
		if b
			if isnumeric(t1)
				t(iD)=lvtime(t1,true);
			else
				t(iD)=t1;
			end
		end
	end
	t=t(B);
catch err
	DispErr(err,'problem with reading NI_ExpTimeStamp')
end

function sParts=objNameParts(s)
if length(s)==1
	sParts={};
	return
end
sParts=cell(1,sum(s=='/'));
nP=0;
i=1;
while i<length(s)
	if s(i)=='/'
		i=i+1;
		if s(i)~=''''
			warning('LEESTDMS:WRONGaccentsOBJECTNAME','wrong use of "''" in object name')
			return
		end
		i=i+1;
		i0=i;
		while s(i)~=''''
			if s(i)=='\'
				i=i+1;
			end
			i=i+1;
		end
		nP=nP+1;
		sParts{nP}=s(i0:i-1);
		i=i+1;
	else
		warning('LEESTDMS:CHARobjectName','unexpected character in object name')
		break
	end
end

function [groups,Rprops]=AddFields(props,groups,Rprops,iChannel,iG,fname)
fn=fieldnames(props);
for i=1:length(fn)
	fni=fn{i};
	value=props.(fni);
	if iChannel>0
		if isfield(groups(iG).channel(iChannel).properties		...
				,fni)
			DoWarn('overwritten','channel',fni,fname)
		end
		groups(iG).channel(iChannel).properties.(fni)=value;
	elseif iG>0
		if isfield(groups(iG).properties		...
				,fni)
			DoWarn('overwritten','group',fni,fname)
		end
		groups(iG).properties.(fni)=value;
	else
		if isfield(Rprops,fni)
			DoWarn('overwritten','root',fni,fname)
		end
		Rprops.(fni)=value;
	end
end		% for i

function DoWarn(warnType,warnLevel,warnData,fName)
persistent WARNlist

switch warnType
	case 'init'
		WARNlist=[];
	case 'overwritten'
		i=[];
		if isempty(WARNlist)
			WARNlist=struct(warnLevel,{{warnData;1}});
		elseif ~isfield(WARNlist,warnLevel)
			WARNlist.(warnLevel)={warnData;1};
		else
			i=find(strcmp(warnData,WARNlist.(warnLevel)(1,:)));
			if isempty(i)
				WARNlist.(warnLevel){1,end+1}=warnData;
				WARNlist.(warnLevel){2,end}=1;
			else
				WARNlist.(warnLevel){2,i}=WARNlist.(warnLevel){2,i}+1;
			end
		end
		switch warnLevel
			case 'root'
				if isempty(i)
					warning('LEESTDMS:ROOToverwritten'	...
						,'root property "%s" is overwritten! (%s)'	...
						,warnData,fName)
				end
			case 'group'
				if isempty(i)
					warning('LEESTDMS:GROUPoverwritten'	...
						,'group property "%s" is overwritten! (%s)'	...
						,warnData,fName)
				end
			case 'channel'
				if isempty(i)
					warning('LEESTDMS:CHANNELoverwritten'	...
						,'channel property "%s" is overwritten! (%s)'	...
						,warnData,fName)
				end
			otherwise
				error('Wrong use of this function')
		end
	case 'exit'
		if ~isempty(WARNlist)
			fn=fieldnames(WARNlist);
			for i=1:length(fn)
				L=WARNlist.(fn{i});
				for j=1:size(L,2)
					if L{2,j}>1
						fprintf('%s property %-15s overwritten %d times\n'	...
							,fn{i},L{1:2,j})
					end
				end
			end
		end
	otherwise
		error('Wrong use of this function')
end
