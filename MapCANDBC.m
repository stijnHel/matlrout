function [D,IDundefined,Ilog]=MapCANDBC(Xlog,Cdbc,bReplaceFE_id,node_id,bDiscardPrio)
%MapCANDBC - Map logged CAN-data with DBC-specification
%    [D,IDundefined]=MapCANDBC(Xlog,Cdbc)
%        Xlog: log of CAN data (see ReadCANLOG)
%             struct with fields:
%                T: timestamp (vector)
%                ID: CAN ID's (vector)
%                D: [nx8] matrix with data bytes
%               optional: (if not available, it's created)
%                uID: unique ID's
%                iID: indices of data related to uID's
%             or:
%                Timestamp
%                ID
%                Data
%             or:
%                channel (TDMS data) with channels
%                     Timestamp
%                     Payload
%                     Identifier

D=[];
IDundefined=[];
if ischar(Xlog)
	Xlog=ReadCANLOG(Xlog);
elseif isstruct(Xlog)&&isfield(Xlog,'Name')&&isfield(Xlog,'Data')
	%CNH-data
	if (isfield(Xlog,'MetaData')||isfield(Xlog,'Metadata'))&&length(Xlog)>=3	% part of CNHstruct
		nameData = {Xlog.Name};
		iID = find(strcmp('Id',nameData));
		iT = find(strcmp('Timestamp',nameData));
		iD = find(strcmp('Payload',nameData));
		if isempty(iID)||isempty(iT)||isempty(iD)
			warning('Can''t interpret CAN-data!!!')
			return
		end
		if ~isscalar(iID)||~isscalar(iT)||~isscalar(iD)
			warning('Multiple channels for ID, T or D?!')
			iID = iID(1);
			iT = iT(1);
			iD = iD(1);
		end
		if length(Xlog)>3
			warning('Already interpreted CAN-data?!')
		end
		T = Xlog(iT).Data;
		if isstruct(T)||isa(T,'timeseries')
			T = T.Data;
		end
		ID = Xlog(iID).Data;
		if isstruct(ID)||isa(ID,'timeseries')
			ID = ID.Data;
		end
		Data = Xlog(iD).Data;
		if isstruct(Data)||isa(Data,'timeseries')
			Data = Data.Data;
		end
		D = reshape(typecast(Data,'uint8'),8,[]);
	else	% older data?
		T=Xlog.Data(11).Data.Data;
		ID=Xlog.Data(9).Data.Data;
		D=[Xlog.Data(1:8).Data];
		D=[D.Data];
	end
	Xlog=var2struct(T,ID,D);
elseif isstruct(Xlog)&&isfield(Xlog,'Timestamp')&&isfield(Xlog,'Data')
	% also CNH-data
	T=Xlog.Timestamp(:);
	ID=Xlog.ID(:);
	D=Xlog.Data;
	Xlog=var2struct(T,ID,D);
elseif isstruct(Xlog)&&isfield(Xlog,'properties')&&isfield(Xlog,'channel')
	% CNH-TDMS-data (result from leesTDMS)
	iTime=find(strcmpi('Timestamp',{Xlog.channel.name}));
	iData=find(strcmpi('Payload'  ,{Xlog.channel.name}));
	iID = find(startsWith({Xlog.channel.name},'Id','IgnoreCase',true));
	if isempty(iTime)||isempty(iData)||isempty(iID)
		error('Wrong expectations about data!')
	end
	T=Xlog.channel(iTime).data;
	ID=Xlog.channel(iID).data;
	D=Xlog.channel(iData).data;
    if isempty(D)
        % do nothing
	elseif ~isa(D,'uint64')
        error('Wrong expectation about data - datatype!')
    end
	Xlog=var2struct(T,ID,D);
elseif isstruct(Xlog)&&isfield(Xlog,'id')&&isfield(Xlog,'dlc')	% BAG data
	ID = [Xlog.id]';
	DLC = [Xlog.dlc]';
	if isfield(Xlog,'header')
		H = [Xlog.header];
		T = [H.stamp]';
		if all(cellfun('length',{Xlog.data})==8)
			D = cat(1,Xlog.data)';
		else
			D = zeros(8,length(Xlog));
			for i=1:length(ID)
				D(1:length(Xlog(i).data)) = Xlog(i).data;
			end
		end
	elseif isfield(Xlog,'header_stamp')
		T = Xlog.header_stamp;
		D = Xlog.data;
	else
		warning('No timestamp field found in CAN-data!')
		T = (1:length(ID))';
	end
	Xlog=var2struct(T,ID,D,DLC);
end
if isa(Xlog.D,'uint64')	% packed bytes into uin64 --> bytes
	Xlog.D=reshape(typecast(Xlog.D,'uint8'),8,[])';
	Xlog.D=Xlog.D(:,8:-1:1);	%bigendian ---> littleendian (swapbytes of uint64 is an alternative)
end

if ischar(Cdbc)
	Cdbc=leesdbc(Cdbc);
end
if nargin<3||isempty(bReplaceFE_id)
	bReplaceFE_id = false;
end
if nargin<4||isempty(node_id)
	node_id = 0;
elseif ~isnumeric(node_id)
	node_id = str2double(node_id);% node_id can still be a string as entered in dbc_can
end
if nargin<5||isempty(bDiscardPrio)
	bDiscardPrio = false;
end
if bReplaceFE_id
	% if DBC-ID ends with 0xFE (254), then it's replaced by node_id (default 0)
	%     (a J1939-option - "not yet defined addresses")
	for i=1:size(Cdbc,1)
		if Cdbc{i}>1024&&bitand(Cdbc{i},255)==254
			Cdbc{i}=Cdbc{i}-254+node_id;
			if bDiscardPrio
				Cdbc{i}=bitand(Cdbc{i},2^26-1);
			end
		end
	end
end

if bReplaceFE_id&&bDiscardPrio
	B = Xlog.ID>1024&bitand(Xlog.ID,255)==node_id;
	Xlog.ID(B) = bitand(Xlog.ID(B),2^26-1);
	Xlog.uID = unique(Xlog.ID);
end
if ~isfield(Xlog,'uID')
	Xlog.uID=unique(Xlog.ID);
end
if ~isfield(Xlog,'iID')
	Xlog.iID=cell(1,length(Xlog.uID));
	for i=1:length(Xlog.uID)
		Xlog.iID{i}=find(Xlog.ID==Xlog.uID(i));
	end
end
if min(size(Xlog.D))>8
	% expecting one DLC-column of row
	BdBytes = size(Xlog.D)==9;
	if ~any(BdBytes)
		error('Minimally 1 dimension of D must be at most 9!')
	elseif all(BdBytes)
		if any(Xlog.D(1,:)>8)
			Xlog.D = Xlog.D';
			if any(Xlog.D(1,:)>8)
				error('First column or row of D not DLC?!')
			end
		end
	elseif BdBytes(2)
		Xlog.D = Xlog.D';
	end
	Xlog.DLC = Xlog.D(1,:);
	Xlog.D = Xlog.D(2:end,:);
elseif size(Xlog.D,1)>8
	Xlog.D=Xlog.D';
end

IDdbc=cell2mat(Cdbc(:,1));
IDundefined=setdiff(Xlog.uID,IDdbc);
[IDdefined,Ilog,Idbc]=intersect(Xlog.uID,IDdbc);

D=struct('msg',Cdbc(Idbc,2)','msgID',Cdbc(Idbc,1)'	...
	,'src',Cdbc(Idbc,5)'	...
	,'signals',Cdbc(Idbc,3)','t',[],'X',[]	...
	,'dataOK',[],'signalsOK',[]);

for i=1:length(IDdefined)
	iDBC=Idbc(i);
	iLOG=Ilog(i);
	msg=Cdbc{iDBC,3};
	bytes = [msg.byte];
	nBytes = max(bytes)+1;
	if nBytes>8	% packed data (assuming "Fast-packet transmission")
		iMSGs = Xlog.iID{iLOG};
		nMsgsPerPacket = ceil(nBytes/7);
		Draw = Xlog.D(:,iMSGs);
		iPart = bitand(Draw(1,:),31);
		if max(iPart)+1~=nMsgsPerPacket
			if length(iMSGs)<2*nMsgsPerPacket	% not enough messages
				continue
			end
			warning('Something is wrong with the message packages?!')
			nMsgsPerPacket = max(iPart)+1;
		end
		nMsgsPerPacket = double(nMsgsPerPacket);
		if iPart(1)~=0	% skip uncomplete packets at the start
			j = find(iPart==0,1);
			if isempty(j)
				continue	% no start of packet found - not enough messages?
			end
			iPart(1:j-1) = [];
			iMSGs(1:j-1) = [];
			Draw(:,1:j-1) = [];
		end
		% Create packets
		if all(iPart(1:nMsgsPerPacket:end)==0)	% fast method
			% remove uncomplete packets at the end
			while ~isempty(iMSGs)&&iPart(end)~=nMsgsPerPacket-1
				iPart(end) = [];
				iMSGs(end) = [];
				Draw(:,end) = [];
			end
			% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			if isempty(Draw)
				% Draw can be empty, which gives an error ni Draw(1) in the following if.
				% Example where this happens: 20200903_152712_LSB D4.tdms
				continue
			end
			% ---------------------------------------------
			% combine raw data of message in packets
			Draw = reshape(Draw,8,nMsgsPerPacket,[]);
			Draw = reshape(Draw(2:8,:,:),7*nMsgsPerPacket,size(Draw,3));
			if ~all(Draw(1,:)==Draw(1))	% length data
				warning('Expected to work with constant length packages!')
			end
			Draw(1,:) = [];	% removed length data
			D(i).t = Xlog.T(iMSGs(1:nMsgsPerPacket:end));
		else	% slow (robust) method
			% in fact, this is not a lot slower than the "fast method"!
			[Draw,D(i).t] = GetPacketData(Draw,iPart,Xlog.T(iMSGs));
		end
	else	% normal messages - not more than 8 bytes (64 bits)
		D(i).t=Xlog.T(Xlog.iID{iLOG});
		Draw = Xlog.D(:,Xlog.iID{iLOG});
	end		% normal message (<= 64 bits)
	[D(i).X,D(i).signalsOK] = InterpretRaw2Signals(Draw,msg);
	linkSigs = Cdbc{iDBC,7};
	if ~isempty(linkSigs)
		Bdel = false(1,length(msg));
		for j=1:length(linkSigs)
			D(i).X(:,linkSigs(j).link(1)) = D(i).X(:,linkSigs(j).link)*linkSigs(j).factor;
			Bdel(linkSigs(j).link(2:end)) = true;
			D(i).signals(linkSigs(j).link(1)).signal = linkSigs(j).name;
		end
		D(i).signals(Bdel) = [];
		D(i).X(:,Bdel) = [];
	end
	D(i).dataOK=all(D(i).signalsOK);
end		% for i

function [X,signalsOK] = InterpretRaw2Signals(D,msg)
X=zeros(size(D,2),length(msg));
signalsOK=true(1,length(msg));
for j=1:length(msg)
	if max(msg(j).byte)>=size(D,1)
		signalsOK(j) = false;
		continue
	end
	%bReverseBits=length(msg(j).bitorder)==3&&msg(j).bitorder(1)=='@'&&msg(j).bitorder(2)=='0';
		% now interpreted in leesdbc
	bReverseBits = msg(j).bBigEndian;
	V=D(msg(j).byte+1,:);
	bb=rem(msg(j).bit(1),8);
	nBits = msg(j).bit(2);
	nBytes = length(msg(j).byte);
	if bReverseBits
		Vs = 2.^(8*(size(V,1)-1:-1:0));
		fBits = 8*nBytes-nBits-7+bb;
	else
		Vs = 2.^(8*(0:nBytes-1));
		fBits = bb;
	end
	V = Vs*double(V);
	if fBits>0
		V=floor(V/2^fBits);
	end
	if 	length(msg(j).byte)*8>nBits+fBits
		V=bitand(V,2^nBits-1);
	end
	%if msg(j).bitorder(end)=='-'
	if msg(j).bSigned && nBits>1
		if ~isfloat(V)	% always in the current version?!!
			V=double(V);
		end
		V=V-2^nBits*(V>=2^(nBits-1));
	end
	V=V*msg(j).scale(1)+msg(j).scale(2);
	X(:,j)=V;
	if length(msg(j).scale)>2
		if msg(j).scale(3)<msg(j).scale(4) && any(V<msg(j).scale(3)|V>msg(j).scale(4))
			%warning('signal (#%d,%d) %s is going out-of-bounds!'	...
			%	,i,j,msg(j).signal)
			signalsOK(j)=false;
		end
	end
end		% for j

function [Dpackets,Tpackets] = GetPacketData(D,iPart,T)
nPackets = sum(iPart==0);	% number of starting messages in a packet
nMax = (max(iPart)+1)*7-1;	% maximum number of bytes in a packet (max #msgs/packet * max bytes in a msg)

Dpackets = zeros(nMax,nPackets,'uint8');
Tpackets = zeros(nPackets,1);
iD = 1;
iPacket = 1;
nD = size(D,2);
nBmax = 0;
while iD<nD
	nBytes = D(2,iD);
	if nBytes>nMax
		warning('Unexpected high size of packets - everything OK?')
	end
	Dpackets(1:6,iPacket) = D(3:8,iD);
	Tpackets(iPacket) = T(iD);
	iD = iD+1;
	nB = 6;
	msgNr = 0;
	while iD<=nD && nB<nBytes
		msgNr = msgNr+1;
		if iPart(iD)~=msgNr
			warning('Missing data in CAN-packet! - packet is skipped');
			while iD<nD && iPart(iD)~=0
				iD = iD+1;
			end
			break
		end
		Dpackets(nB+1:nB+7,iPacket) = D(2:8,iD);
		iD = iD+1;
		nB = nB+7;
	end		% while packet not full
	if nB>=nBytes	% else incomplete or missing message
		iPacket = iPacket+1;
		nBmax = max(nBmax,nBytes);
	end
end		% while not all data processed
iPacket = iPacket-1;	% if packet is full, iPacket is incremented
if iPacket<nPackets||nBmax<nMax
	Dpackets = Dpackets(1:nBmax,1:iPacket);
	Tpackets = Tpackets(1:iPacket);
end
