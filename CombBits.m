function [X,nX]=CombBits(X,idx,nX)
%CombBits - Combine bits in array for compact plotting
%
%         X=CombBits(X,idx);
%         [X,nX]=CombBits(X,idx,nX)
%             idx indexes of bits to be combined
%                cell array of sets of indexes
%
%  1. X=CombBits(X,idx);
%    It's not really combining that's done, but changing the values so that
%    they don't overlap when plotting together:
%        if ~=0 ---> 0.5, otherwise 0
%           1st data ---> +0
%           2nd      ---> +1
%           ...
%  2. [X,nX]=CombBits(X,idx,nX)
%    Data is combined as separate bits in one value (integer).
%    As name of the channel you get '#<chan1>#<chan2...'.

if iscell(idx)
	if nargin<3
		nX=[];
	end
	for i=1:length(idx)
		[X,nX]=CombBits(X,idx{i},nX);
	end
	return
end

if isempty(idx)
	return
end
if islogical(X)
	X=double(X);
else
	X(:,idx)=X(:,idx)~=0;
end
if length(idx)==1
	return;
end

if nargin<3||isempty(nX)
	for i=1:length(idx)
		X(:,idx(i))=X(:,idx(i))*.5+(i-1);
	end
else
	k=1;
	C=0;
	for i=1:length(idx)
		C=C+X(:,idx(i))*k;
		k=k*2;
	end
	X(:,idx(1))=C;
	X(:,idx(2:end))=[];
	nX{idx(1)}=sprintf('#%s',nX{idx});
	nX(idx(2:end))=[];
end
