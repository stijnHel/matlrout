function out=ShowUIs(fig,fCopy,varargin)
%ShowUIs - Show UI's on a figure (copying them to another figure)
%     ShowUIs([fig[,fCopy]])
%
%   See CopyControls - want dit is hetzelfde

[bShowTag] = true;
[bShowType] = false;
[bShowStyle] = false;
[bShowString] = false;
[bSetNormalized] = true;

if nargin==0
	fig=[];
end
if nargin<2
	fCopy=[];
	options={};
elseif ischar(fCopy)
	options=[fCopy,varargin];
	fCopy=[];
end
if isempty(fig)
	fig=gcf;
	fCopy=[];
end
if ~isempty(options)
	setoptions({'bShowTag','bShowType','bShowString','fCopy'	...
		,'bShowStyle','bSetNormalized'},options{:})
end

if isempty(fCopy)
	fCopy=nfigure('Position',get(fig,'Position'),'Name','UI-copy');
end
H=get(fig,'Children');

notCopied = cell(0,2);
for i=1:length(H)
	h=[];
	tp = get(H(i),'Type');
	switch tp
		case 'uicontrol'
			p = GetPos(H(i));
			h=uicontrol(fCopy,'Style','pushbutton','Enable','off','Position',p);
			tg = get(H(i),'Tag');
			if ~isempty(tg)&&bShowTag
				set(h,'String',tg)
			end
			if bShowString
				s=get(H(i),'String');
				if ischar(s)&&~isempty(s)&&size(s,1)==1
					set(h,'String',s)
				end
			end
			if bShowStyle
				set(h,'String',get(H(i),'Style'))
			end
		case 'axes'
			p = GetPos(H(i));
			h=uicontrol(fCopy,'Style','pushbutton','Enable','off','Position',p);
			tg = get(H(i),'Tag');
			if ~isempty(tg)
				set(h,'String',tg)
			end
		case 'uimenu'
			% don't
		otherwise
			B=strcmp(tp,notCopied(:,1));
			if any(B)
				notCopied{B,2}(end+1)=H(i);
			else
				notCopied{end+1,1} = tp; %#ok<AGROW>
				notCopied{end,2} = H(i);
			end
	end
	if bShowType&&~isempty(h)
		set(h,'String',tp)
	end
end
if bSetNormalized
	set(get(fCopy,'Children'),'Units','normalized')
end
if nargout
	out = notCopied;
end

function p = GetPos(h)
u = get(h,'Units');
b = false;
if ~strcmp(h,'pixels')
	b = true;
	set(h,'Units','pixels')
end
p = get(h,'Position');
if b
	set(h,'Units',u)
end
