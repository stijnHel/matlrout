classdef VIDEOstream < handle
   %VIDEOstream - help class for navigation through a video
   %   c = VIDEOstream(fName)
   %    see also navimgs, VideoReader
	properties
		video;	% file ID
		nImgs;	% number of images
	end		% properties
	methods
		function c=VIDEOstream(fName)
			c.video=VideoReader(fFullPath(fName));
			c.nImgs=c.video.NumberOfFrames;
		end 	% VIDEOstream (constructor) 

		function Ximage=getImage(c,nr)
			%VIDEOstream/getImage - get one image
			%     Ximage=getImage(c[,nr])
			%        nr: number of the image (1-based!)
			%            if not given, read next image
			
			Ximage=c.video.read(nr);
		end	% getImage

		function n=length(c)
			n=c.nImgs;
		end	% length
		
		function delete(c)	% destructor
			% clean up is supposed to be done by Matlab's garbage collector
		end		% delete
	end		% methods
end		% classdef VIDEOstream
