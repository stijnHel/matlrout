function [e,varargout]=leesTDMSfast(fname,varargin)
%leesTDMSfast - Reads a labView TDMS-file - faster implementation not finished
%    [e,ne,de,e2,gegs,D]=leesTDMSfast(fname[,iStart,maxLen,options])
%         or
%    [e,ne,de,e2,gegs,D]=leesTDMSfast(fname,options)
%        e : matrix of data (channels in columns)
%        ne : channel names
%        de : channel dimensions
%        e2 : empty (reserved for lower frequency data)
%       gegs : structure with info about the file
%       D : raw data (made for development of this function)
%
%  more info, see leesTDMS
%
% until now, only reading is replaced by reading full file, and then
% extracting, but the idea is to group more, so that things can be done
% more efficient

iStart=[];
maxLen=[];
bConvBlockTime=true;
bConvert=false;
bCData=false;
bCProps=false;
bReadIndex=false;
bLinChans=false;
bRawBlocks=false;
bStructured=[];
iDecimateData=1;
decimMethod={};
nMaxD=1e9;
nDStartData=0;
nDStopData=1e9;
maxRawData=1e12;
nMaxObjects=500;
bReadAllNonChanData=false;
bDontStoreData=false;
bAutoChannel=nargout>1;
bScaleChans=true;
bTruncBlocks=false;
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
				,'bReadAllNonChanData','bScaleChans'	...
				,'maxRawData','bTruncBlocks'}	...
			,options{:})
		if ~isempty(bStructured)&&bStructured %#ok<BDSCI,BDLGI>
			% do nothing
		elseif bRawBlocks<0
			bStructured=true;
		end
	end
end
if bConvert
	bCData=true; %#ok<UNRCH>
	bCProps=true;
end
if isempty(iStart)
	iStart=0;
end
if isempty(maxLen)
	maxLen=1e9;
end
if isstruct(fname)&&isscalar(fname)
	fname=fname.name;
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
			[E{i,:}]=leesTDMSfast(fname_i);
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
fid=fopen(fFullPath(fname));
Xtdms=fread(fid,[1 maxLen],'*uint8');
if ~feof(fid)
	warning('Not read until the end!!!')
end
fclose(fid);

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

lFile=length(Xtdms);

if lFile>1e6
	cStat=cStatus('Reading TDMS file',0);
else
	cStat=[];
end

ix = 0;
bVersionWarning=false;
NdataTot=0;
NchanDataTot=0;
DoWarn init
while ix+20<lFile&&nD<nMaxD
	x=char(Xtdms(ix+1:ix+4));ix=ix+4;
	if ~strcmp(x,'TDSm')
		if ~bReadIndex
			if strcmp(x,'TDSh')
				warning('LEESTDMS:INDEXfileNoDATA','This is the index-file, without data----this function can only read the datafile.')
			else
				warning('LEESTDMS:WRONGstart','Wrong start for a TDMS-file-segment')
			end
			fprintf('reading is stopped (pos %d / %d)\n',ix,lFile)
			break
		end
	end
	ToC=Xtdms(ix+1);ix=ix+4;
	bMetaData=bitand(ToC,2)>0;
	bNewObjectList=bitand(ToC,4);
	bRawData=bitand(ToC,8);
	bInterleaved=bitand(ToC,32)>0;
	bBigEndian=bitand(ToC,64)>0;
	bDAQmxData=bitand(ToC,128)>0;
	nD=nD+1;
	if nD>length(D)
		nTotalEstim = ceil((nD-1)/double(ix)*lFile);
		D(max(nD+1000,nTotalEstim)).ToC=[];
	end
	D(nD).ToC=ToC;
	D(nD).bDAQmxData=bDAQmxData;
	version=typecast(Xtdms(ix+1:ix+4),'uint32');ix=ix+4;
	if (version<4712||version>4713)&&~bVersionWarning
		bVersionWarning=true;
		warning('LEESTDMS:version','Unknown version (%d)',version)
	end
	D(nD).version=version;
	dNext=typecast(Xtdms(ix+1:ix+8),'int64');ix=ix+8;
	rawDoffset=typecast(Xtdms(ix+1:ix+8),'int64');ix=ix+8;
	if dNext==-1
		fNextPos=lFile;
	else
		fNextPos=ix+dNext;
	end
	fDataPos=ix+rawDoffset;
	if bMetaData	% metaData
		nObjects=typecast(Xtdms(ix+1:ix+4),'uint32');ix=ix+4;
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
			[Objects(iObject).name,ix]=readString(Xtdms,ix);
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
			rdIdx=typecast(Xtdms(ix+1:ix+4),'int32');	%(defined to be uint32, but easier to test for -1)
			ix=ix+4;
			bIdx=false;
			Objects(iObject).idxData=rdIdx;
			if bDAQmxData&&length(sParts)>1&&rdIdx==version	% !!!!this is pure speculation --- no documentation found!!!!
				DAQmxGroup=group;
				verDAQ=rdIdx;
				rdIdx=typecast(Xtdms(ix+1:ix+4),'int32');	% ? toch datatype (-1 voor DAQmxData?)
				i1=typecast(Xtdms(ix+5:ix+8),'int32');	% arrDim? (==1)
				numValues=typecast(Xtdms(ix+9:ix+16),'uint64');
				idx_nBlocks=typecast(Xtdms(ix+17:ix+20),'int32');ix=ix+20;
				ixn=ix+4*5*idx_nBlocks;
				idx_Blocks=reshape(typecast(Xtdms(ix+1:ixn),'int32'),5,idx_nBlocks)';
				ix=ixn;
				%idxBlocks: [<type> 0 idx(0,2,..) 0 0]
				%      <type>: 3 int16, 5 int32
				i2=typecast(Xtdms(ix+1:ix+4),'int32');	% always 1?
				ix=ix+4;
				if i2~=1
					warning('i2 in DAQmx is not 1!')
				end
				idx_size=typecast(Xtdms(ix+1:ix+4),'int32');ix=ix+4;
				
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
					error('idx-data expected to be at least 20 bytes!')
				end
				tdsDataType=typecast(Xtdms(ix+1:ix+4),'int32');
				arrDim=typecast(Xtdms(ix+5:ix+8),'uint32');% should be one
				numValues=typecast(Xtdms(ix+9:ix+16),'uint64');ix=ix+16;
				idx=struct('tdsDataType',tdsDataType,'arrDim',arrDim	...
					,'numValues',numValues,'object',iObject		...
					,'chan',iChannel,'group',iG,'DAQmx',[]);
				bIdx=true;
				groups(iG).channel(iChannel).idx=idx;
				if rdIdx>20
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
			numProps=typecast(Xtdms(ix+1:ix+4),'int32');ix=ix+4;
			props=cell(numProps,2);
			bIsChan=false;
			for iProp=1:numProps
				[name,ix]=readString(Xtdms,ix);
				dType=typecast(Xtdms(ix+1:ix+4),'int32');ix=ix+4;
				[value,ix]=ReadData(Xtdms,ix,1,dType,bCProps);
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
				Objects(iObject).props=lvData2struct(props);
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
	ix=fDataPos;
	if bRawData&&bDAQmxData	% rawData
		if fNextPos>fDataPos&&sum(numVlist)>0
			D(nD).type=[IDX.tdsDataType];
			%if bInterleaved	---- not used anymore!!!!
			nB1=IDX(1).DAQmx.size;
			nPt=floor((fNextPos-fDataPos)/nB1);
			ixn=ix+nB1*nPt;
			D1=reshape(Xtdms(ix+1:ixn),nB1,nPt);
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
						case 5
							nB=4;
							sType='int32';
						otherwise
							error('Unknown type (%d) in DAQmx data',D(nD).type(iChan))
					end
					D2(:,iS)=typecast(reshape(	...
						D1(IDX(iChan).DAQmx.idx(iS)+(1:nB),:),nPt*nB,1),sType);
				end
				D(nD).D{iChan}=D2;
			end
			if bDontStoreData
				D(nD).D=[];
			end
		end
		ix=fNextPos;	% DAQmx-data not read well??
	elseif bRawData	% rawData
		tdsDataType={IDX(1:nIDX).tdsDataType};
		Nblocks=cellfun('length',tdsDataType);
		if any(Nblocks>1)
			error('multiple data-blocks per channel is not yet forseen!')
		end
		tdsDataType=[tdsDataType{:}];
		D(nD).type=tdsDataType;
		if ~all(tdsDataType==tdsDataType(1))
			D(nD).D=cell(1,length(tdsDataType));
			for iC=1:length(tdsDataType)
				[D(nD).D{iC},ix]=ReadData(Xtdms,ix,[numVlist(iC) 1],tdsDataType(iC),bCData);
			end
			if fNextPos~=ix
				warning('Multiple blocks not yet implemented in case of multiple types')
				ix=fNextPos;
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
				ix=ix+dataTypeSizes(tdsDataType(1))*nValTot;
			else
				[D(nD).D,ix]=ReadData(Xtdms,ix,valSize,tdsDataType(1),bCData);
			end
			if D(nD).isChanData
				NchanDataTot=NchanDataTot+nValTot;
			end
			if bInterleaved&&~isempty(D(nD).D)		% OK?
				D(nD).D=D(nD).D';
			end
			if bDontStoreData
				D(nD).D=[]; %#ok<UNRCH>
			end
			if fNextPos~=ix
				nBlocks=double(fNextPos-ix)/double(ix-fDataPos)+1;
				bSeek=false;
				if bTruncBlocks&&floor(nBlocks)<nBlocks
					warning('#blocks truncated! (%.3f --> %d)',nBlocks,floor(nBlocks))
					nBlocks=floor(nBlocks);
					bSeek=true;
					%(!) in case of bInterleaved ==> still readable blocks!
				end
				if nBlocks<=1||round(nBlocks)~=nBlocks
					warning('LEESTDMS:MISSEDdata','!!?missed data - wrong position in file : %d <-> %d (%d)'	...
						,ix,fNextPos,fNextPos-ix)
					bSeek=true;
				elseif nValTot>0	%&&~bInterleaved
					if (nChan>0&&NchanDataTot>=maxLen*nChan&&dataTypeSizes(tdsDataType(1))>0)	...
							||NdataTot>=maxRawData	% skip data
						if D(nD).isChanData
							NchanDataTot=NchanDataTot+(nBlocks-1)*nValTot;
						end
						NdataTot=NdataTot+(nBlocks-1)*nValTot;
						ix=ix+(nBlocks-1)*dataTypeSizes(tdsDataType(1))*nValTot;
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
							[D1,ix]=ReadData(Xtdms,ix,valSize,tdsDataType(1),bCData);
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
						end		% for iB
					end		% not if skip data
				end		% if nBlocks>1
				if bSeek
					ix=fNextPos;
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
	end		% if rawData
	if ~isempty(cStat)
		cStat.status(double(ix)/lFile)
	end
end		% while ~feof
if ~isempty(cStat)
	cStat.close();
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
	for iS=1:length(D(iD).idxChans)
		iG=D(iD).idxGroups(iS);
		iC=D(iD).idxChans(iS);
		iB=groups(iG).nBlocks(iC)+1;
		groups(iG).nBlocks(iC)=iB;
		if D(iD).nVals(iS)
			if iscell(D(iD).D)
				D1=D(iD).D{iS};
			elseif size(D(iD).D,2)>1||nChan==1	%!!nChan==1 added!!
				D1=D(iD).D(:,iS);
			else
				%!!!!interleaved data!!!! --- is this possible?
				idn=id+D(iD).nVals(iS);
				D1=D(iD).D(id+1:idn);
				id=idn;
			end
			groups(iG).channel(iC).data{iB}=D1;
		end
	end		% for iC
end		% for iG
for iG=1:nGroups
	channels=groups(iG).channel;
	for iC=1:length(channels)
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
	end
	Dstruct.group(iG).channel=channels;
	groups(iG).channel=channels;
end		% for iG
chanInfo=[];
if bStructured
	e=Dstruct;
	return
elseif bRawBlocks
	e=D; %#ok<UNRCH>
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
	if bAutoChannel&&nGroups==1
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
		channels=[channels{:}];
		chanNames={channels.name};
		nChan=length(channels);
		if bLinChans
			uChanNames=unique(chanNames); %#ok<UNRCH>
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
if any([D.bDAQmxData])
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
				t0=lvtime(t0);
			end
			if bConvBlockTime
				T=gettimes(D);
			else
				T=[]; %#ok<UNRCH>
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

function [s,ix]=readString(Xtdms,ix)
l=double(typecast(Xtdms(ix+1:ix+4),'int32'));
ix=ix+4;
if l<0
	s='';
	warning('LEESTDMS:NEGATIVEstringLENGTH','!!!!!only positive string lengths are possible')
else
	s=char(Xtdms(ix+1:ix+l));
	ix=ix+l;
end

function [value,ix]=ReadData(Xtdms,ix,siz,dType,bConvert)
% see also readLVtypeString
bToDouble=false;
if ~isscalar(dType)
	error('Something is going wrong with type?!')
end
nElem=prod(siz);
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
		ixn=ix+nElem;
		value=int8(Xtdms(ix+1:ixn));ix=ixn;
		bToDouble=true;
	case 2
		ixn=ix+nElem*2;
		value=typecast(Xtdms(ix+1:ixn),'int16');ix=ixn;
		bToDouble=true;
	case 3
		ixn=ix+nElem*4;
		value=typecast(Xtdms(ix+1:ixn),'int32');ix=ixn;
		bToDouble=true;
	case 4
		ixn=ix+nElem*8;
		value=typecast(Xtdms(ix+1:ixn),'int64');ix=ixn;
		bToDouble=true;
	case 5
		ixn=ix+nElem;
		value=Xtdms(ix+1:ixn);ix=ixn;
		bToDouble=true;
	case 6
		ixn=ix+nElem*2;
		value=typecast(Xtdms(ix+1:ixn),'uint16');ix=ixn;
		bToDouble=true;
	case 7
		ixn=ix+nElem*4;
		value=typecast(Xtdms(ix+1:ixn),'uint32');ix=ixn;
		bToDouble=true;
	case 8
		ixn=ix+nElem*8;
		value=typecast(Xtdms(ix+1:ixn),'uint64');ix=ixn;
		bToDouble=true;
	case 9
		ixn=ix+nElem*4;
		value=typecast(Xtdms(ix+1:ixn),'single');ix=ixn;
		bToDouble=true;
	case 10
		ixn=ix+nElem*8;
		value=typecast(Xtdms(ix+1:ixn),'double');ix=ixn;
	case 11
		ixn=ix+nElem*16;
		value=double(reshape(Xtdms(ix+1:ixn),16,nElem));ix=ixn;
		zS=floor(value(1,:)/128);
		zE=rem(value(1,:),128)*256+data(2);
		zM=[72057594037927936,281474976710656,1099511627776,4294967296,16777216,65536,256,1]	...
			*value(10:-1:3,:)/2^64+1;
		value=reshape((-1)^zS*zM*2^(zE-16383),siz(1),siz(2));
	case 12
		ixn=ix+nElem*8;
		value=[1,1i]*reshape(typecast(Xtdms(ix+1:ixn),'single'),2,[]);ix=ixn;
	case 13
		ixn=ix+nElem*16;
		value=[1,1i]*reshape(typecast(Xtdms(ix+1:ixn),'double'),2,[]);ix=ixn;
	case 14		% !!!! extended !!!!
		ixn=ix+nElem*8;
		value=[1,1i]*reshape(typecast(Xtdms(ix+1:ixn),'single'),2,[]);ix=ixn;
	case 25	% single with unit!!!!!!!!
		ixn=ix+nElem*8;
		value=typecast(Xtdms(ix+1:ixn),'double');ix=ixn;
	case 26	% double with unit!!!!!!
		ixn=ix+nElem;
		value=int8(Xtdms(ix+1:ix+siz));ix=ixn;
		bToDouble=true;
	case 27	% extFloat with unit!!!!!!
		ixn=ix+nElem;
		value=int8(Xtdms(ix+1:ix+siz));ix=ixn;
		bToDouble=true;
	case 32	% string
		if nElem==1
			[value,ix]=readString(Xtdms,ix);
		else
			if isscalar(siz)
				siz=[1 siz];
			end
			value=cell(siz);
			ixn=ix+nElem*4;
			nB=typecast(Xtdms(ix+1:ixn),'uint32');ix=ixn;
			s=char(Xtdms(ix+1:ix+nB(end)));
			ix=ix+nB(end);
			iL=0;
			for iS=1:nElem
				value{iS}=s(iL+1:nB(iS));
				iL=nB(iS);
			end
		end
	case 33	% boolean
		ixn=ix+nElem;
		value=Xtdms(ix+1:ixn);ix=ixn;
		bToDouble=true;
	case 68	% timestamp
		sizRaw=siz;
		if length(sizRaw)==2
			if sizRaw(1)~=1
				error('reading timestamps is only implemented for vectors, not for arrays')
			else
				sizRaw(1)=16;
			end
		else
			sizRaw=[16 sizRaw];
		end
		ixn=ix+nElem*16;
		value=reshape(Xtdms(ix+1:ixn),16,sizRaw(2))';ix=ixn;
		if bConvert
			value=lvtime(value,true);
		end
	otherwise
		error('Unknown data type (%d)!!!',dType)
end
if prod(siz)>1
	if length(siz)>1
		value=reshape(value,siz);
	else
		value=value(:);
	end
end
if bToDouble&&numel(value)<5
	value=double(value);
end

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
