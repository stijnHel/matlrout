function X=CombineVectors(varargin)
%CombineVectors - Make an array from multiple vectors
%    The largest vector is taken, and others are zero-padded
%         X=CombineVectors(...)

% idea options by checking the first char-varargin
%     make row vectors
%     allow matrices
%     if column vectors ==> combine in rows rather than in columns
%     free padding value (NaN, Inf, ...)
%     combine data of different types (uint8, double, ...)

xPad=0;
[bColVectors]=[];

V=varargin;
nV=length(V);
Bchar=cellfun(@ischar,V);
if any(Bchar)
	i=find(Bchar,1);
	setoptions({'xPad','bColVectors'},varargin{i:nV})
	nV=i-1;
	V=V(1:nV);
end
Bcolumn=cellfun(@iscolumn,V);
if isempty(bColVectors)
	bColVectors=any(Bcolumn);	% if any vector is column, use column vector
end

N=cellfun('length',V);
nMax=max(N);
for i=1:length(V)
	if bColVectors
		if isrow(V{i})
			V{i}=V{i}(:);
		end
	elseif iscolumn(V{i})
		V{i}=V{i}';
	end
	if N(i)<nMax
		if bColVectors
			V{i}(end+1:nMax,:)=xPad;
		else
			V{i}(:,end+1:nMax)=xPad;
		end
	end
end

% check types
[bFl,nB,bS]=TypeInfo(V{1});
	%!!!!! e.g. combination of uint16 and int16!!!!!  ==> can lead to overflow
bChange=false;
for i=2:length(V)
	[bFl1,nB1,bS1]=TypeInfo(V{i});
	bChange=bChange || bFl~=bFl1 || nB~=nB1 || bS~=bS1;
	if bFl1 && ~bFl
		bFl=bFl1;
		if nB1<64&&nB>=32
			nB1=64;	% force double if combined floats with 32(or more) bit integers
		end
	elseif bFl && ~bFl1
		if nB<64&&nB1>=32
			nB=64;
		end
	elseif ~bFl&&~bFl1&&bS~=bS1
		if bS && nB==nB1	% combine equal sized signed and unsigned numbers
			% test extremes?
			if nB1>32	% keep(!!)
				warning('Overflow might happen!! combining signed and unsigned numbers')
			else
				nB=nB*2;
			end
		end
	end
	bS=bS||bS1;
	nB=max(nB,nB1);
end
if bChange
	if bFl
		if nB>32
			tp='double';
		else
			tp='single';
		end
	else
		if nB>32
			tp='int64';
		elseif nB>16
			tp='int32';
		elseif nB>8
			tp='int16';
		else
			tp='int8';
		end
		if ~bS
			tp=['u' tp];
		end
	end
	for i=1:length(V)
		if ~isa(V{i},tp)
			V{i}=cast(V{i},tp);
		end
	end
end

if bColVectors
	X=cat(2,V{:});
else
	X=cat(1,V{:});
end

function [bIsFloat,nBits,bSigned]=TypeInfo(v)
bIsFloat=isfloat(v);
if bIsFloat
	if isa(v,'single')
		nBits=32;
	else
		nBits=64;
	end
	bSigned=true;
else
	tp=class(v);
	x=zeros(1,1,tp);	% to handle empty inputs correctly
	nBits=length(typecast(x,'uint8'))*8;
	bSigned=tp(1)~='u' && tp(1)~='l';
end
