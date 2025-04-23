classdef CLV_Img_streamer < handle
	%CLV_Img_streamer - class to handle stream of data from LabVIEW CameraTester
	%
	% This "image streamer" is created for image-(bin-)files created by
	%    CameraTest.vi (in CameraTesting.lvproj).
	%
	%         c = CLV_Img_streamer(<fname>);
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
	
	% Based on ReadImage (to avoid the need to read a full file)

	properties
		f
		fileName
		lFile
		headLen
		blockSize
		nFrames
		curFrame
		version
		bSaveCustom
		imgTypInt
		imgTypString
		filePixTyp
		Image_Height
		b_8bitData
		b_16bitData
		btPerP
		bTranspose = false
		sizImage
		t_last
		X_last
	end
	
	methods
		function c = CLV_Img_streamer(fName,varargin)
			%CLV_Img_streamer - Constructor
			if ~isempty(varargin)
				setoptions(c,varargin{:})
			end
			c.fileName = fFullPath(fName,false,'.bin');
			c.f = file(c.fileName,'r','ieee-be');
			fseek(c.f,0,'eof');
			c.lFile = ftell(c.f);
			fseek(c.f,0,'bof');

			c.ReadFirst();

			c.nFrames = (c.lFile-c.headLen)/c.blockSize;
			if c.nFrames>floor(c.nFrames)
				nEnd = rem(c.lFile-c.headLen,c.blockSize);
				if nEnd~=24	% when cancelling a block header is written
					warning('Broken file?!')
				end
				c.nFrames = floor(c.nFrames);
			end
			c.curFrame = 0;
		end		% function CLV_Img_streamer
		
		function [Ximage,E,C] = getImage(c,nr)
			%CLV_Img_streamer/getImage - get one image
			%     Ximage=getImage(c[,nr])
			%        nr: number of the image (1-based!)
			%            if not given, read next image

			% !!!?? data read in X but permuted in Ximage - needed?

			if nargin>1 && ~isempty(nr)
				if nr>c.nFrames
					warning('total number of frames reached! (%d)',c.nFrames)
					nr = c.nFrames;
				end
				if nr<1
					warning('image index starts at 1!')
					nr = 1;
				end
				c.f.fseek(c.headLen+(nr-1)*c.blockSize,'bof');
			else
				nr = c.curFrame+1;
			end
			c.t_last = lvtime([],c.f);
			if c.version>1&&c.version<=2
				n = c.f.fread(1,'uint8');
				xt = c.f.fread([1 n],'*uint16');	% not used
				if any(c.imgTypInt==[1,4,7])
					xt(end+1) = c.f.fread(1,'*uint16');
				end
			elseif c.version>2
				n = c.f.fread(1,'uint8');
				xt = c.f.fread([1 n],'*uint16');	% not used
				if any(c.imgTypInt==[1,4,7])
					xt(end+1) = c.f.fread(1,'*uint16');
				end
			end
			c.sizImage = c.f.fread([1,2],'uint32');
			if strcmp(c.imgTypString,'MONO')
				X = c.f.fread(prod(c.sizImage),['*' c.filePixTyp]);
				dummy = c.f.fread(1,'uint32');	% why? It just is...
				if dummy>0
					warning('Fill-data not zero?')
				end
			elseif c.version>1
				X = c.f.fread(prod(c.sizImage),['*' c.filePixTyp]);
				dummy = c.f.fread(1,'uint32');	% why? It just is...
			elseif all(c.sizImage>0)	% normal 8-bit RGB-data
				X = c.f.fread(prod(c.sizImage),'*uint32');
				c.b_16bitData = false;
				c.btPerP = 4;
			else	% 
				c.b_16bitData = true;
				c.sizImage = c.f.fread([1,2],'uint32');
				X = c.f.fread(prod(c.sizImage),'*uint64');
				c.btPerP = 4;%!!!
			end
			if c.version==2
				C = ReadCustom(c.f);
			elseif c.version>2&&c.bSaveCustom
				C = ReadCustom(c.f);
			else
				C = [];
			end
			Ximage = reshape(X,c.sizImage(end:-1:1));	% ??!!!!!
			if strcmp(c.imgTypString,'MONO')
				Ximage = permute(reshape(X,c.sizImage(2),c.sizImage(1),1,size(X,2)),[2 1 3 4]);
			elseif strcmp(c.imgTypString,'RGB')
				if c.b_16bitData
					Ximage = reshape(typecast(X(:),'uint16'),4,c.sizImage(2),c.sizImage(1),size(X,2));
					Ximage = Ximage([2,3,4],:,:,:);
				else
					Ximage = reshape(typecast(X(:),'uint8'),4,c.sizImage(2),c.sizImage(1),size(X,2));
					Ximage = Ximage([3,2,1],:,:,:);
				end
				Ximage = permute(Ximage,[3 2 1 4]);
			end
			
			if c.bTranspose
				Ximage = permute(Ximage,[2 1 3]);
			end
			c.X_last = Ximage;
			c.curFrame = nr;
			if nargout>1
				E = struct('t',c.t_last);
				if ~isempty(C) && ~isempty(fieldnames(C))
					TS_H = [];
					if isfield(C,'IMAQdxReceiveTimestampHigh')&&isfield(C,'IMAQdxReceiveTimestampLow')
						TS_H = cat(1,C.IMAQdxReceiveTimestampHigh);
						TS_L = cat(1,C.IMAQdxReceiveTimestampLow);
					elseif isfield(C,'IMAQdxTimestampHigh')&&isfield(C,'IMAQdxTimestampLow')
						TS_H = cat(1,C.IMAQdxTimestampHigh);
						TS_L = cat(1,C.IMAQdxTimestampLow);
					end
					if ~isempty(TS_H)
						TS = [TS_L(:,[4 3 2 1])';TS_H(:,[4 3 2 1])'];
						E.TS = double(typecast(TS(:),'uint64'))*1e-6;
					end
				end
			end
		end	% getImage

		function [T,t0] = getImgTimes(c,nMax)
			%getImgTimes - retrieves all timestamps

			n = c.nFrames;
			if nargin>=2 && ~isempty(nMax)
				n = min(nMax,n);
			end

			TT = zeros(16,n,'uint8');
			for i=1:n
				c.f.fseek(c.headLen+(i-1)*c.blockSize,'bof');
				TT(:,i) = c.f.fread(16,'*uint8');
			end
			T = double(typecast(reshape(TT(12:-1:5,:),n*8,1),'uint64'))/2^32;
			T = T-T(1);
			if nargout>1
				t0 = lvtime(TT(:,1));
			end
		end		% getImgTimes
		
		function [X,E] = getImages(c,n1,n2)
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
			if nargout<2	% (for slight improved efficiency(...))
				X = c.getImage(n1);
				X(1,1,1,n2-n1+1) = X(1);
				for i=2:n2-1+1
					X(:,:,:,i) = c.getImage();
				end
			else
				[X,E] = c.getImage(n1);
				X(1,1,1,n2-n1+1) = X(1);
				E(n2-n1+1) = E;
				for i=2:n2-1+1
					[X(:,:,:,i),E(i)] = c.getImage();
				end
			end
			c.curFrame = n2;
		end		% getImages

		function n=length(c)
			n = c.nFrames;
		end	% length

		function ReadFirst(c)
			% read header
			n = c.f.fread(1,'uint32');
			if n>32
				error('Wrong start of image file - not a "LV-ImageFileDump"? (%s)',c.f.fName)
			end
			typ = c.f.fread([1 n],'*char');
			if ~strcmp(typ,'imgStream')
				error('Sorry, but this function only allows files of type "imgStream"! (%s)',typ)
			end
			c.version = c.f.fread(1,'uint32')/100;
			if c.version>3
				warning('Only version 3.00 is known! (version %.2f)',c.version)
			end
			c.imgTypInt = c.f.fread(1,'uint32');
			n=c.f.fread(1,'uint32');
			if n>16
				error('Bad image type?!')
			end
			c.imgTypString=c.f.fread([1 n],'*char');
			if c.version>=3
				c.bSaveCustom = logical(c.f.fread(1,'*uint8'));
			end
			c.headLen = ftell(c.f);
			c.b_8bitData = false;
			c.b_16bitData = false;
			switch c.imgTypInt
				case 0	% Grayscale (U8)
					if strcmp('MONO',c.imgTypString)
						c.filePixTyp = 'uint8';
						c.b_8bitData=true;
					else
						c.filePixTyp ='uint32';	% old version...
					end
					c.btPerP =1;
				case 1	% Grayscale (I16)
					c.filePixTyp ='int16';
					c.b_16bitData =true;
					c.btPerP =2;
				case 2	% Grayscale (SGL)
					c.filePixTyp ='single';
					c.btPerP =4;
				case 3	% Grayscale (CSG)
					c.filePixTyp ='uint64';	%!!!!
					c.btPerP =8;
				case 4	% RGB (U32)
					c.filePixTyp ='uint32';
					c.btPerP =4;
				case 5	% Grayscale (U32)
					c.filePixTyp ='uint32';
					c.btPerP =4;
				case 6	% RGB (U64)
					c.filePixTyp ='uint64';
					c.b_16bitData=true;
					c.btPerP =8;
				case 7	% Grayscale (U16)
					c.filePixTyp ='uint16';
					c.b_16bitData=true;
					c.btPerP =2;
				otherwise
					c.filePixTyp ='uint8';
					warning('Unknown(/wrong?) image type?!')
			end
			c.getImage();	% read first image (mainly to get blocksize & nFrames)
			fP1=c.f.ftell();
			c.blockSize = fP1-c.headLen;
		end		% ReadFirst
		
		function [varargout] = getFrame0(c)
			varargout = cell(1,max(1,nargout));
			[varargout{:}] = c.getImage(1);
		end		% getFrame0
		
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
end		% CLV_Img_streamer

function C = ReadCustom(cFile)
nCustom=cFile.fread(1,'uint32');
C=cell(2,nCustom);
idx=1;
for i=1:nCustom
	nT=cFile.fread(1,'uint32');
	nCi=cFile.fread([1 nT],'uint8=>char');
	idx=idx+4+nT;
	nV=cFile.fread(1,'uint32');
	idx=idx+4;
	nVi=cFile.fread([1 nV],'*uint8');
	idx=idx+nV;
	C{1,i}=nCi;
	C{2,i}=nVi;
end
C=struct(C{:});
end		% ReadCustom
