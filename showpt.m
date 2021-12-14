function showpt(l,ax,options)
% SHOWPT   - Toont punten aangeklikt in een grafiek in andere grafieken
%    showpt(l,ax,options)
%         l : lijn die aangeklikt kan worden
%         ax : as (of assen) waar lijn getoond moet worden bij aanklikken
%                 of lijnen die assen aangeven
%              bij aangeven van lijnen, wordt de data van deze lijnen gebruik
%                 voor het tekenen van de lijnen
%              bij aangeven van assen moet er minstens een lijn zijn, en
%                 wordt de eerst gevonden lijn genomen om de data uit te halen.
%         options :
%              niet gegeven : default : vertikale lijn
%              'hor' : horizontale lijn
%              'ver' : vertikale lijn
%              'all' : horizontale en vertikale lijn
%    !!!!!!!!!dit was maar een idee, maar werd nog niet geimplementeerd
%  2003 - Stijn Helsen

if nargin==1
	if ischar(l)
		lin=gco;
		switch l
		case 'delete'
			lines=get(lin,'userdata');
			for i=1:size(lines,1)
				try
					delete(lines(i,1));
				catch
					% just continue
				end
			end
		case 'stopfollow'
			set(gcf,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[]);
		end	% if delete
	else	% no char
		error('Verkeerd gebruik van showpt');
	end
	return
elseif nargin>1
	% setup
	if length(l)~=1|~strcmp(get(l,'type'),'line')
		error('verkeerd gebruik van showpt')
	end
	hor=0;
	ver=0;
	if exist('options')&~isempty(options)
		switch lower(options(1:3))
		case 'hor'
			hor=1;
		case 'ver'
			ver=1;
		case 'all'
			hor=1;
			ver=1;
		end
	else
		ver=1;
	end
	lines=zeros(0,2);
	for i=1:length(ax)
		switch get(ax(i),'Type')
		case 'line'
			ax1=get(ax(i),'Parent');
			if hor
				z=get(ax(i),'YData');
				lines(end+1,1)=line(get(ax1,'XLim'),z([1 1])	...
					,'Tag','showPtline','UserData',[0 ax(i)]	...
					,'Parent',ax1	...
					);
				lines(end,2)=ax(i);
				% (now double information is stored)
			end
			if ver
				z=get(ax(i),'XData');
				lines(end+1,1)=line(z([1 1]),get(ax1,'YLim')	...
					,'Tag','showPtline','UserData',[1 ax(i)]	...
					,'Parent',ax1	...
					);
				lines(end,2)=ax(i);
			end
		end	% switch
	end	% for i
	set(l,'ButtonDownFcn','showpt'	...
		,'UserData',lines	...
		,'DeleteFcn','showpt(''delete'')');
	setappdata(get(get(l,'Parent'),'Parent'),'showptline',l);
	return
end

l=gco;
switch get(l,'Type')
case 'line'
	% ok
case 'axes'
	l=getappdata(get(l,'Parent'),'showptline');
case 'figure'
	l=getappdata(l,'showptline');
otherwise
	error('Verkeerd gebruik');
end
x=get(l,'XData');
y=get(l,'YData');
lines=get(l,'UserData');
p=get(gca,'CurrentPoint');

[mn,ipt]=min((x-p(1,1)).^2+(y-p(1,2)).^2);
for i=1:size(lines,1)
	d=get(lines(i,1),'UserData');
	if d(1)	% vertical
		z=get(lines(i,2),'XData');
		set(lines(i,1),'XData',[z(ipt) z(ipt)]);
	else
		z=get(lines(i,2),'YData');
		set(lines(i,1),'YData',[z(ipt) z(ipt)]);
	end
end
set(gcf,'WindowButtonMotionFcn','showpt','WindowButtonUpFcn','showpt(''stopfollow'')')
