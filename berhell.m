function out=berhell(l,dx,varargin)
% BERHELL  - Berekent helling van een lijn.
%    berhell(l,dx)   (default dx=1)
%       Zet ButtonDownFcn van l op berhell
%    berhell(f,dx) met f wijzend naar een as of een figuur
%       Zet ButtonDownFcn van alle lijnen van f op berhell

persistent BSettings

sSettings={'bRevGrad','bShowOnPlot'	...
	};
if isempty(BSettings)
	bShowOnPlot=true;
	bRevGrad=false;
	BSettings=var2struct(sSettings);
else
	struct2var(BSettings)
end
bSwitchOff=false;
if nargin>0&&ischar(l)
	if strcmpi(l,'settings')
		if nargin==1
			disp(BSettings)
		elseif nargin==2&&ischar(Y)
			if strcmpi(Y,'default')
				BSettings=[];	% will be set next time
			else
				error('Bad input')
			end
		else
			switch nargin
				case 2
					options=dx;
				otherwise
					options=[{dx},varargin];
			end
			BSettings=setoptions(BSettings,options{:});
		end
		if nargout
			out=BSettings;
		end
		return
	elseif strcmpi(l,'off')
		l=gcf;
		bSwitchOff=true;
	else
		error('Wrong input!')
	end
end

if nargin
	% setup
	if nargin==1
		dx=1;
	elseif isempty(dx)
		dx=1;
	elseif ischar(dx)
		if ~strcmpi(dx,'off')
			error('Unexpected input!')
		end
		bSwitchOff=true;
	end
	if length(l)==1
		t=get(l,'Type');
		if strcmp(t,'figure')||strcmp(t,'axes')
			l=findobj(l,'Type','line');
		end
	end
	if bSwitchOff
		set(l,'ButtonDownFcn','1;')
	else
		set(l,'ButtonDownFcn','berhell','UserData',dx)
	end
	return
end

l=gco;
ax=ancestor(l,'axes');
x=get(l,'XData');
y=get(l,'YData');
dx=get(l,'UserData');
xl=get(ax,'XLim');
yl=get(ax,'YLim');
p=get(ax,'CurrentPoint');
xType=get(ax,'XScale');
yType=get(ax,'YScale');
bXlog=strcmp(xType,'log');
bYlog=strcmp(yType,'log');

x0=p(1,1);
if bXlog
	x=log(x);
	xl=log(xl);
	x0=log(x0);
end
if bYlog
	y=log(y);
	yl=log(yl);
end
if dx<0
	dx=-dx*diff(xl);
end
xb=x0-dx;
xe=x0+dx;
i=find((x>=xb)&(x<=xe));
if length(i)<2
	if x0<min(x)||x0>max(x)
		return
	end
	i1=find((x>=xl(1))&(x<=xl(2)));
	if length(i1)<5
		warning('BERHELL:lowNumPt','Te weinig punten op grafiek!!!')
		return
	end
	meandx=mean(diff(x(i1)));
	if meandx*1.5>dx
		dx=meandx*1.5;
		xb=x0-dx;
		xe=x0+dx;
		i=find((x>=xb)&(x<=xe));
		if length(i)<2
			warning('BERHELL:lowNumPt2','Te weinig punten gevonden, ook na vergroting marge')
			return
		end
		warning('BERHELL:marginIncreased','Te weinig punten gevonden - marge vergroot!!')
	else
		warning('BERHELL:lowNumPt3','Te weinig punten gevonden')
		return
	end
end
if length(i)<4
	warning('BERHELL:lowNumPt4','Weinig punten gevonden ! (%d)',length(i))
end

if ~isfloat(x)
	x = double(x);
end
if ~isfloat(y)
	y = double(y);
end

xFit=x(i);
yFit=y(i);
y0 = mean(yFit);

p=polyfit(xFit-x0,yFit-y0,1);
p(2) = p(2)+y0;
y0=polyval(p,0);
xunit=extractunit(get(get(ax,'xlabel'),'string'));
yunit=extractunit(get(get(ax,'ylabel'),'string'));
if ~isempty(xunit)&&~isempty(yunit)
	%!!!!!!!!!!!!!!if [X/Y]log!!!!!!!!!!!!!!!!!!!
	hellunit=sprintf('%s/%s',yunit,xunit);
	fprintf('Helling rond (%g (+/-%g),%g #%d) is %g [%s]',x0,dx,y0,length(i),p(1),hellunit)
	if bRevGrad
		fprintf('   reversed: %g %s/%s',1/p(1),yunit,xunit) %#ok<UNRCH>
		hellunit=sprintf('%s/%s',xunit,yunit);
	end
else
	hellunit='';
	fprintf('Helling rond (%g (+/-%g),%g #%d) is %g',x0,dx,y0,length(i),p(1))
	if bRevGrad
		fprintf('   reversed: %g',1/p(1)) %#ok<UNRCH>
	end
end
fprintf('\n')

if bShowOnPlot
	Dx=3*dx;
	if Dx>diff(xl)/2
		Dx=diff(xl)/2;
	elseif Dx<diff(xl)/20
		Dx=diff(xl/20);
	end
	x1=x0-Dx;
	x2=x0+Dx;
	y1=polyval(p,x1-x0);
	if p(1)>0
		if yl(1)>y1
			x1=min(x0+(yl(1)-p(2))/p(1),xb);
		end
	else
		if yl(2)<y1
			x1=min(x0+(yl(2)-p(2))/p(1),xb);
		end
	end
	y2=polyval(p,x2-x0);
	if p(1)>0
		if yl(2)<y2
			x2=max(x0+(yl(2)-p(2))/p(1),xe);
		end
	else
		if yl(1)>y2
			x2=max(x0+(yl(1)-p(2))/p(1),xe);
		end
	end
	y=polyval(p,[x1 xb x0 xe x2]-x0);
	dy=diff(yl)/20;
	yL1=[y(2)-dy y(2)+dy];
	yL2=[y(4)-dy y(4)+dy];
	if bXlog
		x0=exp(x0);
		x1=exp(x1);
		x2=exp(x2);
		xb=exp(xb);
		xe=exp(xe);
	end
	yText=y0+4*dy;
	if bYlog
		y=exp(y);
		yL1=exp(yL1);
		yL2=exp(yL2);
		yText=exp(yText);
		y0=exp(y0);
	end
	l=line([x1 x2],y([1 end]));
	l1=line([xb xb],yL1);
	l2=line([xe xe],yL2);
	l3=line(x0,y0,'Marker','.','MarkerSize',6);
	if bRevGrad
		if isempty(hellunit) %#ok<UNRCH>
			sval=sprintf('%g',1/p(1));
		else
			sval=sprintf('%g [%s]',1/p(1),hellunit);
		end
	else
		if isempty(hellunit)
			sval=sprintf('%g',p(1));
		else
			sval=sprintf('%g [%s]',p(1),hellunit);
		end
	end
	t=text(x0,yText,sval,'HorizontalAlignment','center');
	beruis=[l l1 l2 l3 t];
	set(beruis,'ButtonDownFcn','delete(get(gco,''UserData''));','UserData',beruis)
end

function unit=extractunit(s)
if isempty(s)
	unit='';
	return
end
i1=find(s=='[');
i2=find(s==']');
if (length(i1)==1)&&(length(i2)==1)&&(i1<i2)
	unit=s(i1+1:i2-1);
else
	unit='';
end
