function out=matchmeas(e1,ne1,e2,ne2,yoffset)
% MATCHMEAS - Zoekt (interactief) naar match tussen twee metingen
%    matchmeas(e1,ne1,e2,ne2)
%        zoekt naar een tijdverschuiving (en tijd-factor) tussen twee metingen

f=findobj('Type','figure','Tag','matchmeas');
if ~isempty(f)&nargin>3	% !!!!!!tijdelijk?????
	close(f)
	f=[];
end
if isempty(f)
	if ~exist('yoffset')|isempty(yoffset)
		yoffset=0;
	end
	f=nfigure([],'Tag','matchmeas');
	p=get(f,'position');
	b1=ceil(p(3)/2);
	h=p(4)-yoffset;
	h1=ceil(h/2);
	psel1=uicontrol('Position', [40 h-25+yoffset 120 20]   ...
		,'Style','popupmenu'     ...
		,'CallBack', 'matchmeas(''line1'')'      ...
		,'String',addstr(ne1,' ')	...
		,'Value',size(ne1,1)+1	...
		,'Tag','kanaal1'	...
		);
	psel2=uicontrol('Position', [b1+40 h-25+yoffset 120 20]   ...
		,'Style','popupmenu'     ...
		,'CallBack', 'matchmeas(''line2'')'      ...
		,'String',addstr(ne2,' ')	...
		,'Value',size(ne2,1)+1	...
		,'Tag','kanaal2'	...
		);
	ax1=axes('units','pixels','position',[10 h1+20+yoffset b1-20 h1-50]	...
		,'xtick',[],'ytick',[],'box','on');
	line(1:size(e1,1),zeros(size(e1,1),1),'Tag','line1');
	line([0 0],[0 0],'color',[0 0 0],'linestyle',':','Tag','x0_1')
	ax2=axes('units','pixels','position',[b1+10 h1+20+yoffset b1-20 h1-50]	...
		,'xtick',[],'ytick',[],'box','on');
	line(1:size(e2,1),zeros(size(e2,1),1),'Tag','line2');
	line([0 0],[0 0],'color',[0 0 0],'linestyle',':','Tag','x0_2')
	hZoek=uicontrol('Position',[30 h1-15+yoffset 120 30],'String','Zoek'	...
		,'CallBack','matchmeas(''match'')'	...
		);
	hT1=uicontrol('Style','text','String','tijdverschuiving'	...
		,'position',[200 h1+yoffset 80 15]);
	hOffset=uicontrol('Style','edit','String','0'	...
		,'position',[285 h1-1+yoffset 100 18]	...
		,'Tag','offset');
	hT2=uicontrol('Style','text','String','tijdsfactor'	...
		,'position',[200 h1-20+yoffset 80 15]);
	hTeken=uicontrol('Position',[400 h1-15+yoffset 120 30],'String','Teken'	...
		,'CallBack','matchmeas(''plot'')'	...
		);
	ax3=axes('units','pixels','position',[10 10+yoffset p(3)-20 h1-40]	...
		,'xtick',[],'ytick',[],'box','on');
	line(1:size(e1,1),zeros(size(e1,1),1),'Tag','refline');
	line(1:size(e2,1),zeros(size(e2,1),1),'Tag','shiftline','linestyle',':');
	set([psel1 psel2 ax1 ax2 ax3 hZoek hT1 hOffset hT2 hTeken],'Units','normalized')
	set(f,'UserData',struct('e1',e1,'e2',e2,'ne1',ne1,'ne2',ne2));
	zoom
	if nargout
		out=f;
	end
elseif ischar(e1)
	switch e1
	case 'line1'
		i=get(findobj(f,'Type','uicontrol','Tag','kanaal1'),'Value');
		h=findobj(f,'Type','line','Tag','line1');
		X=get(f,'UserData');
		set(h,'YData',X.e1(:,i));
		h=findobj(f,'Type','line','Tag','x0_1');
		set(h,'YData',[min(X.e1(:,i)),max(X.e1(:,i))])
	case 'line2'
		i=get(findobj(f,'Type','uicontrol','Tag','kanaal2'),'Value');
		h=findobj(f,'Type','line','Tag','line2');
		X=get(f,'UserData');
		set(h,'YData',X.e2(:,i));
		h=findobj(f,'Type','line','Tag','x0_2');
		set(h,'YData',[min(X.e2(:,i)),max(X.e2(:,i))])
	case 'match'
		h1=findobj(f,'Type','line','Tag','line1');
		a1=get(h1,'Parent');
		h2=findobj(f,'Type','line','Tag','line2');
		a2=get(h2,'Parent');
		xl1=get(a1,'XLim');
		yl1=get(a1,'YLim');
		xl2=get(a2,'XLim');
		yl2=get(a2,'YLim');
		yl=[max(yl1(1),yl2(1)) min(yl1(2),yl2(2))];
		if yl(1)>=yl(2)
			error('Geen overlappende gebieden (in Y-richting)')
		end
		x1=get(h1,'XData');
		y1=get(h1,'YData');
		x2=get(h2,'XData');
		y2=get(h2,'YData');
		i1=find(x1>=xl1(1)&x1<=xl1(2)&y1>=yl(1)&y1<=yl(2));
		i2=find(x2>=xl2(1)&x2<=xl2(2)&y2>=yl(1)&y2<=yl(2));
		if isempty(i1)|isempty(i2)
			error('Geen gemeenschappelijke punten gevonden')
		end
		p1=polyfit(x1(i1),y1(i1),1);
		p2=polyfit(x2(i2),y2(i2),1);
		if p1(1)==0|p2(1)==0
			error('!!!???konstante lijn??')
		end
		if p1(1)*p2(1)<0
			error('Kan geen gelijkenis tussen twee lijnen vinden')
		end
		if abs(1-p1(1)/p2(1))>0.2
			warning('Gelijkenis is niet erg betrouwbaar')
		end
		y0=mean([mean(y1(i1)),mean(y2(i2))]);
		x0_1=(y0-p1(2))/p1(1);
		x0_2=(y0-p2(2))/p2(1);
		if x0_1<xl1(1)|x0_1>xl1(2)|x0_2<xl2(1)|x0_2>xl2(2)
			error('Gelijk punt valt buiten grenzen.  M.a.w. geen betrouwbare gelijkenis gevonden!!')
		end
		set(findobj(f,'Type','uicontrol','Tag','offset'),'String',num2str(x0_2-x0_1));
		h=findobj(f,'Type','line','Tag','x0_1');
		set(h,'XData',[x0_1 x0_1])
		h=findobj(f,'Type','line','Tag','x0_2');
		set(h,'XData',[x0_2 x0_2])
		
		matchmeas plot
	case 'plot'
		i=get(findobj(f,'Type','uicontrol','Tag','kanaal1'),'Value');
		h=findobj(f,'Type','line','Tag','refline');
		X=get(f,'UserData');
		set(h,'YData',X.e1(:,i));
		i=get(findobj(f,'Type','uicontrol','Tag','kanaal2'),'Value');
		h=findobj(f,'Type','line','Tag','shiftline');
		X=get(f,'UserData');
		off=str2num(get(findobj(f,'Type','uicontrol','Tag','offset'),'String'));
		set(h,'XData',(1:size(X.e2,1))-off,'YData',X.e2(:,i));
	case 'getoffset'
		out=str2num(get(findobj(f,'Type','uicontrol','Tag','offset'),'String'));
	case 'getfig'
		out=f;
	end
end
