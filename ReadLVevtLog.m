function E = ReadLVevtLog(fName)
%ReadLVevtLog - Read LabVIEW event log
%     E = ReadLVevtLog(fName)

fid = fopen(fName,'rb');
if fid<3
	error('Can''t open the file!')
end
x = fread(fid,[1 Inf],'*uint8');
fclose(fid);

E = struct('t',cell(1,1000),'iEvent',[],'sEvent','');
nE = 0;

ix = 0;
while ix<length(x)
	if length(x)-ix<24
		warning('File is broken?')
		break
	end
	if nE>=length(E)
		E(nE+1000).t = [];
	end
	t = lvtime(x(ix+1:ix+16));
	i = typecast(x(ix+20:-1:ix+17),'int32');
	ls = typecast(x(ix+24:-1:ix+21),'uint32');
	ix = ix+24;
	ixN = ix + double(ls);
	if ixN>length(x)
		warning('Something went wrong (reading string beyond the end of file)!')
		ixN = length(x);
	end
	nE = nE+1;
	E(nE).t = t;
	E(nE).iEvent = i;
	E(nE).sEvent = char(x(ix+1:ixN));
	ix = ixN;
end
if nE<length(E)
	E = E(1:nE);
end
