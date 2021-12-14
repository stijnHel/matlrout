function varargout=PlotXCOR(x,varargin)
%PlotXCOR - Plot cross correlation of vector
%    PlotXCOR(x[,...])

bSubMeanDBL = true;
bSubU8_128 = [];
bSubU8_mean = [];
bU8_2_dbl = true;
bPlot = nargout<2;
dx=1;

if nargin<=1
	options={};
	y=[];
elseif isnumeric(varargin{1})
	options=varargin(2:end);
	y=varargin{1};
else
	options=varargin;
	y=[];
end
if ~isempty(options)
	setoptions({'bSubMeanDBL','bSubU8_128','bSubU8_mean','bU8_2_dbl','bPlot','dx'}	...
		,options{:})
end
if isa(x,'uint8')
	if isempty(bSubU8_128)
		if isempty(bSubU8_mean)
			bSubU8_128=true;
			bSubU8_mean=false;
		else
			bSubU8_128=~bSubU8_mean;
		end
	elseif isempty(bSubU8_mean)
		bSubU8_mean=~bSubU8_128;
	end
	if bU8_2_dbl
		x=double(x);
	end
	if bSubU8_128
		x = x-128;
	elseif bSubU8_mean
		x = x-mean(x);
	end
else
	if ~isa(x,'double')
		x=double(x);	%(!)
	end
	if bSubMeanDBL
		x=x-mean(x);
	end
end
nX=length(x);
if ~isempty(y)
	if isa(y,'uint8')
		if isempty(bSubU8_128)
			if isempty(bSubU8_mean)
				bSubU8_128=true;
				bSubU8_mean=false;
			else
				bSubU8_128=~bSubU8_mean;
			end
		elseif isempty(bSubU8_mean)
			bSubU8_mean=~bSubU8_128;
		end
		if bU8_2_dbl
			y=double(y);
		end
		if bSubU8_128
			y = y-128;
		elseif bSubU8_mean
			y = y-mean(y);
		end
	else
		if ~isa(y,'double')
			y=double(y);	%(!)
		end
		if bSubMeanDBL
			y=y-mean(y);
		end
	end
	if length(x)<length(y)
		x(length(y))=0;
		nX=length(x);
	elseif length(x)>length(y)
		y(length(x))=0;
	end
end

if isempty(y)
	x=xcorr(x);
	x=x(nX:end);
	X=0:nX-1;
else
	x=xcorr(x,y);
	X=1-nX:nX-1;
end
if bPlot
	h=plot(X*dx,x);grid
	if nargout
		varargout={h,x,X};
	end
elseif nargout
	varargout={x,X};
end
