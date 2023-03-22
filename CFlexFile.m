classdef CFlexFile < handle
	%CFlexFile - "Flexible file" - can be a real file, or a "memory file"
	%    f = CFlexFile(<filename>,...)  - creates a "normal file"
	%    f = CFlexFile(<start-size>,...) - creates a memory file
	%            start-size: length of starting buffer
	%                 if not given / empty / 0 ==> default size
	%
	%  This class is created as a replacement of an old simple "local
	%  write function".
	
	properties
		bMemFile
		f
		buffer
		n
	end
	
	methods
		function c = CFlexFile(fName,varargin)
			if nargin<1 || isempty(fName)
				fName = 0;
			end
			if isnumeric(fName)
				if fName==0
					fName = 10000;
				end
				c.buffer = char(zeros(1,fName));
				c.f = 0;
				c.bMemFile = true;
			else
				c.f = fopen(fName,varargin{:});
				if c.f<3
					error('Can''t open the file!')
				end
				c.bMemFile = false;
			end
			c.n = 0;
		end
		
		function printf(c,varargin)
			if c.bMemFile
				s = sprintf(varargin{:});
				if length(c.buffer)<c.n+length(s)
					c.buffer(length(c.buffer)+length(s)+10000)=0;
				end
				nNext = c.n+length(s);
				c.buffer(c.n+1:nNext) = s;
				c.n = nNext;
			else
				fprintf(c.f,varargin{:});
			end
		end
		
		function close(c)
			if ~c.bMemFile
				fclose(c.f);
				c.f = -1;
			end
		end
		
		function s = get(c)
			if c.bMemFile
				s = c.buffer(1:c.n);
			else
				error('Sorry - but reading the "real file" is not foreseen!')
			end
		end
	end
end		% CFlexFile
