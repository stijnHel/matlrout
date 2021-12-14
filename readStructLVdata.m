function D=readStructLVdata(fname)
%readStructLVdata - Read structured LabVIEW data (variant - type+data)
%     D=readStructLVdata(fname)
%
% Type and Data comes from "variant to flattened string".
% Only one type is allowed now, in two possible ways:
%     <type> <data1> <type> <data2> ...
% or
%     <type> <data1> <data2>
%
%  see also readLVvariantData

BE32=[167772 65536 256 1];

fid=fopen(zetev([],fname),'r','ieee-be');
if fid<3
	error('Can''t open the file')
end

lXt=fread(fid,1,'int32');
xt=fread(fid,[1 lXt],'uint16');
x=fread(fid,'*uint8');
fclose(fid);
T=readLVtypeString(xt);
n=BE32*double(x(1:4));
D1=readLVtypeString(T,x(5:4+n));
D=lvData2struct(D1);
ix=5+n;
i1=BE32*double(x(ix:ix+3));
bType=i1==lXt;
if bType
	nEst=ceil((length(x)+4+lXt*2)/(lXt*2+8+n));
else
	nEst=ceil(length(x)/(4+n));
end
D(1,nEst)=D;
nD=1;
while ix<length(x)
	if bType
		ix=ix+4+2*lXt;
	end
	n=BE32*double(x(ix:ix+3));
	D1=readLVtypeString(T,x(ix+4:ix+3+n));
	ix=ix+4+n;
	nD=nD+1;
	D(nD)=lvData2struct(D1);
end
D=D(1:nD);
