function Xout=rbline(X0,varargin)
%rbline   - user-interactive line drawing
%     A bit similar to rbbox, it is possible to ask for a line, or at
%     least ask for one or two points.
%     (The line is removed after getting the points.)
%         X=rbline([X0[,options]]);
%         If X0 is given, a line is drawn from this point, otherwise
%            the function waits until the first mousebutton press.
%     Some options are used for this function, others are given to the
%        line.  Options in this funtion:
%             'stoptype' : if only button up or down is wanted ('up' or 'down')
%             'action'   : action after getting the line (or point)
%                  can be a string to be executed, or a function, or
%                     a cell vector with a function and additional inputs.
%                     if a function (with or without additional arguments),
%                       is used, the first argument will be a structure
%                       with internal fields and :
%                          X0, X1 : start and end point
%             'doResume' : if true (default) uiresume for the current
%                figure is executed.

if ~exist('X0','var')
	X0=[];
end

f=gcf;
if isempty(X0)	% ask for start and end
	pter=get(f,'Pointer');
	set(f,'Pointer','crosshair')
	bCancel=waitforbuttonpress;
	p1=get(gca,'CurrentPoint');
	if bCancel	% doesn't work in this version
		set(f,'Pointer','arrow')
		Xout=[];
		return
	end
	p1=p1(1,1:2);
	pf0=get(f,'currentpoint');
	rbline(p1(1,1:2),varargin{:});
	uiwait(gcf)
	D=getappdata(f,'rbline');
	rmappdata(f,'rbline')
	pf1=get(f,'currentpoint');
	if abs(pf1(1)-pf0(1))<2&abs(pf1(2)-pf0(2))<2
		Xout=[];
	else
		Xout=[p1;D.X1];
	end
	set(f,'Pointer',pter)
elseif isnumeric(X0)
	opts=varargin;
	l=line(X0([1 1]),X0([2 2]),'EraseMode','xor');
	D=struct('down',get(f,'WindowButtonDownFcn')	...
		,'motion',get(f,'WindowButtonMotionFcn')	...
		,'up',get(f,'WindowButtonUpFcn')	...
		,'l',l	...
		,'X0',X0	...
		,'X1',[]	...
		,'ax',gca	...
		,'stoptype',[]	...
		,'action',[]	...
		,'doResume',true	...
		);
	if ~isempty(opts)
		[D,oUsed]=setoptions(2,{'stoptype','action','doResume'},{'structBase',D,opts{:}});
		oUsed(1)=[];
		opts=opts(~[oUsed;oUsed]);
		if ~isempty(opts)
			set(l,opts{:})
		end
	end
	setappdata(f,'rbline',D);
	set(f,'WindowButtonDownFcn','rbline down'	...
		,'WindowButtonMotionFcn','rbline motion'	...
		,'WindowButtonUpFcn','rbline up'	...
		)
elseif ischar(X0)
	D=getappdata(f,'rbline');
	switch lower(X0)
		case 'motion'
			p1=get(D.ax,'CurrentPoint');
			set(D.l,'XData',[D.X0(1) p1(1)],'YData',[D.X0(2) p1(1,2)]);
			drawnow
		case {'up','down'}	%!! both !!
			% stop
			if ~isempty(D.stoptype)
				if ~strcmp(lower(X0),D.stoptype)
					return
				end
			end
			x=get(D.l,'XData');
			y=get(D.l,'YData');
			D.X1=[x(2) y(2)];
			delete(D.l);
			D.l=[];
			setappdata(f,'rbline',D);
			set(f,'WindowButtonDownFcn',D.down	...
				,'WindowButtonMotionFcn',D.motion	...
				,'WindowButtonUpFcn',D.up);
			if ~isempty(D.action)
				if ischar(D.action)
					eval(D.action)
				elseif isa(D.action,'function_handle')
					D.action(D);
				elseif iscell(D.action)
					D.action{1}(D,D.action{2:end})
				end
			end
			if D.doResume
				uiresume(f)
			end
	end
end
