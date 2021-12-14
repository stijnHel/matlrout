%file     - Class for file handling, mainly to avoid hanging open files
%     c = file(filename[...])

classdef file < handle
	
	properties
		fName				% filename
		fid=0;				% file id
		fSelOPtions	= {};	% options for file selection
		len=-1;
		fopenOptions = {};
	end
	
	methods
		function c=file(fName,varargin)
			if nargin==0
				fName=[];
			end
			fName=fFullPath(fName);
			if ~isempty(fName)&&ischar(fName)
				c.fName=fName;
				c.fopenOptions=varargin;
				fopen(c,c.fopenOptions{:});
				if c.fid<3
					error('Can''t open the file! (%s)',fName)
				end
			else
				c.fName=[];
				if iscell(fName)
					if nargin>1
						error('In case of cell-input, only one argument is allowed!')
					end
					options=fName;
				else
					options=varargin;
					if isscalar(options)&&iscell(options{1})
						options=options{1};
					end
				end
				c.fSelOPtions = options;
			end
		end		% file
		
		%file/fclose - closes the file
		function fclose(c)
			if c.fid<3
				error('Can''t close the file if it''s not open!')
			end
			fclose(c.fid);
			c.fid=0;
		end		% fclose
		
		%file/fcloseif - closes the file if open
		function fcloseif(c)
			if c.fid>=3
				fclose(c.fid);
				c.fid=0;
			end
		end		% fclose
		
		%file/fopen - open the file
		%   f = fopen(cFile,...)
		function f=fopen(c,varargin)
			options=varargin;
			bReopenWarning=true;
			if ~isempty(options)&&~ischar(options{1})
				bReopenWarning=options{1};
				options(1)=[];
			end
			if c.fid>=3
				if isempty(fopen(c.fid))	% file was closed externally?
					warning('Was this file closed unintentionally?!')
					c.fid=0;
				elseif bReopenWarning
					%warning('Request to open file when a file was open?!  No file is opened!')
					f=fopen(c.fid);
					return
				end
			end
			if c.fid<3
				if isempty(options)
					options=c.fopenOptions;
				end
				c.fid=fopen(c.fName,options{:});
			end
			if nargout
				f=c.fid;
			end
		end		% fopen
		
		function x=fread(c,varargin)
			if c.fid<3
				error('File is not open!!')
			end
			if ~isempty(varargin)&&length(varargin{1})>2
				x=fread(c.fid,prod(varargin{1}),varargin{2:end});
				x=reshape(x,varargin{1});
			else
				x=fread(c.fid,varargin{:});
			end
		end
		
		function l=fgetl(c)
			l=fgetl(c.fid);
		end
		
		function b=feof(c)
			b=feof(c.fid)||ftell(c.fid)>=c.length();
		end
		
		function l=length(c)
			if c.len<0
				% find length of file
				%     might be overhead if not needed, but extends
				%     feof-function
				curPos=ftell(c.fid);
				fseek(c.fid,0,'eof');
				c.len=ftell(c.fid);
				fseek(c.fid,curPos,'bof');
			end
			l=c.len;
		end
		
		function b=fseek(c,varargin)
			b=fseek(c.fid,varargin{:});
		end
		
		function p=ftell(c)
			p=ftell(c.fid);
		end
		
		function f=double(c)
			f=c.fid;
		end		% double
		
		function delete(c)
			c.fcloseif()
		end		% delete
	end
end
