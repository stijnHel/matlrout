function [V,ix,T] = readLVvariant(x,ix,bAll)
%readLVvariant - Read LabVIEW variant data (as written to disk)
%      [V,ix,T] = readLVvariant(x,ix,bAll)
%            x: uint8-vector
%            ix: bytes to skip (0 is start from beginning)
%            bAll: read all (otherwise read only 1)
%
%            V is the variant data
%            ix: last read byte
%            T: type of data
%
% see readLVtypeString

if nargin<2 || isempty(ix)
	ix = 0;
end

if nargin>2 && ~isempty(bAll) && bAll
	V = cell(2,ceil(length(x)/12));
	nV = 0;
	while ix<length(x)-10
		nV = nV+1;
		[V{1,nV},ix,V{2,nV}] = readLVvariant(x,ix);
	end
	if nargout>2
		T = V(2,1:nV);
	end
	V = V(1,1:nV);
	return
end

if x(ix+1)~=25
	error('Expected another starting byte!')
end
% what to do with bytes x(ix+2:ix+8)?

n = double(swapbytes(typecast(x(ix+9:ix+10),'uint16')));
ixN = ix+8+n;
Tdata = x(ix+9:ixN);
ix = ixN;
if ~all(x(ix+1:ix+4)==uint8([0 1 0 0]))
	warning('Different from what expected!')
end
ix = ix+4;
[V,T,n] = readLVtypeString(Tdata,x(ix+1:end));	%(!!!)
if iscell(V) && isequal(size(V),[1 2])	% {value,name}
	V = V{1};
end
ix=ix+n+3;
