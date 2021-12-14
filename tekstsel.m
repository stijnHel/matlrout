function tekstsel(x1,x2)
% TEKSTSEL - Tekst-selectie routines

if nargin==0

elseif ischar(x1)
	f=gcf;
	switch x1
		case 'down'
			switch get(f,'SelectionType')
				case 'normal'
					setappdata(f,'lastMotion',get(f,'WindowButtonMotionFcn'))
					setappdata(f,'lastUp',get(f,'WindowButtonUpFcn'))
					t=gcbo;
					ax=get(t,'Parent');
					setappdata(f,'mover',t);
					set(f,'WindowButtonMotionFcn','tekstsel motion'	...
						,'WindowButtonUpFcn','tekstsel up');
					set(t,'Visible','off')
					setappdata(t,'lastpoint',get(ax,'CurrentPoint'))
					set(t,'EraseMode','xor','Visible','on')
				case 'alt'
				case 'open'
					set(gcbo,'Editing','on')
			end
		case 'motion'
			t=getappdata(f,'mover');
			ax=get(t,'Parent');
			a1=getappdata(t,'lastpoint');
			a2=get(ax,'CurrentPoint');
			setappdata(t,'lastpoint',a2)
			set(t,'Position',get(t,'Position')-a1(1,:)+a2(2,:))
		case 'up'
			set(f,'WindowButtonMotionFcn',getappdata(f,'lastMotion')	...
				,'WindowButtonUpFcn',getappdata(f,'lastUp'));
			t=getappdata(f,'mover');
			rmappdata(f,'lastMotion')
			rmappdata(f,'lastUp')
			rmappdata(f,'mover')
			rmappdata(t,'lastpoint')
			set(t,'Visible','off')
			set(t,'EraseMode','normal','Visible','on')
		case 'start'
			set(x2,'ButtonDownFcn','tekstsel down','HitTest','on')
		case 'stop'
			set(x2,'HitTest','off');
	end
end

