function Dout=ShowBlocksHEX(x,varargin)
%ShowBlocksHEX - byte-data analysis tool: show blocks of nonzeros
%      [D=]ShowBlocksHEX(x)
%            D: blocks

%(!!) other constant blocks different from 0? (especially 255)

nZeroBlock = 30;
maxBlocksDisp = 30;
maxSizeBlockDisp = 512;
nShowLargeBlock = 128;
[bRoundIdx] = true;
[bIncludeData] = false;
[bPrint] = nargout==0;

if nargin>1
	setoptions({'nZeroBlock','maxBlocksDisp','maxSizeBlockDisp'	...
		,'nShowLargeBlock'	...
		,'bRoundIdx','bPrint','bIncludeData'	...
		},varargin{:})
end
nShowLargeBlock = min(nShowLargeBlock,maxSizeBlockDisp/2);

D = struct('iStart',cell(1,1000),'iEnd',[]);
nD = 0;

nx = length(x);
ix = 0;
while ix<nx
	ix = ix+1;
	while ix<=nx&&x(ix)==0
		ix = ix+1;
	end
	if ix<nx
		nD = nD+1;
		iStart = ix;
		
		while true
			ix = ix+1;
			if ix>nx
				break
			elseif x(ix)==0
				B = x(ix+1:min(nx,ix+nZeroBlock-1));
				if any(B)
					j = find(B,1,'last');
					ix=ix+j;
				else
					break
				end
			end		% x(ix)==0
		end		% while true
		iEnd = ix-1;
		
		if bPrint
			if nD>maxBlocksDisp
				if nD==maxBlocksDisp+1
					fprintf('...and more blocks....\n')
				end
			else
				if bRoundIdx
					iSshow = floor((iStart-1)/16)*16+1;
					iEshow = ceil((iEnd-1)/16)*16;
				else
					iSshow = iStart;
					iEshow = iEnd;
				end
				if iEshow-iSshow+1>maxSizeBlockDisp
					printhex(x(iSshow:iSshow+nShowLargeBlock-1),[],iSshow-1)
					if nShowLargeBlock*2<iEshow-iSshow+1
						fprintf('............\n')
					end
					printhex(x(iEshow-nShowLargeBlock+1:iEshow),[],iEshow-nShowLargeBlock)
				else
					printhex(x(iSshow:iEshow),[],iSshow-1)
				end
				fprintf('\n')
			end		% show block
		end		% bPrint
		
		D(nD).iStart = iStart;
		D(nD).iEnd = iEnd;
		if bIncludeData
			D(nD).block = x(iStart:iEnd);
		end
	end
end

if nargout
	Dout = D(1:nD);
end
