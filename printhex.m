function printhex(x,f,offset,s0)
% PRINTHEX - print gegevens in hexadecimale vorm
%     printhex(x,f,offset,s0)
%        f kan een file-ID zijn of een filename
%        offset kan een getal of een hexadecimale string zijn
%        s0 is een string die vooraan de tekst toegevoegd wordt (bij elke lijn)
if ~exist('offset','var');offset=[];end
if isempty(offset)
	offset=0;
elseif ischar(offset)
	offset=sscanf(offset,'%x');
end
x=x(:);
if any(x>255)&&all(x>=0&x<=65535)
	if nargin==1
		A={};
	elseif nargin==2
		A={f};
	elseif nargin==3
		A={f,offset};
	elseif nargin==4
		A={f,offset,s0};
	end
	printhex(uint16(x),A{:})
	return
elseif any(x<0|x>255)&&all(x>=-32768&x<=32767)
	if nargin==1
		A={};
	elseif nargin==2
		A={f};
	elseif nargin==3
		A={f,offset};
	elseif nargin==4
		A={f,offset,s0};
	end
	printhex(int16(x),A{:})
	return
end
x=floor(double(x(:)));
if min(x)<0
	error('x moet minimaal 0 zijn');
end
if max(x)>255
	error('x moet maximaal 255 zijn');
end
%nok=[0:31 127:144 147:159];
%nok=[0:31 127:144 147:159 192:255];	% !!
nok=[0:31 127:255];	% !!
pos=[1:3:10 14:3:23 27:3:36 40:3:49];
pos1=53;
ckonv=0:255;
%ckonv(nok+1)=(127-ismac)*ones(1,length(nok));	% 127 is not printed on mac
ckonv(nok+1)=126*ones(1,length(nok));	% windows ook niet meer...
s='xx xx xx xx  xx xx xx xx  xx xx xx xx  xx xx xx xx -0123456789abcdef';
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
for i=1:16:length(x)
	l=min(i+15,length(x));
	bNaN=false;
	for j=i:i+15
		if j>length(x)
			s(pos(j-i+1):pos(16)+1)=blanks(pos(16)+2-pos(j-i+1));
			s(pos1+l-i+1:length(s))=[];
			break;
		elseif isnan(x(j))
			s(pos(j-i+1):pos(j-i+1)+1)='--';
			bNaN=true;
		else
			s(pos(j-i+1):pos(j-i+1)+1)=sprintf('%02x',x(j));
		end
	end
	if bNaN
		x1=x(i:l);
		bx1=isnan(x1);
		s(pos1-1+find(bx1))=' ';
		s(pos1-1+find(~bx1))=sprintf('%c',ckonv(x1(~bx1)+1));
	else
		s(pos1:pos1+l-i)=sprintf('%c',ckonv(x(i:l)+1));
	end
	fprintf(f,form,i-1+offset,s);
end
if bFileOwner
	fclose(f);
end
