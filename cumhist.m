function [N,X]=cumhist(y,varargin)
%cumhist - cumulative histogram
%    Uses hist to do the histogram analysis and shows it cumulatively
%           cumhist(y[,x][,...])
%          [N,X]=cumhist(y,...)
%                options:
%                   bNormalized (all = 1)

if nargin>1&&isnumeric(varargin{1})
	[n,x]=hist(y,varargin{1});
	nUsed=2;
else
	[n,x]=hist(y);
	nUsed=1;
end
bPlot=nargout==0;
[bNormalized]=deal(false);
[bLinePlot] = false;
if nargin>nUsed
	setoptions({'bPlot','bNormalized','bLinePlot'},varargin{nUsed:end})
end
Nc=cumsum(n);
if bNormalized
	if isvector(Nc)
		Nc=Nc/Nc(end);
	else
		Nc=bsxfun(@rdivide,Nc,Nc(end,:));
	end
end
if bPlot
	if bLinePlot
		plot(x,Nc)
	else
		bar(x,Nc)
	end
	grid
end
if nargout
	N=Nc;
	X=x;
end
