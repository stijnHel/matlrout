function [MSGs,H]=ReadPCAP(fName)
%ReadPCAP - Read PCAP-file (libpcap file format)
%    [MSGs,H]=ReadPCAP(fName)

% see https://wiki.wireshark.org/Development/LibpcapFileFormat

fid=fopen(fFullPath(fName));
if fid<3
	error('Can''t open the file!')
end
x=fread(fid,[1 Inf],'*uint8');
fclose(fid);

nsTime = false;

MN=typecast(x(1:4),'uint32');
if MN==2712847316
	bByteSwap=false;
elseif MN==3569595041
	bByteSwap=true;
elseif MN==2712812621	% nanoseconds accuracy (?A1B23C4D? expected 1A2B3C4D !) 
	bByteSwap=false;
	nsTime = true;
else
	error('Unknown type! (0x%08X)',MN)
end
if nsTime
	fracTfactor = 1e-9;
else
	fracTfactor = 1e-6;
end
ix=4;
[v,ix]=GetUInt16(x,ix,bByteSwap,2);
[GMTcor,ix]=GetUInt32(x,ix,bByteSwap,1);
[sigfigs,ix]=GetUInt32(x,ix,bByteSwap,1);
[snaplen,ix]=GetUInt32(x,ix,bByteSwap,1);
[network,ix]=GetUInt32(x,ix,bByteSwap,1);
H=var2struct(v,GMTcor,sigfigs,snaplen,network);
MSGs=struct('t',cell(1,round(length(x)/500)),'ts',[],'msg',[]);
nMsgs=0;

while ix<length(x)-16
	[I,ix]=GetUInt32(x,ix,bByteSwap,4);
	if I(3)>snaplen
		warning('Message length larger than maximum?! Reading stopped.')
		break
	end
	if ix+I(3)>length(x)
		warning('Message out of file?!')
		break
	end
	nMsgs=nMsgs+1;
	MSGs(nMsgs).t=I(1:2);
	MSGs(nMsgs).ts=double(I(1:2))*[1;fracTfactor];
	MSGs(nMsgs).msg=x(ix+1:ix+I(4));
	ix=ix+I(3);
end
if nMsgs<length(MSGs)
	MSGs=MSGs(1:nMsgs);
end

function [I,ix]=GetUInt16(x,ix,bByteSwap,n)
ixn=ix+2*n;
I=typecast(x(ix+1:ixn),'uint16');
ix=ixn;
if bByteSwap
	I=swapbytes(I);
end

function [I,ix]=GetUInt32(x,ix,bByteSwap,n)
ixn=ix+4*n;
I=typecast(x(ix+1:ixn),'uint32');
ix=ixn;
if bByteSwap
	I=swapbytes(I);
end

function [I,ix]=GetInt32(x,ix,bByteSwap,n)
ixn=ix+4*n;
I=typecast(x(ix+1:ixn),'int32');
ix=ixn;
if bByteSwap
	I=swapbytes(I);
end
