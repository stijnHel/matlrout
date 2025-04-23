function D = ReadParquet(fName)
%ReadParquet - Read Parquet file
%  (just started!!!!)
%      D = ReadParquet(fName)

% see https://parquet.apache.org/docs/file-format/
%   metadata: https://github.com/apache/parquet-format/blob/master/src/main/thrift/parquet.thrift

if isa(fName,'uint8')
	% (only for development...)
	x = fName;
else
	fid = fopen(fFullPath(fName));
	x = fread(fid,[1 Inf],'*uint8');
	fclose(fid);
end

if ~isequal(x(1:4),'PAR1')
	error('Wrong start?!')
end
if ~isequal(x(end-3:end),'PAR1')
	error('Wrong end?!')
end

lFoot = double(typecast(x(end-7:end-4),'uint32'));
iFootStart = length(x)-7-lFoot;
FootRaw = x(iFootStart:end-8);

% using apache-info didn't work....(?!)
%   search for serialization (Compact...)
ix = 18;
C = cell(100,2);
nC = 0;
while FootRaw(ix+1)==0 && FootRaw(ix+2)==21	%!!!!!!!!!!!!!!!!!
	h = FootRaw(ix+1:ix+6);
	ixn = ix+7;
	l = double(FootRaw(ixn));
	ix = ixn;
	ixn = ix+l;
	s = char(FootRaw(ix+1:ixn));
	ix = ixn;
	nC = nC+1;
	C{nC,1} = h;
	C{nC,2} = s;
end
C = C(1:nC,:);
xAfterC = FootRaw(ix+1:ix+128);





D = var2struct(C,xAfterC,iFootStart,x,ix,FootRaw);
