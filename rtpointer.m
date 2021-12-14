function rtpointer(ax,varargin)
%rtpointer - Realtime follower in a graph - with matlab-timer
%    Plot a line (or lines) and move it in real time.
%      rtpointer(ax[,...])
%          ax : axes or figures where pointers should be drawn
%          ... : options : pairs of option names and values
%             'or' : orientation : 'horizontal' or 'vertical'
%                         (in fact 'ho' or 've' but words are clipped)
%             'lim' : time span to follow (in seconds)
%                 default : limit of first found axes
%             'dt' : update time (in seconds)
%                 default 0.1 s
%             'col' : color of pointer lines (vector or matlab name)
%                 default red
%             'ftime' : factor between "axes-dimension" and seconds
%                    (use 1000 if plot is in ms, 1/3600 if plot is in hours)
%
%  see also realtimepointer (similar but without use of timer)


if ~exist('ax','var')||isempty(ax)
	ax=gca;
else
	ax=findobj(ax,'Type','axes');
end
% Default values for options
or='hor';
lim=[];
col=[1 0 0];
dt=0.1;
ftime=1;
if ~isempty(varargin)
	posopt={'or','lim','dt','col','ftime'};
	setoptions(posopt,varargin{:})
end
lin=zeros(1,length(ax));
figure(get(ax(1),'parent'))

switch lower(or(1:min(2,end)))
	case 'ho'
		direc=1;
		if isempty(lim)
			lim=get(ax(1),'xlim');
		end
		for i=1:length(ax)
			lin(i)=line(lim(1)+[0 0],get(ax(i),'ylim')	...
				,'parent',ax(i),'color',col	...
				,'EraseMode','xor'	...
				);
		end
		tdata='XData';
	case 've'
		direc=2;
		if isempty(lim)
			lim=get(ax(1),'ylim');
		end
		for i=1:length(ax)
			lin(i)=line(get(ax(i),'xlim'),lim(1)+[0 0]	...
				,'parent',ax(i),'color',col	...
				,'EraseMode','xor'	...
				);
		end
		tdata='YData';
	otherwise
		error('Wrong use of this function')
end
t0=now;
t=lim(1);
Tdata=struct('ftime',ftime*24*3600,'axes',tdata,'lim',lim,'t0',t0,'lin',lin);
if false
tim=timer('ExecutionMode','singleShot'	...
	,'TimerFcn',@Update,'UserData',Tdata);
else
tim=timer('ExecutionMode','fixedRate','Period',dt	...
	,'TimerFcn',@Update,'UserData',Tdata);
end
start(tim)

	function Update(h,ev)
		Tdata=get(h,'UserData');
		t=(datenum(ev.Data.time)-Tdata.t0)*Tdata.ftime+Tdata.lim(1);
		set(Tdata.lin,Tdata.axes,t+[0 0])
		if t>=lim(2)
			stop(tim)
			disp('..... the end')
			delete(Tdata.lin)
			delete(tim);
		end
	end
end
