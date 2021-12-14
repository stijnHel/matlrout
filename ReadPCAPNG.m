function D=ReadPCAPNG(fName)
%ReadPCAPNG - Read PCAPNG-file - logfile of Wireshark
%      D=ReadPCAPNG(fName)
%
% see http://wiki.wireshark.org/Development/LibpcapFileFormat
%     http://www.winpcap.org/ntar/draft/PCAP-DumpFileFormat.html

fid=fopen(zetev([],fName));
if fid<3
	fid=fopen(fName);
	if fid<3
		error('Can''t open the file')
	end
end
x=fread(fid,[1 Inf],'*uint8');
fclose(fid);

I32=[1;256;65536;16777216];

DheaderBlock = [];
DintDescBlock = [];

tResolution=1e-6;	% !should come from header blocks!!!
tRef=datenum(1970,1,1);

nn=zeros(1,32);
n6=0;
S5 = [];
S6=struct('iID',cell(1,40000),'t',[],'nBcaptured',[],'nBpacket',[]	...
	,'data',[],'options',[]);
S3 = {};
iX = 1;
notImplementedBT = zeros(1,0,'uint8');
while iX<length(x)
	[B,BT,iX]=GetBlock(x,iX);
	nn(min(end,BT))=nn(min(end,BT))+1;
	switch BT
		case 168627466	% Section Header Block
			DheaderBlock1 = ReadSectionHeader(B);
			if ~isempty(DheaderBlock)
				warning('Multiple section header blocks!')
				DheaderBlock(end+1) = DheaderBlock1; %#ok<AGROW>
			else
				DheaderBlock = DheaderBlock1;
			end
		case 1	% Interface Description Block
			% see http://www.tcpdump.org/linktypes.html
			%    for linktype==1 (ethernet) -->
			%    https://ieeexplore.ieee.org/document/7428776/ (IEEE 802.3)
			DintDescBlock1 = ReadIntDesc(B);
			if isempty(DintDescBlock)
				DintDescBlock = DintDescBlock1;
			else
				DintDescBlock(end+1) = DintDescBlock1; %#ok<AGROW>
				warning('Multiple interface description blocks!')
			end
		case 3	% Simple Packet Block
			S3{1,end+1} = B;
		case 5	% Interface Statistics Block (Section 4.6)
			if ~isempty(S5)
				warning('Multiple Interface statistic blocks?!')
			end
			S5 = B;
		case 6	% Enhanced Packet Block
			II=I32'*reshape(double(B(1:20)),4,5);
			n6=n6+1;
			if n6>length(S6)
				S6(n6+9999).t=0;
			end
			S6(n6).iID=II(1);
			t=(II(2)*2^32+II(3))*tResolution;
			t=(t/86400)+tRef;
			S6(n6).t=t;
			S6(n6).nBcaptured=II(4);
			S6(n6).nBpacket=II(5);
			S6(n6).data=B(21:end);	% interpret!!!!
			lWithPaddedBytes = ceil(double(S6(n6).nBcaptured)/4)*4;
			if length(S6(n6).data)>lWithPaddedBytes
				fprintf('There are options for this block (%d)\n',n6)
				% (remove options-data from data!!)
				S6(n6).options = B(21+lWithPaddedBytes:end);
				%!!! interpret!!!!
			end
		otherwise
			B = notImplementedBT==BT;
			if ~any(B)
				warning('BT %d not implemented!',BT)
				notImplementedBT(1,end+1) = BT; %#ok<AGROW>
			end
	end
end
Bn=nn>0;
nn=[find(Bn);nn(Bn)];

D=struct('DheaderBlock',DheaderBlock,'DintDescBlock',DintDescBlock	...
	,'nTypes',nn	...
	,'S6',S6(1:n6)		...
	);
if ~isempty(S3)
	D.S3 = S3;
end
if ~isempty(S5)
	D.S5 = S5;
end

function [B,BT,iX]=GetBlock(x,iX)
I32=[1;256;65536;16777216];
BT=double(x(iX:iX+3))*I32;
lB=double(x(iX+4:iX+7))*I32;
B=x(iX+8:iX+lB-5);
if lB~=double(x(iX+lB-4:iX+lB-1))*I32
	error('Bad block end (length is expected)!')
end
iX=iX+lB;

function D = ReadSectionHeader(B)
D = struct('BOmagic',typecast(B(1:4),'uint32')	... should be 0x1A2B3C4D
	,'versionMajor',typecast(B(5:6),'uint16')	...
	,'versionMinor',typecast(B(7:8),'uint16')	...
	,'sectionLen',typecast(B(9:16),'uint64')	...
	);
i=16;
% (!!)make function to read option
while i<length(B)
	typ = B(i+1);
	l = typecast(B(i+3:i+4),'uint16');
	switch typ
		case 2	% shb_hardware
			s = char(B(i+5:i+4+l));
			D.hardware = s;
		case 3	% shb_os
			s = char(B(i+5:i+4+l));
			D.os = s;
		case 4	% shb_userappl
			s = char(B(i+5:i+4+l));
			D.userappl = s;
		case 0
			if ~all(B(i+1:end)==0)
				warning('Missing header info?')
			end
			break
		otherwise
			warning('Unknown type of section optional info?! (%d)',typ)
			break
	end
	i = i+4+ceil(double(l)/4)*4;
end

function D = ReadIntDesc(B)
D = struct('LinkType', typecast(B(1:2),'uint16')	...
	,'SnapLen', typecast(B(5:8),'uint32')	...
	,'Options', []	...
	,'Braw',B	... for debugging purposes
	);
if any(B(3:4)~=0)
	warning('Reserved bytes in Interface Description Block are not zeros?!')
end
Options = cell(2,20);
nO = 0;
iB = 9;
bAllOK = true;
% (!!!) use (not yet existing) ReadOption-function!
while iB<length(B)-3
	typ_len = typecast(B(iB:iB+3),'uint16');
	typ = typ_len(1);
	l = typ_len(2);
	Odata = B(iB+4:iB+3+l);
	iB = iB+4+ceil(double(l)/4)*4;
	switch typ
		case 2
			typ = 'if_name';
			Odata = char(Odata);
		case 3
			typ = 'if_description';
			Odata = char(Odata);
		case 4
			typ = 'IPv4addr';
			% Odata : IP + IPmask
		case 5
			typ = 'IPv6addr';
		case 6
			typ = 'if_MACaddr';
		case 7
			typ = 'if_EUIaddr';
		case 8
			typ = 'if_speed';
			Odata = typecast(Odata,'uint64');
		case 9
			typ = 'if_tsresol';
		case 10
			typ = 'if_tzone';
		case 11
			typ = 'if_filter';
			Odata = char(Odata);
		case 12
			typ = 'if_os';
			Odata = char(Odata);
		case 13
			typ = 'if_fcslen';
		case 14
			typ = 'if_tsoffset';
			Odata = typecast(Odata,'uint64');
		case 15
			typ = 'if_hardware';
			Odata = char(Odata);
		case 16
			typ = 'if_txspeed';
			Odata = typecast(Odata,'uint64');
		case 17
			typ = 'if_rxspeed';
			Odata = typecast(Odata,'uint64');		% if not known - just keep the "raw data"
		otherwise
			bAllOK = false;
	end
	nO = nO+1;
	Options{1,nO} = typ;
	Options{2,nO} = Odata;
end
Options = Options(:,1:nO);
if bAllOK && nO==length(unique(Options(1,1:nO)))
	%(if length is not OK, then e.g. multiple IP addresses are supplied)
	%      no combining of these are implemented
	Options = struct(Options{:});
end
D.Options = Options;
