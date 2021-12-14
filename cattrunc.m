function Z=cattrunc(dim,varargin)
%cattrunc - concatenate arrays with truncation and/or zero-padding
%    Z=cattrunc(dim,data1,...)
%       concatenates to shortest length
%           dim gives dimension (see cat)
%    Z=cattrunc([dim length],data1,...);
%       concatenates to a specific length
%    Z=cattrunc([dim Inf],data1,...);
%       concatenates with zero padding to longest length
%  Multiple dimensions are possible.
%     the first use (truncation) works the same.
%     for other possibilities, the inputs should be:
%        Z=cattrunc({dim sizes},data1,...);
%         the sizes are the dimensions different from the growing dimension
%  The number of dimensions should always be the same.

if iscell(dim)
	error('Sorry, but documentaion is earlier than implementation!! only simple imputs are possible')
end

nDims=cellfun('ndims',varargin);
if any(nDims~=nDims(1))
	error('All data must have the same number of dimensions')
end
nDims=nDims(1);
S=zeros(length(varargin),nDims);
for i=1:nDims
	S(:,i)=cellfun('size',varargin,i);
end
catDim=dim(1);
if nDims<catDim
	nDims=catDim;
	S(end+1:nDims)=1;
end

D=min(S);
if length(dim)>1
	if isinf(dim(2))
		D=max(S);
	else
		D(:)=dim(2);	% !now square matrices are made with multidimensional input!!!
	end
end
D(catDim)=sum(S(:,catDim));
Z=zeros(D);
iZ=0;
ss=cell(1,nDims);
for i=1:length(varargin)
	for j=1:nDims
		if j==catDim
			ss{j}=1:S(i,j);
			ss1=iZ+1:iZ+S(i,j);
		else
			ss{j}=1:min(S(i,j),D(j));
		end
	end
	Z1 = subsref(varargin{i},substruct('()',ss));
	ss{catDim}=ss1;
	Z=subsasgn(Z,substruct('()',ss),Z1);
	iZ=ss1(end);
end
