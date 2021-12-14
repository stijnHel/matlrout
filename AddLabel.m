function AddLabel(m,varargin)
%AddLabel - Add label to line with contextmenu-functionality
%     Possible to set position of text
%
%     AddLabel('add',<line-handle>,<label>)
%            Adds contextmenu to add the label
%     AddLabel(<handle>)
%            Adds the label at the axes' currentpoint

if ischar(m)
	switch lower(m)
		case 'add'
			l=varargin{1};
			s=varargin{2};
			if iscell(s)
				for i=1:length(s)
					AddLabel('add',l(i),s{i})
				end
			else
				if isnumeric(s)
					s=num2str(s);
				end
				h=uicontextmenu;
				uimenu(h,'label',s,'callback',@AddLabel);
				set(h,'userdata',l)
				set(l,'uicontextmenu',h);
			end
		otherwise
			error('Unknown functionality of AddLabel')
	end
	return
end
cm=ancestor(m,'uicontextmenu');
l=get(cm,'userdata');
ax=get(l,'parent');
pt=get(ax,'CurrentPoint');
txt=get(m,'label');
t=text(pt(1,1),pt(1,2),txt,'color',get(l,'Color'),'Tag','label'	...
	,'parent',ax,'UserData',l);
h=uicontextmenu;
uimenu(h,'label','left','callback',@LeftAlign);
uimenu(h,'label','center','callback',@CenterAlign);
uimenu(h,'label','right','callback',@RightAlign);
uimenu(h,'label','top','callback',@TopAlign);
uimenu(h,'label','middle','callback',@MiddleAlign);
uimenu(h,'label','bottom','callback',@BottomAlign);
uimenu(h,'label','delete','callback',@Delete);
uimenu(h,'label','position','callback',@Position);
uimenu(h,'label','delete line','callback',@DeleteLine);
uimenu(h,'label','copy line','callback',@CopyLine);
set(h,'userdata',t)
set(t,'uicontextmenu',h);


function LeftAlign(m,varargin)
cm=ancestor(m,'uicontextmenu');
set(get(cm,'userdata'),'HorizontalAlignment','left')

function RightAlign(m,varargin)
cm=ancestor(m,'uicontextmenu');
set(get(cm,'userdata'),'HorizontalAlignment','right')

function CenterAlign(m,varargin)
cm=ancestor(m,'uicontextmenu');
set(get(cm,'userdata'),'HorizontalAlignment','center')

function TopAlign(m,varargin)
cm=ancestor(m,'uicontextmenu');
set(get(cm,'userdata'),'VerticalAlignment','top')

function MiddleAlign(m,varargin)
cm=ancestor(m,'uicontextmenu');
set(get(cm,'userdata'),'VerticalAlignment','middle')

function BottomAlign(m,varargin)
cm=ancestor(m,'uicontextmenu');
set(get(cm,'userdata'),'VerticalAlignment','bottom')

function Delete(m,varargin)
cm=ancestor(m,'uicontextmenu');
delete(get(cm,'userdata'))

function Position(m,varargin)
cm=ancestor(m,'uicontextmenu');
t=get(cm,'userdata');
ax=get(t,'parent');
axl=get(ax,'xlabel');
xls=get(axl,'string');
set(axl,'string',['nieuwe plaats voor "' get(t,'string') '"']);
[x,y,z]=ginput(1);
if isequal(z,1)
	set(t,'Position',[x y])
end
set(axl,'string',xls);

function DeleteLine(m,varargin)
cm=ancestor(m,'uicontextmenu');
ht=get(cm,'userdata');
l=get(ht,'UserData');
delete([l ht])

function CopyLine(m,varargin)
cm=ancestor(m,'uicontextmenu');
ht=get(cm,'userdata');
l=get(ht,'UserData');
nfigure
plot(get(l,'xdata'),get(l,'ydata'));grid

