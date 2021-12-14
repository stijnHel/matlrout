classdef XVIstreamer < handle
	%XVIstreamer - class to handle stream of XVI-files (Xenics)
	%   This is just based on one (or a couple of files)!
	
	properties
		f
		head
		H
		fileName
		headLen = 1024
		frameBytesExtra = 64
		nFrames
		curFrame
		LUtable
		Z
		bThermal
	end
	
	methods
		function c=XVIstreamer(fName)
			c.f = file(fName);
			lFile = c.f.length();
			c.fileName = fopen(c.f.fid);
			c.head = c.f.fread([c.headLen,1],'*uint8');
			I = typecast(c.head,'uint32');
			c.H = struct('nBytesPerP',I(1)	... currently not used!
				,'nBytesFullFrame',I(3)	...
				,'nBitsPerPixel',I(4)	...
				,'width',I(5)	...
				,'height',I(6)	...
				,'fps',I(7)	... ?
				,'streamStart',I(8)	...
				,'nImageBytes',I(10)	...
				);
			c.nFrames = (lFile-c.headLen)/c.H.nBytesFullFrame-1;
				% first "frame" is scaling info(??) - at least no real frame
			if c.nFrames>floor(c.nFrames)
				warning('File ends in "broken frame"?!')
				c.nFrames = floor(c.nFrames);
			end
			c.curFrame = 0;
			x = c.f.fread([1 c.H.nBytesFullFrame],'*uint8');
			c.Z = ReadZip(x);
			i = find(strcmp('tmptable.csv',{c.Z.fName}));
			c.bThermal = true;
			if isempty(i)
				warning('No LU-table found.')
				c.LUtable = uint16(0:65535);
			else
				c.LUtable = sscanf(char(c.Z(i).fUncomp), '%g');
			end
		end		% function XVIstreamer
		
		function [Ximage,xExtra]=getImage(c,nr,bScale)
			%XVIstreamer/getImage - get one image
			%     Ximage=getImage(c[,nr])
			%        nr: number of the image (1-based!)
			%            if not given, read next image
			if nargin<2||isempty(nr)
				nr = c.curFrame+1;
				if c.curFrame>c.nFrames
					Ximage=[];
					xExtra=[];
					return
				end
				c.curFrame = nr;
			end
			if nargin<3||isempty(bScale)
				bScale = c.bThermal;
			end
			bErr=false;
			if nr>c.nFrames
				warning('total number of frames reached! (%d)',c.nFrames)
				nr=c.R.length;
				bErr=true;
				err='max';
			end
			if nr<1
				warning('image index starts at 1!')
				nr=1;
			end
			c.f.fseek(c.headLen+nr*c.H.nBytesFullFrame,'bof');	% only if required
			if c.H.nBytesPerP==1
				Ximage = c.f.fread([c.H.width,c.H.height], '*uint8')';
			else
				Ximage = c.f.fread([c.H.width,c.H.height], '*uint16')';
			end
			if bScale
				Ximage = c.LUtable(uint32(Ximage)+1);
			end
			if nargout>1
				x = c.f.fread(c.frameBytesExtra,'*uint8');
				[t,nr,T] = TailData(x,1);
				xExtra = var2struct(t,nr,T);
			end
			if bErr
				Ximage=struct('err',err,'n',nr,'X',Ximage);
			end
		end	% getImage

		function n=length(c)
			n=c.nFrames;
		end	% length
		
		function x = getFrame0(c)
			c.f.fseek(c.headLen,'bof');
			x = c.f.fread([1 c.H.nBytesFullFrame],'*uint8');
		end		% getFrame0
		
		function delete(c)
			c.f.fclose();
		end
		
		function [t,nr,T,H] = getTails(c)
			frameSize = c.H.nBytesFullFrame-c.frameBytesExtra;	%(!!!)
			c.f.fseek(c.headLen+c.H.nBytesFullFrame+frameSize,'bof');
			H = zeros(c.frameBytesExtra,c.nFrames,'uint8');
			for i=1:c.nFrames
				H(:,i) = c.f.fread(c.frameBytesExtra,'*uint8');
				c.f.fseek(frameSize,'cof');
			end
			[t,nr,T] = TailData(H,c.nFrames);
		end		% getTails
		
		function [H,xHead] = getHead(c)
			H = c.H;
			xHead = c.head;
		end		% getHead
	end		% methods
end		% XVIstreamer

function [t,nr,T] = TailData(H,nFrames)
	t = double(typecast(reshape(H(13:20,:),1,nFrames*8),'uint64'))/1e6;
	nr = typecast(reshape(H(21:24,:),1,nFrames*4),'uint32');
	T = reshape(typecast(reshape(H(33:64,:),1,nFrames*32),'uint16'),16,nFrames)';
end		% TailData
