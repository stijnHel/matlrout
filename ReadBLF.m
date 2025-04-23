function D = ReadBLF(fName,varargin)
%ReadBLF  - Read BLF file (Vector CAN logging format)
%    D = ReadBLF(fName)
%
%  (based on LabVIEW code - but heavily adapted)
%         ("Read Write BLF API 2018 Version 8")
%     see also: binlog_objects.h

%!!!!!!! blocks of data should be appended, now it's "assumed" that objects
%fit within a single block of data.  But that's not the case!!!!

[nObjectMax] = [];

if nargin>1
	setoptions({'nObjectMax'},varargin{:})
end

f = file(fName);

fSig = f.fread([1 4],'*char');
if ~strcmp(fSig,'LOGG')
	error('Wrong start!')
end

hLen = f.fread(1,'*uint32');
Hraw = f.fread([1 hLen-8],'*uint8');

sizUncompressed = typecast(Hraw(17:24),'uint64');
nObjects = typecast(Hraw(25:28),'uint32');
iXXX = typecast(Hraw(29:32),'uint32');
[tStart,tSdn,ix] = ExtractTime(Hraw,32);
[tEnd,tEdn,ix] = ExtractTime(Hraw,ix);

H = var2struct(sizUncompressed,nObjects,tStart,tEnd,tSdn,tEdn);

x = f.fread([1 Inf],'*uint8');

cStat = cStatus('Reading data',0);
[B,ix] = ReadBlock(x,0);
iB = 0;
bBav = true;
OO = cell(1,10000);
nOO = 1;
OO{1} = cell(1,10000);
nOOi = 0;
nObjects = 0;
while length(B)-iB>20
	if length(B)-iB<1000 && bBav
		[B1,ix] = ReadBlock(x,ix);
		cStat.status(ix/length(x))
		if isempty(B1) || length(x)-ix<50
			bBav = false;
		else
			B = [B(iB+1:end),B1];
			iB = 0;
		end
	end
	[Oi,iB] = ReadObject(B,iB);
	nOOi = nOOi+1;
	if nOOi>length(OO{nOO})
		nOO = nOO+1;
		nOOi = 1;
	end
	OO{nOO}{nOOi} = Oi;
	nObjects = nObjects+1;
	if ~isempty(nObjectMax) && nObjects>=nObjectMax
		break
	end
end		% while data to be read
cStat.close()
f.fclose();
OO{nOO} = OO{nOO}(1:nOOi);

O = [OO{1:nOO}];
D = var2struct(H,O);

function [ts,t,ix] = ExtractTime(x,ix)
W = typecast(x(ix+1:ix+16),'uint16');
year = W(1);
month = W(2);
d_week = W(3);
d_month = W(4);
hour = W(5);
minute = W(6);
second = W(7);
i_sec = W(8);
f_sec = double(i_sec)/1000;
ix = ix+16;
ts = var2struct(year,month,d_week,d_month,hour,minute,second,f_sec);
t = datetime(year,month,d_month,hour,minute,second,i_sec);

function [B,ix] = ReadBlock(x,ix)
while ix<length(x) && x(ix+1)==0
	ix = ix+1;
end
if length(x)-ix<32
	B = [];	% the end
	return
end
if ~strcmp(char(x(ix+1:ix+4)),'LOBJ')
	warning('Wrong start - reading stopped')
	% look for next LOBJ or check for LOGG?
	B = [];
	return
end
ii = typecast(x(ix+5:ix+32),'uint16');
lObj = ii(3);
ixN = ix+double(lObj);
try
	B = zuncompr(x(ix+33:ixN));
	ix = ixN;
catch err
	DispErr(err)
	warning('Error while decompressing!')
	B = [];
	return
end

function [B,ix] = ReadObject(x,ix)
while ix<length(x) && x(ix+1)==0
	ix = ix+1;
end
if length(x)-ix<32
	B = [];	% the end
	return
end
if ~strcmp(char(x(ix+1:ix+4)),'LOBJ')
	printhex(x(ix+1:ix+16))
	warning('Wrong start - searching for new start')
	while length(x)-ix>32 && ~strcmp(char(x(ix+1:ix+4)),'LOBJ')
		ix = ix+1;
		while length(x)-ix>32 && x(ix+1)~='L'
			ix = ix+1;
		end
	end
	if ~strcmp(char(x(ix+1:ix+4)),'LOBJ')
		% look for next LOBJ or check for LOGG?
		B = [];
		return
	end
end
ii = typecast(x(ix+5:ix+32),'uint16');
lObj = ii(3);
typObj = ii(5);
ixN = ix+double(lObj);
if ixN>length(x)
	warning('ixN is too large??!! (%d <-> %d)',ixN,length(x))
	ixN = length(x);
	lObj = ixN-ix;	%!!!!!!
end

if typObj==1 || typObj==86	% CAN message
	t = typecast(x(ix+25:ix+32),'uint64');
	% use other data to know if it's 10^-5 sec or nsec
	channel = x(ix+33);
	dlc = x(ix+36);
	ID = bitand(typecast(x(ix+37:ix+40),'uint32'),0x1fffffff);
	bExt = x(ix+40)>127;
	typ = x(ix+35);
	data = x(ix+41:ix+40+double(dlc));
	extra = x(49:ixN);
	B = var2struct(t,channel,typ,dlc,ID,bExt,data,extra);
elseif typObj==65	% text
	B = {typObj,{ii,x(ix+33:ix+48)},deblank(char(x(ix+49:ixN)))};
else
	B = {typObj,ii,x(ix+33:ixN)};
end
ix = ixN;
