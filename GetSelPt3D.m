function [ptSel,iPt,dMin,lSel]=GetSelPt3D(ax,pt)
%GetSelPt3D - Get 3D-selected point in an axes
%   [ptSel,iPt,dMin,lSel]=GetSelPt3D(ax,pt)
%   [ptSel,iPt,dMin,lSel]=GetSelPt3D(l,pt)
%          ax: axes (default gca)
%          l:  line handle
%          pt: point to find in data (default CurrentPoint)
%
%          ptSel: 3D coordinates of point found
%          iPt: index of point found in line
%          dMin: distance between point and requested point in projected plane
%          lSel: handle to line

l=[];
if nargin<1||isempty(ax)
	ax=gca;
elseif ~strcmp(get(ax,'Type'),'axes')
	l=ax;
	ax=ancestor(l,'axes');
	if isempty(ax)
		error('Can''t find the axes?!')
	end
end
if nargin<2||isempty(pt)
	pt=get(ax,'CurrentPoint');
end
A=view(ax);
BAR=get(ax,'PlotBoxAspectRatio');

ptTX=[bsxfun(@rdivide,pt,BAR),ones(size(pt,1),1)]*A';

if isempty(l)
	l=[findobj(ax,'Type','line')' findobj(ax,'Type','hggroup')'];
	if isempty(l)
		warning('No lines found!')
	end
end
dMin=Inf;
lSel=0;
iPt=0;
ptSel=[0 0 0];
for i=1:length(l)
	x=get(l(i),'xdata');
	y=get(l(i),'Ydata');
	z=get(l(i),'zdata');
	T=[x(:)/BAR(1) y(:)/BAR(2) z(:)/BAR(3) ones(length(x),1)]*A';
	D=(T(:,1)-ptTX(1,1)).^2+(T(:,2)-ptTX(1,2)).^2;
	[d,iMn]=min(D);
	if d<dMin
		dMin=d;
		lSel=l(i);
		iPt=iMn;
		ptSel=[x(iMn) y(iMn) z(iMn)];
	end
end
