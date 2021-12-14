function navline(s,x,y,i,di)
% NAVLINE  - Laat toe te 'navigeren' over een lijn.
%
%   navline('start',x,y,i)
if nargin
	if isstr(s)
		if strcmp(s,'start')
			g=struct('X',x,'Y',y	...
				,'l0',length(i)	...
				,'i',i,'di',di	...
				,'OldKeyPress',get(gcf,'KeyPressFcn'));
			set(gcf,'KeyPressFcn','navline');
			line(x(i),y(i)	...
				,'Color',[0 0 0]	...
				,'UserData',g	...
				,'EraseMode','xor'	...
				,'Tag','navline'	...
				)
		end
		return
	end
end

l=findobj(gcbf,'Tag','navline');
c=get(gcbf,'CurrentCharacter');
g=get(l,'UserData');
hertekenen=0;
switch c
	case 'n'
		if (length(g.i)<g.l0)&(g.i(1)==1)
			g.i=[(1:g.di)';g.i(:)];
		else
			g.i=g.i+g.di;
		end
		hertekenen=1;
	case 'N'
		g.i=g.i+round((g.i(end)-g.i(1))*0.9);
		hertekenen=1;
	case 'p'
		g.i=g.i-g.di;
		hertekenen=1;
	case 'P'
		g.i=g.i-round((g.i(end)-g.i(1))*0.9);
		hertekenen=1;
	case 's'
		set(gcbf,'KeyPressFcn',g.OldKeyPress);
		delete(l);
		return
end
if isempty(g.i)
	return
end
if g.i(end)>length(g.X)
	g.i(find(g.i>length(g.X)))=[];
end
if g.i(1)<1
	g.i(find(g.i<1))=[];
end
if hertekenen
	set(l,'XData',g.X(g.i),'YData',g.Y(g.i),'UserData',g);
end
