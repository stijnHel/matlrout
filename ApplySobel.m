function Y=ApplySobel(X,dir,varargin)
%ApplySobel - Apply Sobel filter on 2D arrays
%     Y=ApplySobel(X,dir,...);
%            dir: direction:
%                1 (or 'vert'): vertical
%                2 (or 'hor'): horizontal
%                0 (or 'all') / default: vertical and horizontal

bRestoreType = ~isa(X,'double');
bAbs = [];	% take absolute value
scale=[];
if nargin<2||isempty(dir)
	dir = 0;
end

if nargin>2
	setoptions({'bRestoreType','bAbs','scale'},varargin{:})
end
if ischar(dir)
	if strncmpi(dir,'vert',4)
		dir=1;
	elseif strncmpi(dir,'hor',3)
		dir=2;
	else
		error('Unknown input!')
	end
elseif ~any(dir==[0,1,2])
	warning('Default value for "dir" used (0)!')
	dir=0;
end
if isempty(bAbs)
	if dir==0
		bAbs=true;
	elseif bRestoreType
		bAbs=strncmp(class(X),'u',1);
	else
		bAbs=false;
	end
end

h = [1 2 1; 0 0 0; -1 -2 -1];

switch dir
	case 1
		Y = filter2(h,X);
		if bAbs
			Y=abs(Y);
		end
	case 2
		Y = filter2(h',X);
		if bAbs
			Y=abs(Y);
		end
	otherwise
		Y1 = filter2(h,X);
		Y2 = filter2(h',X);
		if bAbs
			Y1=abs(Y1);
			Y2=abs(Y2);
		end
		Y=Y1+Y2;
end
if ~isempty(scale)
	Y=Y*scale;
end
if bRestoreType
	Y=cast(Y,class(X));
end
