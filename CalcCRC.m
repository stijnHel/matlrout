function crc=CalcCRC(x,varargin)
%CRCcalc  - Calculates CRC following ISO 3309 and ITU-T V.42
%   This CRC-check is (for example) used in GZIP files
%        crc=CalcCRC(x);
%        crc=CalcCRC(x,crc_previous)
%
% Based on code in RFC1952 (https://tools.ietf.org/html/rfc1952)

persistent CRC_TABLE

if isempty(CRC_TABLE)
	CRC_TABLE=CalcCRCtable();
end

if nargin>1
	crc=varargin{1};
else
	crc=0;
end

C0=2^32-1;
crc=bitxor(crc,C0);
for i=1:length(x)
	crc=bitxor(CRC_TABLE(rem(bitxor(crc,x(i)),256)+1),floor(crc/256));
end
crc=bitxor(crc,C0);

function crc_table=CalcCRCtable()

crc_table=zeros(1,256);

for n=0:255
	c=n;
	for k=0:7
		if rem(c,2)
			c=bitxor(3988292384,floor(c/2));
		else
			c=floor(c/2);
		end
	end
	crc_table(n+1)=c;
end
