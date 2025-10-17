function [D,fFull] = ReadGenLVlog(fName,varargin)
%ReadGenLVlog - Read "generic LabVIEW data" (blocks of timestamp and "data")
%      D = ReadGenLVlog(fName,...)

fFull = fFullPath(fName,false,'.bin');
f = file(fFull,'rb','ieee-be');
lFile = length(f);
n1 = f.fread(1,'int32');
lBlock = n1+4;
nBlocks = lFile/lBlock;
if nBlocks<=1
	error('Something wrong?!')
end
if nBlocks>floor(nBlocks)
	warning('Varying block lengths, or broken file (or something else)?')
end
f.fseek(0,'bof');
X = f.fread([lBlock,nBlocks],'*uint8');
iX0 = 4;
if size(X,2)>1
	if any(X(1:4,1)~=X(1:4,:),"all")
		X = ReshapeX(X,f.fread());
		iX0 = 0;
	end
end
T = lvtime(X(iX0+1:iX0+16,:));
data = X(iX0+17:end,:);

D = var2struct(T,data,X);

function X = ReshapeX(X,x)
x = [X(:);x(:)];
% first count number of blocks
nX = 0;
ix = 0;
lMax = 0;
while ix<=length(x)-4
	n = double(swapbytes(typecast(x(ix+1:ix+4),'int32')));
	ix = ix+4;
	if n<16 || ix+n>length(x)
		warning('broken or wrong data?')
		break
	end
	lMax = max(lMax,n);
	ix = ix+n;
	nX = nX+1;
end
% Now fill X
X = zeros(lMax,nX,'uint8');
ix = 0;
for iX = 1:nX
	n = double(swapbytes(typecast(x(ix+1:ix+4),'int32')));
	ix = ix+4;
	X(1:n,iX) = x(ix+1:ix+n);
	ix = ix+n;
	nX = nX+1;
end
