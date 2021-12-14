function visAxJumper(varargin)
%visAxJumper - visual data in axes jumper
%    visAxJumper - initializes window to jump
%  clicking in right half jumps to first visible point to the right
%  clicking in left half jumps to first visible point to the right

if nargin==0
	f=gcf;
else
	f=varargin{1};
end
ax=findobj(f,'type','axes','tag','');
set(ax,'ButtonDownFcn',@jumpAx)

function jumpAx(h,~)
pt=get(h,'currentpoint');
xPt=pt(1);
xl=get(h,'xlim');
l=findobj(h,'type','line');
lMx=0;
mx=0;
for i=1:length(l)
	n=length(get(l(i),'xdata'));
	if n>mx
		lMx=l(i);
		mx=n;
	end
end
x=get(lMx,'XData');
if (xPt-xl(1))/diff(xl)<0.5
	i=find(x<xPt,1,'last');
	nXl=x(i)-[diff(xl) 0];
else
	i=find(x>xPt,1,'first');
	nXl=x(i)+[0 diff(xl)];
end
if x(i)>=xl(1)&&x(i)<=xl(2)
	return
end
if isempty(i)
	error('not found')
end
ff=getappdata(get(h,'parent'),'linkednavfig');
if isempty(ff)
	ff=get(h,'parent');
end
if length(ff)>1
	bepfigs(nXl,ff)
else
	bepfig(nXl,ff)
end
