function [D,T]=readLVvariantData(fn,varargin)
%readLVvariantData - Reads variant data from labView
%  D=readLVvariantData(fn)
%
%  This is not standard labView-data:
%     (using Variant to flattened string)
%      first the type-data has to be stored (int16-array)
%      than the data has to be stored (with array size saved)
% Standard use: for file that has been written with
%       type and data written as arrays with length
%       output is converted by lvData2struct
% other use:
%     D=readLVvariantData(fn,1);
%        for data without length (is taken from type description)
%     D=readLVvariantData(fn,0);
%        read until the end
%
%   see also readStructLVdata

bMyFile = ischar(fn) || isstring(fn);
if bMyFile
	fid=fopen(fn,'r','ieee-be');
	if fid<3
		fid=fopen(zetev([],fn),'r','ieee-be');
		if fid<3
			error('Can''t open the file')
		end
	end
else
	fid=fn;
end

nD=[];
nMax=1e4;
[bSimplify]=false;
if nargin>1
	if isnumeric(varargin{1})
		nD=varargin{1};
		options=varargin(2:end);
	else
		options=varargin;
	end
	setoptions({'nMax','bSimplify'},options{:})
end

lXt=fread(fid,1,'int32');
xt=fread(fid,[1 lXt],'uint16');
T=readLVtypeString(xt);
nD0=1;
if ~isempty(nD)
	if all(cellfun('isreal',T(:,3)))
		lXs=sum(cat(1,T{:,3}));
	else
		lXs=-1;
	end
	nD0=nD;
	if nD==0
		nD=nMax;
	end
else
	lXs=fread(fid,1,'int32');
	nD=1;
end
if lXs>0
	xs=fread(fid,[lXs nD],'uint8');
else
	xs=fread(fid,'uint8');
end
if nD0==0&&size(xs,2)==nD
	pF=ftell(fid);
	fseek(fid,0,'eof');
	eF=ftell(fid);
	if eF>pF
		warning('not everything measured (%d/%1.0f)',nD,nD+(eF-pF)/lXs);
	end
end
if bMyFile
	fclose(fid);
end
if lXs>0
	for i=1:size(xs,2)
		d=readLVtypeString(T,xs(:,i));
		D1=lvData2struct(d);
		if i==1
			D=D1(1,ones(1,size(xs,2)));
		else
			D(i)=D1;
		end
	end
else
	%!!!!!!!!!!!!!!!!!!for data with saved data
	I=zeros(2,floor(length(xs)/4));
	ix=1;
	nI=0;
	while ix<length(xs)
		nI=nI+1;
		I(2,nI)=[16777216 65536 256 1]*xs(ix:ix+3,1);
		ix=ix+4;
		I(1,nI)=ix;
		ix=ix+I(2,nI);
	end
	for i=1:nI
		d=readLVtypeString(T,xs(I(1,i):I(1,i)+I(2,i)-1));
		D1=lvData2struct(d);
		if i==1
			D=D1(1,ones(1,nI));
		else
			D(i)=D1;
		end
	end
end
if bSimplify
	D=Simplify(D);
end

function D=Simplify(D)
if isstruct(D)&&isscalar(fieldnames(D))
	fn=fieldnames(D);
	fn=fn{1};
	C={D.(fn)};
	if all(cellfun(@isstruct,C))&&(isscalar(D)||all(cellfun(@isscalar,C)))
		D=[C{:}];
		D=Simplify(D);
	end
end
