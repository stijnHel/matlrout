classdef vectorFile < handle
	%vectorFile - class handling a large file as it is a (read only) vector

	% (use of now can delay the usage a lot!!! - but this is addded to keep
	%  actively used blocks in memory)
	
	properties
		name
		cFile
		blockLength		% size of blocks read at once
		BLOCKS	% set of blocks - indices are given in BLOCKSidx (ordered)
		BLOCKSidx	% i1,i2,tUsed (ordered)
	end		% properties
	
	methods
		function c = vectorFile(fName,varargin)
			blockLength = 131072;
			if nargin>1
				setoptions({'blockLength'},varargin{:})
			end
			c.blockLength = blockLength;
			c.cFile = file(fName);
			[~,c.name] = fileparts(c.cFile.fName);
			xStart = c.cFile.fread([1 c.blockLength],'*uint8');
			c.BLOCKS = cell(1,20);
			c.BLOCKS{1} = xStart;
			c.BLOCKSidx = zeros(length(c.BLOCKS)+1,3);
			c.BLOCKSidx(1) = 1;
			c.BLOCKSidx(1,2) = length(xStart);
			c.BLOCKSidx(1,3) = now;
			c.BLOCKSidx(end,1) = c.cFile.length()+1;
			c.BLOCKSidx(end,3) = 1e9;
		end		% vectorFile
		
		function iB = FindBlock(c, i1, i2)
			%FindBlock - Find the block with at least the start (i1)
			iB = 1;
			while c.BLOCKSidx(iB)>0 && i1>c.BLOCKSidx(iB,2)
				iB = iB+1;
			end
			if c.BLOCKSidx(iB)==0 || i1<c.BLOCKSidx(iB) || iB>length(c.BLOCKS)	% data not available
				bReplaceBlock = false;
				iNextAvail = 0;
				if c.BLOCKSidx(iB)==0	% free block
					% iB is OK
				elseif iB>length(c.BLOCKS)	% all blocks used - find the oldest
					bReplaceBlock = true;
					iB = iB-1;
					[~,i] = min(c.BLOCKSidx(:,3));	% block with oldest usage
				else
					iNextAvail = c.BLOCKSidx(iB);
					i = find(c.BLOCKSidx(:,1)==0,1);
					bReplaceBlock = true;
					if isempty(i)	% all blocks used - find the oldest
						[~,i] = min(c.BLOCKSidx(:,3));	% block with oldest usage
					end
				end
				if bReplaceBlock
					if i<iB
						c.BLOCKS(i:iB-1) = c.BLOCKS(i+1:iB);
						c.BLOCKSidx(i:iB-1,:) = c.BLOCKSidx(i+1:iB,:);
					elseif i>iB
						c.BLOCKS(iB+1:i) = c.BLOCKS(iB:i-1);
						c.BLOCKSidx(iB+1:i,:) = c.BLOCKSidx(iB:i-1,:);
					% else current block is replaced
					end
				end
				c.cFile.fseek(i1-1,'bof');	% does this take a long time?  --> in that case keep track of position
				n = max(i2+1-i1,c.blockLength);
				iNextEnd = i1-1+n;
				if iNextAvail && iNextEnd>=iNextAvail
					n = iNextAvail-i1;
				end
				x = c.cFile.fread([1 n],'*uint8');
				c.BLOCKS{iB} = x;
				c.BLOCKSidx(iB) = i1;
				c.BLOCKSidx(iB,2) = i1-1+length(x);
			end
		end		% FindBlock
		
		function B = subsref(c, S)
			if ~isscalar(S)||~strcmp(S.type,'()')||~isscalar(S.subs)
				error('Sorry, only simple indexing is allowed!')
			end
			tReq = now;
			subs = S.subs{1};
			if islogical(subs)	% for this type of object not expected!
				subs = find(subs);
			elseif ischar(subs)
				if strcmp(subs,':')
					warning('This class is made for large files, too large to read at once!  I''ll try...')
					c.cFile.fseek(0,'bof');
					B = c.cFile.fread([1 Inf],'*uint8');
				else
					error('Not implemented subs-type!')
				end
				return
			elseif isempty(subs)
				B = zeros(1,0,'uint8');
				return
			end
			i1 = min(subs);
			if i1<1
				subs(subs<1) = subs(subs<1)+c.cFile.length();
				i1 = min(subs);
			end
			i2 = max(subs);
			if i1<1 || i2>c.cFile.length()
				error('indices must be at least 1 and maximum the length of file (%d)!',c.cFile.length())
			end
			
			i = FindBlock(c, i1, i2);
			
			i1_2 = c.BLOCKSidx(i,2);
			c.BLOCKSidx(i,3) = tReq;	% mark as used
			if i2<=i1_2
				B = c.BLOCKS{i}(subs-(c.BLOCKSidx(i)-1));
			else
				B = zeros(1,i2-i1+1,'uint8');
				i0 = c.BLOCKSidx(i);
				n = c.BLOCKSidx(i,2)-i1+1;
				B(1:n) = c.BLOCKS{i}(i1+1-i0:end);
				iB = n;
				while true
					i = FindBlock(c, i1_2+1, i2);
					c.BLOCKSidx(i,3) = tReq;	% mark as used
					i2_1 = c.BLOCKSidx(i,2);
					if i2_1>=i2	% end
						B(iB+1:end) = c.BLOCKS{i}(1:i2+1-c.BLOCKSidx(i,1));
						break
					end
					n = length(c.BLOCKS{i});
					B(iB+1:iB+n) = c.BLOCKS{i};
					iB = iB+n;
					i1_2 = i2_1;
				end
				B = B(subs-(i1-1));	% in case subs is not i1,i1+1,...
			end		% not all from 1 block
		end		% subsref
		
		function c = subsasgn(c,S,B)
			error('Sorry, but this is only for read-only vectors!')
		end		% subsasgn
		
		function l = length(c)
			l = c.cFile.length();
		end		% length
		
	end		% methods
end		% vectorFile