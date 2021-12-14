function AddPicture(xImg,varargin)
%AddPicture - Add picture to figure window
%        AddPicture(xImg[,options])
%   Adds a picture to an figure window with the possibility to hold it to
%       a constant relative position (centered, ...)
%   xImg is an image (2D or 3D matrix) or a "Matlab-readable image file"
%                   (with imread)
%            options:
%               scale : factor for X- and Y-size
%               xScale, yScale : separate X- and Y-size scale
%               xPos : 'left', 'right' or 'center'(or 'centre')
%               yPos : 'top', 'bottom' or 'middle'
%               x0, y0 : position, depending on xPos and yPos:
%                   'left' : #pixels left
%                   'right' : #pixels right
%                   'top' : #pixels top
%                   'bottom' : #pixels bottom
%                   not used with 'center' or 'middle'

f=gcf;
if ischar(xImg)
	[X,map]=imread(xImg);
	if ~isempty(map)
		colormap(map)
	end
else
	X=xImg;
end

xScale=[];
yScale=[];
scale=1;
xPos='right';
yPos='top';
x0=0;
y0=0;

if ~isempty(varargin)
	setoptions({'xScale','yScale','scale','xPos','yPos','x0','y0'}	...
		,varargin{:})
end
if isempty(xScale)
	xScale=scale;
end
if isempty(yScale)
	yScale=scale;
end
fPos=get(f,'position');
fSize=fPos(3:4);
imSize=[size(X,2)*xScale,size(X,1)*yScale];
D=struct('fig',f,'fSize',fSize,'imSize',imSize,'ax',[]	...
	,'xPos',xPos,'yPos',yPos,'x0',x0,'y0',y0	...
	);
axPos=CalcPos(D);
D.ax=axes('Units','pixel','position',axPos);
image(X);
axis off
axis equal
set(f,'ResizeFcn',@FigureResized);
D1=getappdata(f,'movingPicture');
if isempty(D1)
	D1=D;
else
	D1(end+1)=D;
end
setappdata(f,'movingPicture',D1);

function FigureResized(f,ev)
D=getappdata(f,'movingPicture');
for i=1:length(D)
	axPos=CalcPos(D(i));
	set(D(i).ax,'Position',axPos)
end

function axPos=CalcPos(D)
p=get(D.fig,'Position');

switch D.xPos
	case 'left'
		x=D.x0;
	case {'center','centre'}
		x=(p(3)-D.imSize(1))/2;
	case 'right'
		x=p(3)-D.x0-D.imSize(1);
	otherwise
		error('Wrong x-position')
end
switch D.yPos
	case 'top'
		y=p(4)-D.y0-D.imSize(2);
	case 'middle'
		y=(p(4)-D.imSize(2))/2;
	case 'bottom'
		y=D.y0;
	otherwise
		error('Wrong x-position')
end
axPos=[x y D.imSize];
