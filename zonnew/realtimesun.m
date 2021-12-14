function varargout=realtimesun(in,varargin)
%realtimesun - testfunctie

f=findobj('Tag','RTsunFIG');
if nargin==0
	p=[];
	if ~isempty(f)
		p=get(f,'position');
		close(f);
	end
	f=nfigure;
	set(f,'DeleteFcn',@StopRTsun	...
		,'Tag','RTsunFIG');
	if ~isempty(p)
		set(f,'Position',p);
	end
	tim=timer('ExecutionMode','fixedRate','Period',60	...
		,'TimerFcn','realtimesun upd');
	setappdata(f,'timerobj',tim)
	set(tim,'UserData',f)
	set(tim,'StopFcn','disp(''timer gestopt'')')
	start(tim)
	if nargout
		varargout{1}=f;
	end
	return
elseif isnumeric(in)
	dt=1/24/60;
	if length(in)==1
		% doe niets
	elseif length(in)==2
		dt=in(2);
		in=in(1);
	elseif length(in)<=6
		if length(in)<6
			in(6)=0;
		end
		if in(3)>40
			in([1 3])=in([3 1]);
		end
		in=datenum(in);
	end
	f=realtimesun;
	tim=getappdata(f,'timerobj');
	stop(tim);
	l=get(f,'UserData');
	if isempty(l)
		realtimesun upd
		l=get(f,'UserData');
	end
	if length(in)>1
		T=in;
	else
		T=in:dt:now;
		if isempty(T)
			warning('!!!gevraagd om te starten vanaf ogenblik in de toekomst?!!! - niet mogelijk')
			return
		end
	end
	X=T;
	Y=T;
	status('Bepalen van eerdere posities',0)
	for i=1:length(T)
		t=datevec(T(i));
		tut=getutctime(t([3 2 1 4 5 6]));
		p=calcposhemel([],tut)*180/pi;
		X(i)=p(1);
		Y(i)=p(2);
		status(i/length(T))
	end
	status
	set(l(1),'XData',p(1),'YData',p(2))	% ,'ZData',T(end)) % removed for ML R2016
	set(l(2),'XData',X,'YData',Y,'ZData',T)
	realtimesun doorg
	start(tim)
	return
elseif strcmp(in,'doorg')
	iStart=0;
	if isempty(varargin)
		y0=0;
	else
		y0=varargin{1};
		if length(varargin)>1
			if ~isempty(varargin{2})
				iStart=varargin{2};
			end
		end
	end
	l=get(f,'UserData');
	ax=get(l(1),'parent');
	X=get(l(2),'XData');
	Y=get(l(2),'YData');
	T=get(l(2),'ZData');
	i=find(Y(iStart+2:end)>=y0&Y(iStart+1:end-1)<y0);
	if ~isempty(i)
		i=i(end)+iStart;
		t0=interp1(Y(i:i+1),T(i:i+1),y0);
		x0=interp1(T(i:i+1),X(i:i+1),t0);
		text(x0,y0,datestr(t0,13),'HorizontalAlignment','left'	...
			,'VerticalAlignment','top'	...
			,'Tag','doorgup','Parent',ax)
	end
	i=find(Y(iStart+2:end)<=y0&Y(iStart+1:end-1)>y0);
	if ~isempty(i)
		i=i(end)+iStart;
		t0=interp1(Y(i:i+1),T(i:i+1),y0);
		x0=interp1(T(i:i+1),X(i:i+1),t0);
		text(x0,y0,datestr(t0,13),'HorizontalAlignment','right'	...
			,'VerticalAlignment','top'	...
			,'Tag','doorgdown','Parent',ax)
	end
	return
end

if isempty(f)
	warning('!!??Er loopt iets fout!!')
	return
end
tcl=clock;
t=datenum(tcl);
tut=getutctime(tcl([3 2 1 4 5 6]));
p=calcposhemel([],tut)*180/pi;
l=get(f,'UserData');
if isempty(l)
	l=plot(p(1),p(2),'o',p(1),p(2),'.');grid
	set(l(1),'MarkerSize',10)
	set(l(2),'zdata',t);
	set(l,'color',[0 0 1])
	l(3)=text(0,0,'','horizontalalignment','center');
	l(4)=get(gca,'title');
	l(5)=get(gca,'xlabel');
	set(f,'UserData',l,'NextPlot','new');
	T=t;
	X=p(1);
	Y=p(2);
else
	X=get(l(2),'XData');
	Y=get(l(2),'YData');
	T=get(l(2),'ZData');
	if strcmp(in,'get')
		varargout{1}=struct('t',T,'X',X,'Y',Y);
		return
	end

	T(end+1)=t;
	X(end+1)=p(1);
	Y(end+1)=p(2);
	set(l(1),'XData',p(1),'YData',p(2))%,'ZData',t) % t removed due to bug/??? in ML R2016
	set(l(2),'XData',X,'YData',Y,'ZData',T)
	realtimesun('doorg',0,length(T)-2)
end
[mx,tmx]=max(Y);
[mn,tmn]=min(Y);
set(l(4),'string',sprintf('%s - %s',datestr(T(1)),datestr(T(end))))
set(l(5),'string',sprintf('(%5.2f,%5.2f,%s)---(%5.2f,%5.2f,%s)'	...
	,X(tmn),mn,datestr(T(tmn),13)	...
	,X(tmx),mx,datestr(T(tmx),13)))
set(l(3),'String',sprintf('(%6.3f,%6.3f)',X(end),Y(end))	...
	,'Position',[min(max(X(1),0),mean(X)),min(max(0,min(0,min(Y))),mx)])

function StopRTsun(h,ev)
ttt=getappdata(h,'timerobj');
stop(ttt);
delete(ttt);
