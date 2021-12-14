function nextfig(x,f)
if ~exist('f')
	f=[];
end
if exist('x')
	if isstr(x)&strcmp(x,'init')
		if isempty(f)
			f=sort(findobj('Type','figure'));
		end
		set(f,'UserData',f,'KeyPressFcn','nextfig');
		return
	end
end
a=get(gcf,'CurrentCharacter');
if (a>='1')&(a<='9')
	i=str2num(a);
	if any(i==get(0,'children'))
		figure(i)
	end
elseif (a>='a')&(a<='z')
	i=abs(a)-abs('a')+10;
	if any(i==get(0,'children'))
		figure(i)
	end
elseif (a>='A')&(a<='Z')
	i=abs(a)-abs('A')+10;
	if any(i==get(0,'children'))
		figure(i)
	end
else
	x=get(gcf,'userdata');
	if ~isstr(x)&(min(size(x))==1)
		if length(x)==1
			figure(x)
			return
		end
		i=find(x==gcf);
		if isempty(i)
			return
		end
		i=i(1)+1;
		if i>length(x)
			i=1;
		end
		figure(x(i))
	end
end