classdef CImgTransformer < handle
%CImgTransformer - class doing image transform
%    class made for navimgs - to use different image adaptations before
%    displaying (but can be used elsewhere too!)

	properties
		bLog = false	% transform to log scale
		xOffset			% can be scalar or an array with same size as the images
		xScale			% can be scalar or an array
		xMin			% minimum value (clipped or replaced by replace value)
		xReplace		% replacement value for xMin
		bToDouble		% Convert to double
	end

	methods
		function c = CImgTransformer(varargin)
			if nargin
				setoptions(c,varargin{:})
			end
			if isempty(c.bToDouble)
				c.bToDouble = c.bLog;
			end
		end

		function InstallInNavimgs(c,f)
			if nargin<2 || isempty(f)
				f = gcf;
			end
			setappdata(f,'ImgTranformData',c)
		end

		function ClearFromNavimgs(c,f)
			if nargin<2 || isempty(f)
				f = gcf;
			end
			if isappdata(f,'ImgTranformData')
				rmappdata(1,'ImgTranformData')
			end
		end

		function X = Transform(c,X)
			if c.bToDouble
				X = double(X);
			end
			if ~isempty(c.xOffset)
				X = X-c.xOffset;
			end
			if ~isempty(c.xMin)
				if isempty(c.xReplace)
					X = max(X,c.xMin);
				else
					X(X<c.xMin) = c.xReplace;
				end
			end
			if ~isempty(c.xScale)
				X = X./c.xScale;
			end
			if c.bLog
				X = log(X);
			end
		end		% Transform

		function SetLog(c,b)
			if nargin<2 || isempty(b)
				b = true;
			end
			c.bLog = b;
		end

		function SetOffset(c,x)
			c.xOffset = x;
		end		% SetOffset
	end		% methods
end		% CImgTransformer
