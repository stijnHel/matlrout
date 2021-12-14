function Y=convRaw2Color(X,varargin)
%convRaw2Color - Convert a raw image to color (using Bayer)
%    Y=convRaw2Color(X[,options])
%  !!first dimension is used for lines (since that's the way images are
%     stored!!
%   supposed pattern:
%        G R G R ....
%        B G B G ....
%        G R G R ....
%        . . . .
% (!)an even number of lines and columns is expected, if not, the image is
%   enlarged.
% options:
%     bRevCol - Reverse colours (red and blue are switched)
%     nBit - inverted color images are 8-bit images
%             number of bits (in case of uint16 images) are guessed, based
%             on the maximum value, unless this option is given.

%  FMTC - Stijn Helsen - 2007

bRevCol=true;
nBit=[];
bTranspose=false;

if ~isempty(varargin)
	if length(varargin)==1
		options=varargin{1};
	else
		options=varargin;
	end
	if ~isempty(options)
		setoptions({'nBit','bRevCol','bTranspose'},options)
	end
end

if bTranspose
	X=X';
end

if rem(size(X,1),2)
	X(end+1,:)=X(end-1,:);
end
if rem(size(X,2),2)
	X(:,end+1)=X(:,end-1);
end

Y=X(:,:,[1 1 1]);
if isa(X,'uint8')
	X=uint16(X);	% prevent overflow
end
% Green
Y([1 end],2:2:end-2,2)=(X([1 end],1:2:end-2)+X([1 end],3:2:end))/2;
Y(1,end,2)=(X(1,end-1)+X(2,end))/2;
Y(3:2:end,end,2)=(X(2:2:end-2,end)+X(4:2:end,end)+X(3:2:end,end-1))/3;
Y(2:2:end-2,3:2:end,2)=(X(1:2:end-2,3:2:end)+X(2:2:end-2,2:2:end-2)	...
	+X(2:2:end-2,4:2:end)+X(3:2:end,3:2:end))/4;
Y(3:2:end,2:2:end-2,2)=(X(2:2:end-2,2:2:end-2)+X(3:2:end,1:2:end-2)	...
	+X(3:2:end,3:2:end)+X(4:2:end,2:2:end-2))/4;

% Red
Y(1:2:end,3:2:end,1)=(X(1:2:end,2:2:end-2)+X(1:2:end,4:2:end))/2;
Y(2:2:end-2,2:2:end-2,1)=(X(1:2:end-2,2:2:end-2)+X(3:2:end,2:2:end-2))/2;
Y(2:2:end-2,3:2:end,1)=(X(1:2:end-2,2:2:end-2)+X(3:2:end,2:2:end-2)	...
	+X(1:2:end-2,4:2:end)+X(3:2:end,4:2:end))/4;
% borders!!

% Blue
Y(2:2:end-2,2:2:end-2,3)=(X(2:2:end-2,1:2:end-2)+X(2:2:end-2,3:2:end))/2;
Y(3:2:end,1:2:end,3)=(X(2:2:end-2,1:2:end)+X(4:2:end,1:2:end))/2;
Y(3:2:end,2:2:end-2,3)=(X(2:2:end-2,1:2:end-2)+X(4:2:end,1:2:end-2)	...
	+X(2:2:end-2,3:2:end)+X(4:2:end,3:2:end))/4;
% borders!!

if bRevCol
	Y=Y(:,:,[3 2 1]);
end

%Y=permute(Y,[2 1 3]);	% transpose (horizontal lines are put to second dimension)
	%!!!!better to transpose before conversion

if isa(Y,'uint16')|~isempty(nBit)
	if isempty(nBit)
		maxX=max(X(:));
		if maxX>16383
			nBit=16;
			Y=uint8(bitshift(Y,-8));	%(!)16 bit is assumed
		elseif maxX>4095
			nBit=14;
			Y=uint8(bitshift(Y,-6));	%(!)14 bit is assumed
		elseif maxX>1023
			nBit=12;
			Y=uint8(bitshift(Y,-4));	%(!)12 bit is assumed
		else
			nBit=10;
		end
	end
	if nBit~=8
		Y=uint8(bitshift(Y,8-nBit));
	else
		Y=uint8(Y);
	end
end
if 0
	maxX=max(X(:));
	if maxX>1
		if maxX>255
			fac=1023;
		else
			fac=255;
		end
		Y=Y/fac;
	end
end
