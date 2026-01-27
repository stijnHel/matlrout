classdef CPYT_Img_streamer < handle
	%CPYT_Img_streamer - class to handle stream of data from Python code
	%	Python code like "test_vision" or ImageStreamViewer creates data
	%	compatible with this streamer.
	%
	%         c = CPYT_Img_streamer(<fname>);
	%         X1 = c.getImage();	% get next image
	%             (first image is read during object creation!)
	%         X1 = c.ReadFirst();	% reads first image
	%         Xi = c.getImage(<nr>);	% get "random access image"
	%         XX = c.getImages(<nr1>,<nr2>);	% reads multiple images
	%                returns in a <m x n x k x [nFrames]> array
	%                    3d dimension is foreseen for multichannel data (RGB)
	%         [X,E] = c.getImage();	% returns some extra information
	%
	% see also navimgs

	properties
		f
		fileName
		lFile
		headLen
		blockSize
		nFrames
		curFrame
		bTranspose = true
		t_last
		X_last
		b_64bit_size = false
		nFields
		fldImage
		posTime
		posImg
		Fields
		b_const_datasize = true
		b_warned = false
		StartsImgs
	end
	
	methods
		function c = CPYT_Img_streamer(fName,varargin)
			%CPYT_Img_streamer - Constructor
			if ~isempty(varargin)
				setoptions(c,varargin{:})
			end
			c.fileName = fFullPath(fName,false,'.bin');
			c.f = file(c.fileName,'r');
			fseek(c.f,0,'eof');
			c.lFile = ftell(c.f);
			fseek(c.f,0,'bof');

			c.ReadFirst();

			if c.nFrames>floor(c.nFrames)
				nEnd = rem(c.lFile-c.headLen,c.blockSize);
				c.nFrames = floor(c.nFrames);
				if nEnd~=24	% when cancelling a block header is written
					warning('Broken file - or not constant block size?!')
					c.b_const_datasize = false;
					c.StartsImgs = zeros(1,c.nFrames);
				end
			end
			c.curFrame = 0;
		end		% function CPYT_Img_streamer
		
		function [Ximage,t,S] = getImage(c,nr)
			%CPYT_Img_streamer/getImage - get one image
			%     Ximage=getImage(c[,nr])
			%        nr: number of the image (1-based!)
			%            if not given, read next image

			% !!!?? data read in X but permuted in Ximage - needed?

			t = [];
			S = [];
			if nargin>1 && ~isempty(nr)
				if nr>c.nFrames
					warning('total number of frames reached! (%d)',c.nFrames)
					nr = c.nFrames;
				end
				if nr<1
					warning('image index starts at 1!')
					nr = 1;
				end
				if ~c.b_const_datasize && nr>1
					if c.StartsImgs(nr)
						c.f.fseek(c.StartsImgs(nr),'bof');
					else
						if ~c.b_warned
							warning('Reading file until requested frame!!')
							c.b_warned = true;
						end
						while c.curFrame<nr-1
							c.getImage();
						end
					end
				else
					c.f.fseek(c.headLen+(nr-1)*c.blockSize,'bof');
				end
			else
				nr = c.curFrame+1;
			end
			if ~c.b_const_datasize && ~c.StartsImgs(nr)
				c.StartsImgs(nr) = c.f.ftell();
			end

			% only read the necessary data?
			%      --> not if nargout>2
			%      --> use posTime and posImage
			
			[tag1,D1] = c.ReadBlock();
			if isempty(tag1)
				warning('trying to read beyond the end?')
				Ximage = [];
				return
			end
			S = struct(tag1,D1);
			%for i=2:c.nFields
			tag = tag1;
			while ~strcmp(tag,c.Fields{end})
				[tag,D1] = c.ReadBlock();
				if isempty(tag)
					warning('trying to read beyond the end?')
					Ximage = [];
					return
				end
				S.(tag) = D1;
			end
			Ximage = S.(c.fldImage);
			if ndims(Ximage)==3	% rgb
				if any(size(Ximage)==1) % not really rgb...
					Ximage = squeeze(Ximage);
				else
					if any(size(Ximage)==3) && size(Ximage,3)~=3
						if size(Ximage,1)==3
							Ximage = permute(Ximage,[2,3,1]);
						else
							Ximage = permute(Ximage,[1,3,2]);
						end
					end
					Ximage = Ximage(:,:,[3 2 1]);	% BGR --> RGB
				end
			end
			if isfield(S,'time')
				t = S.time;
			else
				t = 0;
			end

			if c.bTranspose
				if ismatrix(Ximage)
					Ximage = Ximage';
				else
					Ximage = permute(Ximage,[2 1 3]);
				end
			end
			c.X_last = Ximage;
			c.curFrame = nr;
			if nargout>2
				if isfield(S,'cam')
					s = S.cam;
					if startsWith(s,'exposure:')
						S.exposure = str2double(s(10:end));
					elseif startsWith(s,'gain:')
						S.gain = str2double(s(6:end));
					end
				elseif isfield(S,'lens')
					s = S.lens;
					if startsWith(s,'zoom:')
						S.zoom = str2double(s(6:end));
					elseif startsWith(s,'focus:')
						S.focus = str2double(s(7:end));
					elseif startsWith(s,'iris:')
						S.iris = str2double(s(6:end));
					end
				end
			end
		end	% getImage

		function [T,t0] = getImgTimes(c,nMax)
			%getImgTimes - retrieves all timestamps

			n = c.nFrames;
			if nargin>1 && ~isempty(nMax)
				n = min(n,nMax);
			end
			if c.b_const_datasize
				c.f.fseek(c.headLen+c.posTime,'bof');
				T = c.f.fread([1,n],'double',c.blockSize-8)/1000;
			else
				T = zeros(n,1);
				for i=1:n
					if c.curFrame>=c.nFrames
						T = T(1:i-1);
						break
					end
					[~,t] = c.getImage();
					T(i) = t;
				end
			end
			t0 = T(1);
		end		% getImgTimes
		
		function [X,varargout] = getImages(c,n1,n2)
			if nargin==1
				n1 = c.nFrames;
			end
			if nargin<3
				n2 = c.curFrame+n1;
				n1 = c.curFrame+1;
			end
			if n1<1
				n1 = 1;
			end
			nTotal = n2-n1+1;
			if nargout<2	% (for slight improved efficiency(...))
				if c.b_const_datasize
					X = c.getImage(n1);
				else
					% no random access possibility - only "one way reading"!!!!
					X = c.getImage();
				end
				X(1,1,1,nTotal) = 0;
				for i=2:nTotal
					X1 = c.getImage();
					if isempty(X1)
						break
					end
					X(:,:,:,i) = X1;
				end
			else
				varargout = cell(1,max(0,nargout-1));
				out = varargout;
				if c.b_const_datasize
					[X,out{:}] = c.getImage(n1);
				else
					% no random access possibility - only "one way reading"!!!!
					[X,out{:}] = c.getImage();
				end
				for j = 1:length(out)
					varargout{j} = out{j}(1,ones(1,nTotal));
				end
				X(1,1,1,nTotal) = X(1);
				for i=2:nTotal
					[X1,out{:}] = c.getImage();
					if isempty(X1)
						break
					end
					X(:,:,:,i) = X1;
					for j = 1:length(out)
						varargout{j}(i) = out{j};
					end
				end
			end
			c.curFrame = n2;
		end		% getImages

		function n=length(c)
			n = c.nFrames;
		end	% length

		function ReadFirst(c)
			% read header
			typFile = ReadWord(c.f);
			if strcmp(typFile,'VIDEObin')
				warning('Only one image in this stream?')
			elseif strcmp(typFile,'VIDEOstream')
			elseif any(typFile<' ' | typFile>=127)
				error('Wrong file type')
			else
				warning('Unknown type?! ("%s")',typFile)
			end
			c.headLen = c.f.ftell();

			tag1 = c.ReadBlock();
			Tags = {tag1};
			Spos = struct(tag1,length(tag1)+1);
			while true
				p = c.f.ftell();
				tag = c.ReadBlock();
				if isempty(tag) || strcmp(tag1,tag)
					break
				end
				Tags{1,end+1} = tag; %#ok<AGROW> 
				Spos.(tag) = p-c.headLen+length(tag)+1;
			end
			c.blockSize = p - c.headLen;
			if isempty(c.fldImage)
				if ismember('rgb',Tags)
					c.fldImage = 'rgb';
				elseif ismember('gray',Tags)
					c.fldImage = 'gray';
				else
					i = find(~strcmp(Tags,'time'),1);
					c.fldImage = Tags{i};
				end
			end
			if isfield(Spos,'time')
				c.posTime = Spos.time;
			else
				warning('No time-field?!')
			end
			c.posImg = Spos.(c.fldImage);
			c.nFrames = (c.lFile-c.headLen)/c.blockSize;
			c.f.fseek(c.headLen,'bof');
			c.nFields = length(Tags);
			c.Fields = Tags;
		end		% ReadFirst
		
		function [varargout] = getFrame0(c)
			varargout = cell(1,max(1,nargout));
			[varargout{:}] = c.getImage(1);
		end		% getFrame0

		function [tag,D] = ReadBlock(c)
			tag = ReadWord(c.f);
			if isempty(tag)
				D = [];
				if ~c.f.feof()
					warning('Empty tag (and not in end-of-file)?!')
				end
				return
			end
			typ = [];
			switch tag
				case 'time'
					D = c.f.fread(1,'double')/1000;
				case {'gray','depth','pc'}
					ndim = 2;
					typ = ReadWord(c.f);
				case 'rgb'
					ndim = 3;
					typ = ReadWord(c.f);
				case 'cam'
					D = ReadWord(c.f);
				case 'lens'
					D = ReadWord(c.f);
				otherwise
					warning('Unknown tag! (%s)',tag)
					D = [];
			end		% switch tag
			if ~isempty(typ)
				switch typ
					case {'uint8','int8'}
						%nB = 1;
					case {'uint16', 'int16'}
						%nB = 2;
					case {'uint32', 'int32'}
						%nB = 4;
					case 'float32'
						%nB = 4;
						typ = 'single';
					case {'uint64', 'int64'}
						%nB = 8;
					case 'float'
						%nB = 8;
						typ = 'double';
					otherwise
						error('Unknown datatype (%s)',typ)
				end
				if c.b_64bit_size
					siz = c.f.fread([1 ndim],'uint64');
				else
					siz = c.f.fread([1 ndim],'uint32');
					if siz(2)==0
						warning('Changed to 64-bit-integer setting!')
						c.f.fseek(-ndim*4,'cof');
						c.b_64bit_size = true;
						siz = c.f.fread([1 ndim],'uint64');
					end
				end
				siz = siz(ndim:-1:1);
				if ndim<3
					D = c.f.fread(siz,['*',typ]);
				else
					D = c.f.fread(prod(siz),['*',typ]);
					D = reshape(D,siz);
				end
			end
		end		% ReadBlock

		function reset(c)
			c.f.fseek(c.headLen,'bof');
			c.curFrame = 0;
		end		% reset
		
		function delete(c)
			c.close();
		end
		
		function close(c)
			if ~isempty(c.f)
				c.f.fclose()
				c.f = [];
			end
		end		% close
		
	end		% methods
end		% CPYT_Img_streamer

function s = ReadWord(f)
x = zeros(1,64,'uint8');
i = 0;
a = f.fread(1,'uint8');
while a>0
	i = i+1;
	x(i) = a;
	a = f.fread(1,'uint8');
	if isempty(a)
		warning('end of file reached')
		break
	end
end
s = char(x(1:i));
end		% ReadWord
