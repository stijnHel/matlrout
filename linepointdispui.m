function linepointdispui(varargin)
%linepointdispui - UI to show values of points of line
%
%  This is a quickly made function to show values of a line.
%   Use :
%       linepointdisp    : all default on the lines of the current figure
%       linepointdisp start <options>
%       linepointdisp('start',<linehandles>[,<options>])
%   Options :
%       'crosshair' : makes a crosshair as a pointer for this figure
%       'fullcrosshair' : makes a fullcrosshair (over the total width and
%                         heigt of the figure
%        'fixedtextbox' : uses a fixed box (per line)
%        'alsomovingtext' : normally a fixed box doesn't give a moving
%                           box, with this option, both boxes can be shown
%        'adddot' : shows a dot of the point data shown

if nargin==0
	l=findobj(gcf,'type','line');
	if isempty(l)
		error('No lines can be found in this figure')
	end
	linepointdispui('start',l)
elseif ischar(varargin{1})
	switch lower(varargin{1})
		case 'start'
			t=findobj(gcf,'Tag','linepointuibox');
			delete(t)
			l=varargin{2};
			iOption=3;
			if ischar(l)
				iOption=2;
				l=[];
			end
			if isempty(l)
				l=findobj(gcf,'Type','line');
			end
			set(l,'ButtonDownFcn','linepointdispui btdown')
			valform='(%g,%g)';
			for i=1:length(l)
				setappdata(l(i),'alsomovingtext',false);
				setappdata(l(i),'showdot',false);
				setappdata(l(i),'fixedtext',[]);
			end
			while iOption<=length(varargin)
				switch varargin{iOption}
					case 'crosshair'
						set(gcf,'Pointer','crosshair')
					case 'fullcrosshair'
						set(gcf,'Pointer','fullcrosshair')
					case 'fixedtextbox'
						x0=0;
						for i=1:length(l)
							txt=uicontrol('Position',[x0 0 x0+100 15]	...
								,'Style','text','Tag','linepointuibox');
							setappdata(l(i),'fixedtext',txt);
						end
					case 'alsomovingtext'
						for i=1:length(l)
							setappdata(l(i),'alsomovingtext',true)
						end
					case 'adddot'
						for i=1:length(l)
							setappdata(l(i),'showdot',true)
						end
					otherwise
						warning('!!!Unkown option "%s"!!!',varargin{iOption})
				end
				iOption=iOption+1;
			end
			for i=1:length(l)
				setappdata(l(i),'valform',valform);
			end
		case 'btdown'
			l=gcbo;
			bMovText=getappdata(l,'alsomovingtext');
			bShowDot=getappdata(l,'showdot');
			txt=getappdata(l,'fixedtext');
			if isempty(txt)||bMovText
				txt=text(0,0,'','HorizontalAlignment','center','VerticalAlignment','bottom');
				setappdata(l,'movingtext',txt);
			end
			if bShowDot
				lDot=line(0,0,'marker','o','color',get(l,'color'));
				setappdata(l,'hDot',lDot);
			end
			setappdata(l,'LastButMovFcn',get(gcf,'WindowButtonMotionFcn'))
			setappdata(l,'LastButUpFcn',get(gcf,'WindowButtonUpFcn'))
			setappdata(gcf,'currentLine',l);
			set(gcf,'WindowButtonMotionFcn','linepointdispui btmove'	...
				,'WindowButtonUpFcn','linepointdispui btup')
			linepointdispui btmove
		case 'btmove'
			l=getappdata(gcf,'currentLine');
			pt=get(gca,'CurrentPoint');
			x=get(l,'XData');
			i=findclose(x,pt(1));
			y=get(l,'YData');
			valform=getappdata(l,'valform');
			%s=sprintf(valform,pt(1,1:2));
			s=sprintf(valform,[x(i) y(i)]);
			txt=getappdata(l,'fixedtext');
			if ~isempty(txt)
				set(txt,'string',s);
			end
			txt=getappdata(l,'movingtext');
			if ~isempty(txt)
				set(txt,'String',s,'Position',[x(i) y(i)]);
			end
			bShowDot=getappdata(l,'showdot');
			if bShowDot
				lDot=getappdata(l,'hDot');
				set(lDot,'XData',x(i),'YData',y(i))
			end
		case 'btup'
			l=getappdata(gcf,'currentLine');
			txt=getappdata(l,'movingtext');
			if ~isempty(txt)
				delete(txt);
			end
			set(gcf,'WindowButtonMotionFcn',getappdata(l,'LastButMovFcn')	...
				,'WindowButtonUpFcn',getappdata(l,'LastButUpFcn'))
			bShowDot=getappdata(l,'showdot');
			if bShowDot
				lDot=getappdata(l,'hDot');
				delete(lDot)
			end
	end
else
	error('Wrong use of this function')
end
