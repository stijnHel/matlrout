function linkfigs(f)
% LINKFIGS - Linkt figuren door keypress

if nargin==0
	f=sort(findobj('type','figure'));
end

for i=1:length(f)
	set(f(i),'UserData',f(rem(i,length(f))+1)	...
		,'KeyPressFcn',@Next)
end

function Next(f,~)
fNext=get(f,'UserData');
if ishandle(fNext)
	figure(fNext)
else
	warning('Link from %d (to %d) stopped',double(f),double(fNext))
	set(f,'UserData',[],'KeyPressFcn','')
end
