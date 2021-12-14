function X=readcantrace(fn)
%leescantrace - Reads a trace of canalizer

if ischar(fn)
	fid=fopen(fn);
	if fid<3
		error('Can''t open the file')
	end
	x=fread(fid);
	fclose(fid);
else
	x=fn;
end
head=x(1:65)';
t1=head(33:36)*[1;256;65536;16777216];
t2=head(37:40)*[1;256;65536;16777216];
t0=datenum(1970,1,1,2,0,0);
sT1=datestr(t0+t1/3600/24);
sT2=datestr(t0+t2/3600/24);
N=[1 256 65536 16777216]*reshape(head(41:64),4,6);
	% N(1), N(2), N(3) seem to have the number of messages
l=(length(x)-65)/24;
if l>floor(l)
	warning('?lost dataM')
end
x=reshape(x(66:floor(l)*24+65),24,[])';
lend=[1;256;65536;16777216];
t=x(:,1:4)*lend/10000;	% time given in 10000th of a second
ID=x(:,5:8)*lend;
n=x(:,9);
D=x(:,10:17);
E=x(:,18:end);
if any(E(:)~=0)
	%warning('Some "extra data" nonzero!')
	
end
X=struct('t',t,'ID',ID,'n',n,'D',D,'T',[sT1;sT2]	...
	,'N',N,'E',E,'head',head);
