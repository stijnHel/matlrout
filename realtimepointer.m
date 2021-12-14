function Mout=realtimepointer(ax,varargin)
%realtimepointer - Realtime follower in a graph
%    Plot a line (or lines) and move it in real time.
%      realtimepointer(ax[,...])
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
%             'makemovie' : to make a movie (rather than doing it realtime)
%                 if number : movie is an output of the function
%                    (matlab-movie)
%                 if string : name of the movie (written by movie2avi)
%                 currently the axes is saved in the movie(!!)
%             'moviecomp' : compression
%             'movietype' : 'fig' or 'axe'
%
%  Stijn Helsen/FMTC   - October 2006


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
makemovie=[];
moviecomp='None';
movietype='axes';
if ~isempty(varargin)
	if iscell(varargin{1})
		options=varargin{1};
	else
		options=varargin;
	end
	if rem(length(options),2)
		error('A set of pairs of names and values should be supplied')
	end
	posopt={'or','lim','dt','col','makemovie','moviecomp','movietype'};
	for i=1:2:length(options)
		j=strmatch(lower(options{i}),posopt);
		if isempty(j)
			error('Unkown option (%s)',options{i})
		end
		assignval(posopt{j},options{i+1})
	end
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
if isempty(makemovie)
	ftime=24*3600;
	t0=now;
	t=lim(1);
	while t<lim(2)
		t=(now-t0)*ftime+lim(1);
		set(lin,tdata,t+[0 0])
		pause(dt)
	end
else
	switch lower(movietype(1:min(end,3)))
		case 'fig'
			framehandle=gcf;
		case 'axe'
			framehandle=gca;
		otherwise
			framehandle=gca;
			warning('!!!Unkown movietype (axes (default) or figure)!!!')
	end
	M=getframe(framehandle);
	t=lim(1);
	i=1;
	while t<lim(2)
		t=min(lim(2),t+dt);
		set(lin,tdata,t+[0 0])
		i=i+1;
		M(i)=getframe(framehandle);	% to use the figure write getframe(gcf) or something like that
	end
	if ischar(makemovie)
		movie2avi(M,makemovie,'FPS',1/dt,'COMPRESSION',moviecomp)
	else
		Mout=M;
	end
end
delete(lin)
