function printhex(x,f,offset,s0,varargin)
% UINT16/PRINTHEX - print gegevens in hexadecimale vorm
%     printhex(x,f,offset,s0)
%        f kan een file-ID zijn of een filename
%        offset kan een getal of een hexadecimale string zijn
%        s0 is een string die vooraan de tekst toegevoegd wordt (bij elke lijn)

cEndian=[];
bBigEndian=[];
bLittleEndian=[];
if ~isempty(varargin)
	setoptions({'cEndian','bBigEndian','bLittleEndian'},varargin{:})
	if ~isempty(bLittleEndian)
		if bLittleEndian
			cEndian='L';
		else
			cEndian='B';
		end
	elseif ~isempty(bBigEndian)
		if bBigEndian
			cEndian='B';
		else
			cEndian='L';
		end
	end
end
xT=x(:)';
if ~isempty(cEndian)
	cEndian=upper(cEndian(1));
	if cEndian=='L'
		xT=swapbytes(x(:)');
	elseif cEndian~='B'
		error('(B)ig or (L)ittle endian!')
	end
end

if ~exist('offset','var');offset=[];end
if isempty(offset)
	offset=0;
elseif ischar(offset)
	offset=sscanf(offset,'%x');
end
nok=[0:31 127:255];	% !!
pos=cumsum([1 5 6 5 6 5 6 5]);
pos1=45;
ckonv=0:255;
ckonv(nok+1)=(127-ismac)*ones(1,length(nok));	% 127 is not printed on mac
s='xxxx xxxx  xxxx xxxx  xxxx xxxx  xxxx xxxx -0123456789abcdef';
bFileOwner=false;
if ~exist('f','var')||isempty(f)
	f=1;
elseif ischar(f)
	f=fopen(f,'w');
	if f<3
		error('Can''t open the file')
	end
	bFileOwner=true;
end
if length(x)-1+offset>65535
	form='%08x : %s\n';
else
	form='%04x : %s\n';
end
if exist('s0','var')
	form=[s0 form];
end
for i=1:8:length(x)
	l=min(i+7,length(x));
	for j=i:i+7
		if j>length(x)
			s(pos(j-i+1):pos(8)+3)=' ';
			s(pos1+(l-i+1)*2:length(s))=[];
			break;
		else
			s(pos(j-i+1):pos(j-i+1)+3)=sprintf('%04x',x(j));
		end
	end
	X1=xT(i:l);
	S=[bitshift(X1,-8);bitand(X1,uint16(255))]+1;
	s(pos1:pos1+(l-i)*2+1)=sprintf('%c',ckonv(S(:)));
	fprintf(f,form,i-1+offset,s);
end
if bFileOwner
	fclose(f);
end
