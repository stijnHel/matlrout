function plotshape(c,varargin)
% CSWF/PLOTSHAPE - Plot een "shape"
%    plotshape(c,{shapes})
%    plotshape(c,i,j,nr[,plotopties])

P=getshape(c,varargin{1:min(3,end)});
if iscell(P)
	x0=0;
	for i=1:length(P)
		line(x0+P{i}(:,1),P{i}(:,2),varargin{4:end})
		mx=max(P{i});
		mn=min(P{i});
		x0=x0+mx(1)+50;
		line([x0 x0],[mn(2) mx(2)],'linestyle',':','color',[0 0 0])
		x0=x0+50;
	end
else
	plot(P(:,1),P(:,2),varargin{4:end})
end
axis ij
axis equal
