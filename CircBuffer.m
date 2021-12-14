%CircBuffer - Class implementing a circular buffer
%
% example:
%    B = CircBuffer('type','uint8','size',1000);
%    B.add(uint8([1,2,3,4]);
%    B.add(uint8([5:10]);
%    y1 = B.get();
%    y2 = B.getN(3);
%    nLeft = B.available();
%    y3 = B.getN();

classdef CircBuffer < handle
	properties
		BUFFER
		type = 'double';
		lBuffer = 1000;
		idxAdd
		idxGet
		nAvail	% redundant information(!)
		bFull
	end		% properties
	
	methods
		function c=CircBuffer(size,type)
			if nargin<2
				type = [];
				if nargin==0
					size = [];
				end
			end
			if ~isempty(size)
				c.lBuffer = size;
			end
			if ~isempty(type)
				c.type = type;
			end
			if c.lBuffer<2
				error('Sorry, but a buffer is only useful if more than 1 element wide!')
			end
			c.BUFFER=zeros(c.lBuffer,1,c.type);
			c.idxAdd = 1;
			c.idxGet = 1;
			c.nAvail = 0;
			c.bFull = false;
		end		% CircBuffer (constructor)
		
		function add(c,X)
			if ~isvector(X)
				c.bufferError('Only vectors can be added!!')
			elseif isempty(X)
				return	% do nothing
			end
			nToAdd = length(X);
			nAvailNext = c.nAvail+nToAdd;
			if c.bFull||nAvailNext>c.lBuffer
				c.bufferError('Buffer overfull!')
			end
			n1 = c.lBuffer-c.idxAdd+1;
			if n1<nToAdd
				c.BUFFER(c.idxAdd:c.lBuffer)=X(1:n1);
				n2 = nToAdd-n1;
				c.BUFFER(1:n2) = X(n1+1:nToAdd);
				c.idxAdd = n2+1;
			else
				idxAddNext = c.idxAdd+nToAdd;
				c.BUFFER(c.idxAdd:idxAddNext-1) = X;
				if idxAddNext>c.lBuffer
					c.idxAdd = 1;
				else
					c.idxAdd = idxAddNext;
				end
			end
			c.nAvail = c.nAvail+nToAdd;
			c.bFull = c.nAvail>=c.lBuffer;
		end		% add
		
		function y=get(c)
			if ~c.bFull&&c.idxAdd~=c.idxGet
				y = c.BUFFER(c.idxGet);
				c.idxGet = c.idxGet+1;
				if c.idxGet>c.lBuffer
					c.idxGet=1;
				end
			else
				c.bufferError('Buffer empty!')
			end
			c.nAvail = c.nAvail-1;
			c.bFull = false;
		end		% get
		
		function y=getN(c,n)
			if nargin<2||isempty(n)
				n=c.nAvail;	% all
			end
			if n==0||c.nAvail==0
				if n>0
					warning('More data requested than available!')
				end
				y=zeros(0,1,c.type);
				return
			end
			if n>c.nAvail
				warning('More data requested than available!')
				n = c.nAvail;
			end
			n1 = c.lBuffer-c.idxGet+1;	% data available until end of buffer
			if n1>n		% all requested data is before end of buffer
				idxGetNext = c.idxGet+n;
				y = c.BUFFER(c.idxGet:idxGetNext-1);
				if idxGetNext>c.lBuffer
					idxGetNext = 1;
				end
				c.idxGet=idxGetNext;
			else
				n2 = n-n1;	% number of elements requested at the start of the buffer
				y = [c.BUFFER(c.idxGet:c.lBuffer);
					c.BUFFER(1:n2)];
				c.idxGet = n2+1;
			end
			c.nAvail = c.nAvail-n;
			c.bFull = false;
		end		% getN
		
		function y=preview(c,n)
			if nargin<2||isempty(n)
				n=c.nAvail;	% all
			end
			if n==0||c.nAvail==0
				if n>0
					warning('More data requested than available!')
				end
				y=zeros(0,1,c.type);
				return
			end
			if n>c.nAvail
				warning('More data requested than available!')
				n = c.nAvail;
			end
			n1 = c.lBuffer-c.idxGet+1;
			if n1>n
				idxGetNext = c.idxGet+n;
				y = c.BUFFER(c.idxGet:idxGetNext-1);
			else
				n2 = n-n1;
				y = [c.BUFFER(c.idxGet:c.lBuffer);
					c.BUFFER(1:n2)];
			end
		end		% preview
		
		function i=find(c,x)
			if c.nAvail==0
				i=[];
			else
				n1=c.lBuffer-c.idxGet+1;
				if n1>c.nAvail
					i=find(c.BUFFER(c.idxGet:c.idxGet+c.nAvail-1)==x,1);
				else
					i=find(c.BUFFER(c.idxGet:c.lBuffer)==x,1);
					if isempty(i)
						i=find(c.BUFFER(1:c.nAvail-n1)==x,1);
						if ~isempty(i)
							i=i+n1;
						end
					end
				end
			end
		end		% find
		
		function n=available(c)
			if c.bFull
				n = c.lBuffer;
			elseif c.idxAdd~=c.idxGet
				if c.idxAdd>c.idxGet
					n = c.idxAdd-c.idxGet;
				else
					n = c.lBuffer-c.idxGet+c.idxAdd;
				end
			else
				n = 0;
			end
		end		% available
		
		function clear(c,newSize,newType)
			if nargin>2&&~isempty(newType)
				c.type = newType;
			end
			if nargin>1&&~isempty(newSize)
				c.lBuffer=newSize;
				c.BUFFER=zeros(newSize,1,c.type);
			end
			c.idxAdd = 1;
			c.idxGet = 1;
			c.nAvail = 0;
			c.bFull = false;
		end		% clear
		
		function bufferError(c,s) %#ok<INUSL>
			% allow different types of handling
			error(s)
		end		% bufferError
		
	end		% methods
end		% CircBuffer
