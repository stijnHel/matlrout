function [e,nParts,tHS,tLS]=reformatTDMS(e,gegs,varargin)
%reformatTDMS - Reformat TDMS-read data
%   [e,nParts,tHS,tLS]=reformatTDMS(e,ne,gegs[,options])
%      nParts : number of parts (channels) in one block
%
% options
%     bReshape : reshapes the data from blocks next to each other to
%        [default] : linear block (blocks under each other)
%        3D (option b3Dreshape) : blocks in 2D, 3d dimension for blocks
%                [ch1_1 ch2_1 ... ch_1_2 ch_2_2 ...]
%                    ---> e(:,:,<block-nr>) = [ch1_nr ch2_nr ...]
%     b3Dreshape : see above
%     bUseTimegap : with linear reshape, tHS has gaps for time between
%                   blocks

bReshape=true;
bUseTimegap=true;
b3Dreshape=false;

if ~isempty(varargin)
	setoptions({'bReshape','bUseTimegap','b3Dreshape'},varargin{:})
end
bReshape=bReshape||b3Dreshape;
nParts=length(gegs.chanInfo);
if rem(size(e,2),nParts)
	error('Wrong set of blocks')
end
nBlocks=size(e,2)/nParts;
sizeBlock=size(e,1);
if bReshape
	if b3Dreshape
		e=reshape(e,size(e,1),nParts,nBlocks);
	else
		i=1:nParts:size(e,2);
		j=(0:nParts-1)';
		IJ=i(ones(1,nParts),:)+j(:,ones(1,nBlocks));
		e=reshape(e(:,IJ'),[],nParts);
		% why not done with permute?
	end
end
tHS=(0:size(e,1)-1)*gegs.dt;
if length(gegs.groups)==length(gegs.tBlocks)
	tLS=gegs.tBlocks-gegs.tBlocks(1);
else
	tLS=gegs.tBlocks(1:nParts:end)-gegs.tBlocks(1);
end
if bUseTimegap&&bReshape&&~b3Dreshape
	ie=sizeBlock;
	for i=2:nBlocks
		t=max(tLS(i),tHS(ie)+gegs.dt);
		ie2=ie+sizeBlock;
		tHS(ie+1:ie2)=tHS(ie+1:ie2)+(t-tHS(ie+1));
		ie=ie2;
	end
end
