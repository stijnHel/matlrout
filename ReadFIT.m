function [D,Xrecord,nX,NE,V,G]=ReadFIT(fName,varargin)
%ReadFIT  - Read FIT file (Flexible and Interoperable Data Transfer)
%     [D,X,nX,NE,V,G]=ReadFIT(fName);
%       D: struct with data as in FIT-file
%       X: record data
%       nX: field names
%
%  see also ProjGPS2XY

% add option to remove "starting and ending singles"
%          (couple of points that are related to previous use, or "saving
%          time")

bInterpret=nargout>1;
bGPX=false;
fileGPX=[];
bProcess=nargout>1;
[bRelTime] = nargout>5;
[bRemoveNaNs] = true;
Z1 = [];
if nargin>1
	setoptions({'bInterpret','bGPX','fileGPX','Z1','bRelTime','bRemoveNaNs'},varargin{:})
	bGPX=bGPX||ischar(fileGPX);
	bProcess=bProcess||bGPX;
	bInterpret=bInterpret||bGPX;
end

BE16=[1;256];
BE32=[1;256;65536;16777216];
x=typecast(uint16(256),'uint8');
localArch=x(1);
sCRCtable=['0000 CC01 D801 1400 F001 3C00 2800 E401 ',	...
	'A001 6C00 7800 B401 5000 9C01 8801 4400'];
crc_table = uint16(sscanf(sCRCtable,'%x'));
InvalValues=[255 127 255 32767 65536 2^31-1 2^32-1 0	... 0-7
	2^32-1 2^64-1 0 0 0 255 2^63-1 2^64-1	... 8-15 (!!!floating points, too high values!)
	0];

if bInterpret
	if exist('FITprofile.mat','file')
		F=load('FITprofile');
		Btypes=F.Btypes;
		Ctypes=F.Ctypes;
		Bmsgs=F.Bmsgs;
		Cmsgs=F.Cmsgs;
	else
		pth=fileparts(which(mfilename));
		fFITprofile=fullfile(pth,'Profile.xlsx');
		[~,Btypes,Ctypes]=xlsread(fFITprofile,'Types');
		[~,Bmsgs,Cmsgs]=xlsread(fFITprofile,'Messages');
		fFITprofile=fullfile(pth,'FITprofile.mat');
		save(fFITprofile,'Btypes','Ctypes','Bmsgs','Cmsgs')
	end
	msgNames=GetElems('mesg_num');
end

fName=fFullPath(fName,[],'.fit');
fid=fopen(fName);
x=fread(fid,[1 Inf],'*uint8');
fclose(fid);
xD=double(x);

if x(1)~=12&&x(1)~=14
	error('No FIT file (wrong File Header start)')
end
if ~strcmp(char(x(9:12)),'.FIT')
	error('No FIT file (no ".FIT" in header)')
end
H=struct('ProtocolVersion',x(2),'ProfileVersion',xD(3:4)*BE16		...
	,'DataSize',xD(5:8)*BE32);
if x(1)==14
	CRC=xD(13:14)*BE16;
	if CRC~=0
		crcHead=CalcCRC(x(1:12));
		if crcHead~=CRC
			warning('Error in header-CRC?!')
		end
	end
end
CRC=xD(end-1:end)*BE16;
crcFile=CalcCRC(x(1:end-2));
if CRC~=crcFile
	warning('Error in file-CRC?!')
end

R=[];
nR=0;
ix=xD(1);
ix0=ix;
if H.DataSize>length(x)-ix0
	warning('DataSize in header is larger than data?!!')
	ixMax = length(x)-2;
else
	ixMax = H.DataSize+ix0;
end
file_id=0;
file_idTxt=[];
while ix<ixMax
	nR=nR+1;
	[R1,ix]=ReadRecord(x,ix);
	if isempty(R)
		R=R1(1,ones(1,1000));
	else
		if nR>length(R)
			R(end+1000)=R1; %#ok<AGROW>
		end
		R(nR)=R1; %#ok<AGROW>
	end
end
R=R(1:nR);
D=struct('file_id',file_id,'file_idTxt',file_idTxt	...
	,'H',H	...
	,'R',R);

if bProcess
	DF=[R.DEF];
	iRecord=find([R.msgTyp]==0&[DF.globalMsgNr]==20);
	N=cellfun('length',{R(iRecord).data});
	if max(N)>min(N)
		warning('Not always the same data in records!')
		bNok=false;
	else
		bNok=true;
	end
	if bInterpret&&bNok
		Xrecord=cat(1,R(iRecord).dataScaled);
	else
		Xrecord=zeros(length(iRecord),max(N));
		for iR=1:length(iRecord)
			d=R(iRecord(iR)).data;
			for jD=1:length(d)
				Xrecord(iR,jD)=d{jD};
			end
		end		% for iR
	end
	if isempty(N)
		nX={};
	else
		nX=R(iRecord(1)).DEF.fldNames;
	end
	if bRemoveNaNs
		Bnan = isnan(Xrecord(:,2));
		if any(Bnan)
			Xrecord(Bnan,:) = [];
			if Bnan(1) && size(Xrecord,1)>1 && Xrecord(2,1)-Xrecord(1)>10/86400
				Xrecord(1,:) = [];
			end
		end
	end
	if nargout>3
		[NE,V,~,Z1]=ProjGPS2XY(Xrecord(:,1:3),'Z1',Z1);
		dPts = sqrt(sum(diff(NE).^2,2));
		Dtot=sum(dPts(~isnan(dPts)));
	end
	if ischar(fileGPX)
		if isempty(fileGPX)
			[fPath,fileGPX]=fileparts(fName);
			fileGPX = [fullfile(fPath,fileGPX) '.gpx'];
		elseif ~any(fileGPX=='.')
			fileGPX = [fileGPX '.gpx'];
		end
	end
	if bGPX
		Sxml=CreateGPX(Xrecord);
		if isempty(fileGPX)
			D=Sxml;
		end
		if ~isempty(fileGPX)
			fid=fopen(fileGPX,'w');
			if fid<3
				error('Can''t open the file!!')
			end
			fwrite(fid,Sxml);
			fclose(fid);
		end
	end
	t0X = Xrecord(1);
	t0Data = datenum(1989,12,31,1,0,0);
	t0 = t0X/86400+t0Data;
	if isDST(t0)
		t0 = t0+1/24;
		t0Data = t0Data+1/24;
	end
	if bRelTime
		Xrecord(:,1) = Xrecord(:,1)-t0;
	else
		Xrecord(:,1) = Xrecord(:,1)/86400+t0Data;
	end
	
	if nargout>5
		dD = dPts;
		dD(isnan(dD)) = 0;
		cumD = [0;cumsum(dD)];
		G = var2struct(Dtot,Z1,t0,dPts,cumD);
	end
end		% if bProcess

	function crc=CalcCRC(x)
		crc=uint16(0);
		for i=1:length(x)
			crc=FitCRC_add(crc,x(i));
		end
	end % CalcCRC

	function crc=FitCRC_add(crc, byte)
		% compute checksum of lower four bits of byte
		tmp = crc_table(bitand(crc,15)+1);
		crc = bitshift(crc,-4);
		crc = bitxor(bitxor(crc,tmp), crc_table(bitand(byte,15)+1));
		% now compute checksum of upper four bits of byte
		tmp = crc_table(bitand(crc,15)+1);
		crc = bitshift(crc,-4);
		crc = bitxor(bitxor(crc,tmp), crc_table(bitshift(byte,-4)+1));
	end		% FitCRC_add

	function [R,ix]=ReadRecord(x,ix)
		persistent tRunning MSGs
		
		ix=ix+1;
		x1=x(ix);
		bCompTime=x1>127;
		if bCompTime
			localTyp=bitand(bitshift(x1,-4),3);
			dt=bitand(x1,31);
			t1=bitand(tRunning,31);
			if dt>=t1
				tRunning=t1+uint32(dt);
			else
				tRunning=t1+32+uint32(dt);
			end
			msgTyp=0;
			msgTspec=0;
		else
			msgTyp=bitand(x1,64);	% definition or data message
			msgTspec=bitand(x1,32);
			localTyp=bitand(x1,15);
		end
		if msgTyp	% definition message
			ix=ix+1;
			if x(ix)
				warning('nonzero reserved byte?!')
			end
			archType=x(ix+1);	% architecture type (0: LE, 1: BE)
			globalMsgNr=typecast(x(ix+2:ix+3),'uint16');
			if archType~=localArch
				globalMsgNr=swapbytes(globalMsgNr);
			end
			ix=ix+4;
			nFields=double(x(ix));
			ixN=ix+nFields*3;
			fldData=reshape(x(ix+1:ixN),3,nFields);
			ix=ixN;
			if msgTspec
				ix=ix+1;
				nDevFields=double(x(ix));
				ixN=ix+nDevFields*3;
				devFldData=reshape(x(ix+1:ixN),3,nDevFields);
				ix=ixN;
			else
				devFldData=[];
			end
			DEF=var2struct(archType,globalMsgNr,fldData,devFldData);
			if bInterpret
				k=find([msgNames{:,2}]==globalMsgNr);
				if isempty(k)
					warning('Message number %d not known?!',globalMsgNr)
				else
					DEF.msgName=msgNames{k};
					DEF.fields=GetMessage(DEF.msgName);
					DEF.fldNames=cell(1,nFields);
					DEF.fldInvalid=InvalValues(bitand(fldData(3,:),31)+1);
					DEF.scale=ones(1,nFields);
					DEF.offset=zeros(1,nFields);
					idFields=[DEF.fields{:,1}];
					for j=1:nFields
						B=idFields==fldData(1,j);
						if any(B)
							DEF.fldNames{j}=DEF.fields{B,2};
							if isnumeric(DEF.fields{B,6})&&~isnan(DEF.fields{B,6})	% scale
								DEF.scale(j)=DEF.fields{B,6};
							%elseif strcmp(DEF.fields{B,3},'date_time')	% predefined scalings
							%	DEF.scale(j)=86400;	% not necessary!!!!
							%	DEF.offset(j)=-datenum(1989,12,31,1,0,0);
							elseif ischar(DEF.fields{B,8})
								switch DEF.fields{B,8}
									case 'ms'
										DEF.scale(j)=1e3;
									case 'semicircles'
										DEF.scale(j)=2^31/180;
								end
							end		% scaling
							if isnumeric(DEF.fields{B,7})&&~isnan(DEF.fields{B,7})	% offset
								DEF.offset(j)=DEF.fields{B,7};
							end
						else
							UnknownTag(DEF.msgName,fldData(1,j))
						end
					end		% for j
				end
			end		% if bInterpret
			if isempty(MSGs)
				MSGs=DEF(1,ones(1,localTyp+1));
			else
				try
					MSGs(localTyp+1)=DEF;
				catch err
					MSGs=[];
					DispErr(err)
					error('Sorry, something went wrong, retrying could solve the problem(!)')
				end
			end
			data=[];
			dataScaled=[];
		else
			DEF=MSGs(localTyp+1);
			bSwapBytes=DEF.archType~=localArch;
			data=cell(1,size(DEF.fldData,2));
			if bInterpret
				dataScaled=zeros(1,length(data));
			end
			for i=1:size(DEF.fldData,2)
				[X,ix,bValid]=GetFieldData(x,ix,DEF.fldData,i,bSwapBytes);
				if DEF.fldData(1,i)==253	% time
					tRunning=X;
				end
				if bInterpret
					if DEF.globalMsgNr==0	% file type
						if DEF.fldData(1,i)==0
							file_id=X;
							typs=GetElems('file');
							idxTyp=find([typs{:,2}]==X);
							if isempty(idxTyp)
								warning('file type %d not known?!!',X)
							else
								file_idTxt=typs{idxTyp};
							end
						end
					end		% if file type
					if bValid&&isnumeric(X)
						dataScaled(i)=double(X)/DEF.scale(i)-DEF.offset(i);
					else
						dataScaled(i)=NaN;
					end
				end		% if bInterpret
				data{i}=X;
			end		% for i
			if ~isempty(DEF.devFldData)
				devData=cell(1,size(DEF.devFldData,2));
				for i=1:size(DEF.devFldData,2)
					[X,ix]=GetFieldData(x,ix,DEF.devFldData,i,bSwapBytes);
					devData{i}=X;
				end
				data{1,end+1}=devData;
			end
		end
		
		R=var2struct(tRunning,msgTyp,localTyp,DEF,data);
		if bInterpret
			R.dataScaled=dataScaled;
		end
	end % function ReadRecord

	function [X,ix,bValid]=GetFieldData(x,ix,fldData,i,bSwapBytes)
		ixN=ix+double(fldData(2,i));
		x1=x(ix+1:ixN);
		ix=ixN;
		vTyp=bitand(fldData(3,i),31);
		switch vTyp
			case 0	% enum
				X=x1;
			case 1	% sint8
				X=typecast(x1,'int8');
			case 2	% uint8
				X=x1;
			case 3	% int16
				X=typecast(x1,'int16');
			case 4	% uint16
				X=typecast(x1,'uint16');
			case 5	% int32
				X=typecast(x1,'int32');
			case 6	% uint32
				X=typecast(x1,'uint32');
			case 7	% string
				X=char(x1);	%???variable length !!!utf-8
			case 8	% float32
				X=typecast(x1,'single');	% test invalid
			case 9	% float64
				X=typecast(x1,'double');	% test invalid
			case 10	% uint8z
				X=x1;
			case 11	% uint16z
				X=typecast(x1,'uint16');
			case 12	% uint32z
				X=typecast(x1,'uint32');
			case 13	% byte
				X=x1;
			case 14	% int64
				X=typecast(x1,'int64');
			case 15	% uint64
				X=typecast(x1,'uint64');
			case 16	% uint64z
				X=typecast(x1,'uint64');
			otherwise
				error('Unknown type!')
		end
		if fldData(3,i)>127&&bSwapBytes
			X=swapbytes(X);
		end
		if isscalar(X)
			bValid = X~=InvalValues(vTyp+1);
		elseif ischar(X)
			bValid = true;
		else
			warning('Non scalar data?!')
			bValid = all(X~=InvalValues(vTyp+1));
		end
	end		% function GetFieldData

	function msgs=GetMessage(msgName)
		% only take "base fields"
		iMsgNum=find(strcmp(Cmsgs(:,1),msgName));
		i=iMsgNum+1;
		ii=iMsgNum+1:iMsgNum+256;
		while i<=size(Cmsgs,1)&&isempty(Bmsgs{i})
			if ~isnumeric(Cmsgs{i,2})||isnan(Cmsgs{i,2})
				ii(i-iMsgNum)=0;
			end
			i=i+1;
		end
		msgs=Cmsgs(nonzeros(ii(1:i-1-iMsgNum)),2:11);
	end		% function GetTypes

	function [elems,typ]=GetElems(typeName)
		iMsgNum=find(strcmp(Ctypes(:,1),typeName));
		i=iMsgNum+1;
		while ~isempty(Btypes{i,3})
			if ~isnumeric(Ctypes{i,4})
				if strncmpi(Ctypes{i,4},'0x',2)
					Ctypes{i,4}=sscanf(Ctypes{i,4},'0x%x',1);
				end
			end
			i=i+1;
		end
		typ=Ctypes{iMsgNum,2};
		elems=Ctypes(iMsgNum+1:i-1,3:5);
	end		% function GetTypes

end		% function ReadFIT

function Sxml=CreateGPX(X)
Cbase=struct('type',2,'tag','','fields',[],'data',[],'children',[]);
CptBase=Cbase;
CptBase.tag='trkpt';
CptBase.fields={'lat',0;'lon',0};
CptBase.children=Cbase([1,1]);
CptBase.children(1).tag='ele';
CptBase.children(2).tag='time';

C=Cbase([1 1]);
C(1).tag='xml';
C(1).type=1;
C(1).fields={	...
	'version','1.0';
	'encoding','UTF-8';
	'standalone','no'};
C(2).tag='gpx';
C(2).fields={	... what's required?
	'xmlns'              'http://www.topografix.com/GPX/1/1'
	'xmlns:gpxx'         'http://www.garmin.com/xmlschemas/GpxExtensions/v3'
	'xmlns:gpxtrkx'      'http://www.garmin.com/xmlschemas/TrackStatsExtension/v1'
	'xmlns:wptx1'        'http://www.garmin.com/xmlschemas/WaypointExtension/v1'
	'xmlns:gpxtpx'       'http://www.garmin.com/xmlschemas/TrackPointExtension/v1'
	'creator'            'Oregon 700'
	'version'            '1.1'
	'xmlns:xsi'          'http://www.w3.org/2001/XMLSchema-instance'
	'xsi:schemaLocation' 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackStatsExtension/v1 http://www8.garmin.com/xmlschemas/TrackStatsExtension.xsd http://www.garmin.com/xmlschemas/WaypointExtension/v1 http://www8.garmin.com/xmlschemas/WaypointExtensionv1.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd'
	};

Cc=Cbase;
Cc.tag='trk';
Ctrk=Cbase([1 1]);
Ctrk(1).tag='name';
Ctrk(1).data={GetStime(X(1))};
	% expecting that extensions are not necessary
Ctrk(2).tag='trkseg';	% more segments?
nPts=size(X,1);
Ctrk(2).children=CptBase(1,ones(1,nPts));
Bok=false(1,nPts);
for i=1:nPts
	if ~any(isnan(X(i,2:3)))
		Bok(i)=true;
		Ctrk(2).children(i).fields{1,2}=sprintf('%.6f',X(i,2));
		Ctrk(2).children(i).fields{2,2}=sprintf('%.6f',X(i,3));
		if isnan(X(i,8))
			Ctrk(2).children(i).children(1).data={'0'};
		else
			Ctrk(2).children(i).children(1).data={sprintf('%.2f',X(i,8))};
		end
		Ctrk(2).children(i).children(2).data={GetStimeUTC(X(i))};
	end
end
if ~all(Bok)
	Ctrk(2).children=Ctrk(2).children(Bok);
end
Cc.children=Ctrk;

C(2).children=Cc;
Xxml=struct('type',0,'tag','root','from','fileXXXXX','data',[]	...
	,'children',C);
Sxml=writexml(Xxml);
end		% CreateXML

function s=GetStime(X)
persistent t0
if isempty(t0)
	t0=datenum(1989,12,31);
end
s=datestr(X/86400+t0);
end		% GetStime

function s=GetStimeUTC(X)
persistent t0
if isempty(t0)
	t0=datenum(1989,12,31);
end
s=datestr(X/86400+t0,'yyyy-mm-ddTHH:MM:SSZ');
end		% GetStimeUTC

function UnknownTag(msg,tagNr)
persistent UNKNOWNTAGS

tag = sprintf('%s.%d',msg,tagNr);
if isempty(UNKNOWNTAGS)
	UNKNOWNTAGS = {tag};
elseif ~any(strcmp(UNKNOWNTAGS,tag))
	UNKNOWNTAGS{1,end+1} = tag;
	warning('Unknown field (%s)!',tag)
end
end		% UnknownTag
