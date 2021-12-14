function hOut=steppedline(varargin)
%steppedline - Make a stepped line (or convert a normal line)
%   steppedline(X,Y[,...]) - plots a stepped line
%                     plot function is used, additional arguments are
%                          forwarded to this function
%              if an output argument is used, handle to line is given
%   steppedline(Y)	- plots a stepped line (with X=0:1:..)
%   steppedline(<handle>) - lines within object targeted by <handle> are
%      converted to stepped lines or back
%      steppedline(<handle>,'bReverse',true) - reverse order is used

bCompress=true;

if (nargin>=2&&isnumeric(varargin{2}))||(nargin==1&&size(varargin{1},1)>1)
	if nargin==1
		y=varargin{1};
		x=0:length(y)-1;
		i=2;
	else
		x=varargin{1};
		y=varargin{2};
		i=3;
	end
	[x,y]=makestepped(x,y,bCompress);
	h=plot(x,y,varargin{i:end});
	if nargout
		hOut=h;
	end
	return
end
bReverse=false;
if nargin&&all(ishandle(varargin{1}))
	h=varargin{1};
	options=varargin(2:end);
else
	h=gcf;
	options=varargin;
end
if ~isempty(options)
	setoptions({'bReverse'},options{:})
end
l=findobj(h,'type','line');
for i=1:length(l)
	x=get(l(i),'xdata');
	y=get(l(i),'ydata');
	if isequal(x(2:2:end-2),x(3:2:end-1))&&isequal(y(1:2:end-1),y(2:2:end))
		x=x(1:2:end);
		y=y(1:2:end);
	else
		if bReverse
			[x,y]=makestepped(x(end:-1:1),y(end:-1:1),bCompress);
			x=x(end:-1:1);
			y=y(end:-1:1);
		else
			[x,y]=makestepped(x,y,bCompress);
		end
	end
	set(l(i),'xdata',x,'ydata',y);
end

function [x,y]=makestepped(x,y,bCompress)
if bCompress
	B=[false;diff(y(:))==0];
	B(end)=false;
	x(B)=[];
	y(B)=[];
end
x=x(:)';
y=y(:)';
x=[x(1:end-1);x(2:end)];
y=[y(1:end-1);y(1:end-1)];
x=[x(:);x(end)];
y=[y(:);y(end)];
