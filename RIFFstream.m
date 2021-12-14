classdef RIFFstream < handle
	%RIFFstream - class to handle stream of data coming from a RIFF-file
	%    This is not very generic code(!!!).  It's made for a stream of IR
	%    images taken by Engie.
	%    A disadvantage of this code is that the whole structure is read
	%    (quite detailed), leading to a slow startup.
	
	% use indx & ix00 rather than using looping through data
	%   reading of ReadRIFFstruct can be reduced to a minimum
	properties
		fileName;
		R;
	end
	
	methods
		function c=RIFFstream(fName)
			c.fileName=fFullPath(fName);
			c.R=ReadRIFFstruct(c.fileName,'-bminr');
		end		% function RIFFstream
		
		function [Ximage,xHead]=getImage(c,nr)
			%RIFFstream/getImage - get one image
			%     Ximage=getImage(c[,nr])
			%        nr: number of the image (1-based!)
			%            if not given, read next image
			bErr=false;
			if nr>c.R.length
				warning('total number of frames reached! (%d)',c.R.length)
				nr=c.R.length;
				bErr=true;
				err='max';
			end
			if nr<1
				warning('image index starts at 1!')
				nr=1;
			end
			if nargout<2
				[c.R,Ximage]=ReadRIFFstruct(c.R,nr);
			else
				[c.R,Ximage,xHead]=ReadRIFFstruct(c.R,nr);
			end
			if bErr
				Ximage=struct('err',err,'n',nr,'X',Ximage);
			end
		end	% getImage

		function n=length(c)
			n=c.R.length;
		end	% length
		
		function delete(c)
			c.R.file.fclose();
		end
	end
end
