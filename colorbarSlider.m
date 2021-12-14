function colorbarSlider(ax,varargin)
%colorbarSlider - Slider for variable colorbar

if nargin==0||isempty(ax)
	ax=gca;
	if ~strcmp(get(ax,'Tag'),'Colorbar')
		ax=findobj(gcf,'Tag','Colorbar');
		if isempty(ax)
			error('Can''t find a colorbar')
		elseif length(ax)>1
			ax=ax(1);
			warning('CBslider:multiColorbars','More than one colorbar found, one is taken!')
		end
	end
elseif ischar(ax)
	f=gcf;
	D=getappdata(f,'colorBarLine');
	switch lower(ax)
		case 'off'
			lS=[findobj(f,'Tag','MinScale');findobj(f,'Tag','MaxScale')];
			if ~isempty(lS)
				delete(lS)
			end
			if ~isempty(D)
				rmappdata(f,'colorBarLine');
			end
		case 'cancel'
			if isempty(D)
				error('Only possible if colorbarSlider was initialized correctly')
			end
			D.L=[0 1];
			setappdata(f,'colorBarLine',D);
			set(f,'Colormap',D.D.ccc)
			Replot(D)
		otherwise
			error('Unknown use of this function')
	end
	return
end
xl=get(ax,'Xlim');
yl=get(ax,'ylim');
f=get(ax,'parent');

line(xl,yl([1 1]),'linewidth',3,'Tag','MinScale','Parent',ax	...
	,'ButtonDownFcn',@MouseDown,'UserData',1		...
	);
line(xl,yl([2 2]),'linewidth',3,'Tag','MaxScale','Parent',ax	...
	,'ButtonDownFcn',@MouseDown,'UserData',2);

ccc=get(f,'colormap');

D=var2struct('yl','ccc');
set(ax,'UserData',D);

function MouseDown(h,ev)
f=ancestor(h,'figure');
fMBM=get(f,'WindowButtonMotionFcn');
fMBU=get(f,'WindowButtonUpFcn');
set(f,'WindowButtonMotionFcn',@MouseMoved	...
	,'WindowButtonUpFcn',@MouseUp);
lineT=get(h,'UserData');
ax=get(h,'Parent');
D=getappdata(f,'colorBarLine');
if isempty(D)
	L=[0 1];
else
	L=D.L;
end
D=get(ax,'UserData');
setappdata(f,'colorBarLine'	...
	,var2struct('h','ax','fMBM','fMBU','lineT','L','D'))

function MouseMoved(h,ev)
f=ancestor(h,'figure');
D=getappdata(f,'colorBarLine');
if isempty(D)
	MouseUp(h,ev)
	return
end
p=get(D.ax,'currentpoint');p=p(1,2);p0=p;
rp=min(1,max(0,(p-D.D.yl(1))/diff(D.D.yl)));
if D.lineT==1
	rp=min(D.L(2)-0.001,rp);
else
	rp=max(D.L(1)+0.001,rp);
end
p=D.D.yl(1)+rp*diff(D.D.yl);
D.L(D.lineT)=rp;
set(D.h,'YData',[p p])
setappdata(f,'colorBarLine',D);
ccc=D.D.ccc;
N=size(ccc,1)-1;
i1=1+round(D.L(1)*N);
i2=1+round(D.L(2)*N);
if i1==i2
	i1=max(1,i1-1);
	i2=min(N+1,i2+1);
end
if i1>1
	ccc(1:i1-1,:)=ccc(ones(i1-1,1),:);
end
if i2<=N
	ccc(i2+1:N+1,:)=ccc(N+ones(N-i2+1,1),:);
end
ccc(i1:i2,:)=D.D.ccc(round((0:i2-i1)/(i2-i1)*N)+1,:);
set(f,'Colormap',ccc)

function MouseUp(h,ev)
f=ancestor(h,'figure');
D=getappdata(f,'colorBarLine');
if isempty(D)
	fMBM='';
	fMBU='';
else
	fMBM=D.fMBM;
	fMBU=D.fMBU;
end
set(f,'WindowButtonMotionFcn',fMBM,'WindowButtonUpFcn',fMBU)
% draw markers again to stay on top
Replot(D)

function Replot(D)
delete(findobj(D.ax,'Tag','MinScale'))
delete(findobj(D.ax,'Tag','MaxScale'))
xl=get(D.ax,'XLim');
yl=D.D.yl(1)+D.L*diff(D.D.yl);
ccc=D.D.ccc;
N=size(ccc,1)-1;
line(xl,yl([1 1]),'linewidth',3,'Tag','MinScale','Parent',D.ax	...
	,'ButtonDownFcn',@MouseDown,'UserData',1		...
	);
line(xl,yl([2 2]),'linewidth',3,'Tag','MaxScale','Parent',D.ax	...
	,'ButtonDownFcn',@MouseDown,'UserData',2);
