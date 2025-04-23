classdef cImgStreamer < handle
	properties
		fList
		nFrames	% only for compatibility reasons, method 'length' should be used
	end

	methods
		function c = cImgStreamer(files,varargin)
			if iscell(files) || isstruct(files)
				c.fList = files;
			else
				d = dir(fFullPath(files));
				B = false(1,length(d));
				for i=1:length(d)
					[~,~,fExt] = fileparts(d(i).name);
					B(i) = any(strcmpi(fExt,{'.bmp','.png','.pgm'}));
				end
				d = d(B);
				if isempty(d)
					error('No files found!')
				elseif isscalar(d)
					warning('Only one file found!')
				end
				c.fList = d;
			end
			c.nFrames = length(c.fList);
		end

		function [Ximage,E]=getImage(c,nr)
			E = [];
			if nargin<2||isempty(nr)
				nr = c.curFrame+1;
				if nr>c.nFrames
					Ximage=[];
					return
				end
			end
			if nr>c.nFrames
				warning('total number of frames reached! (%d)',c.nFrames)
				nr = c.nFrames;
			end
			if nr<1
				warning('image index starts at 1!')
				nr=1;
			end
			if iscell(c.fList)
				fn = c.fList{nr};
			else
				fn = c.fList(nr);
			end
			fn = fFullPath(fn);
			Ximage = imread(fn);
		end		% getImage

		function n=length(c)
			n = length(c.fList);
		end	% length
		
		function x = getFrame0(c)
			x = c.getImage(1);
		end		% getFrame0
		
		function delete(c)
		end
		
		function fclose(c)
		end
	end		% methods
end		% cImgStreamer
