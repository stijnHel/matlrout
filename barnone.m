function hout=barnone(x,y,col,varargin)
%barnone  - Bar-plot with NON-Equidistant bars
%    [h=]barnone(x,y[,color[,bottomValue[,patch-parameters]]])
%       with x : x-positions
%            y : y-positions, one element smaller than x
%            color : color of patch (default is first axes color)
%                   can be a name of a color ('r','b',...)
%                       or a triplet giving the RGB-values
%    The plot is added to the axes(!).
%  examples:
%       barnone([1 2 4 8],[5 3 6])
%       barnone([1 5 8 12],[1 2 3],[1 0 0],'LineStyle','none')
%
% Stijn Helsen - Jan 10th, 2007

if ~exist('col','var')|isempty(col)
	col=get(gca,'ColorOrder');
	col=col(1,:);
end
optArgs=varargin;
bottomVal=0;
if ~isempty(optArgs)&&~ischar(optArgs{1})
	bottomVal=optArgs{1};
	optArgs(1)=[];
end

nx=length(x);
if length(y)<nx-1
	error('y too short')
end
if size(x,2)==1
	x=x';
end
if size(y,2)==1
	y=y';
end
X=[x([1 1],1:end-1);x([1 1],2:end)];
y0=bottomVal+zeros(1,nx-1);
Y=[y0;y([1 1],1:nx-1);y0];
h=patch(X,Y,col,optArgs{:});
if nargout
	hout=h;
end
