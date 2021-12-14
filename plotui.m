function [uit,scale]=plotui(varargin)
% PLOTUI   - UI om data af te lezen van grafiek in pixel-formaat
%   plotui('naam') : plot grafische file (start werking op)
%               met 'naam' de naam van de file om te lezen
%         of plotui(X) - met X de bitmap data
%     Het is nu mogelijk om lijnen in de grafiek te maken door de
%     opeenvolgende punten aan te klikken.  De eerste 10 lijnen hebben
%     nummers 0 tot 9.  Functie-toetsen of gebruik van commando's kunnen
%     hogere lijnnummers selecteren.
%     Lijn 0 is een lijn die gebruikt kan worden om de schaal aan
%     te duiden.  Hiervoor moet de lijn uit minstens drie punten
%     bestaan.  Het eerste punt moet de oorsprong zijn.  (Er is
%     niet voorzien dat de grafiek de oorsprong (het punt (0,0))
%     niet bevat.)  Het tweede punt moet dan een punt (x,0) zijn,
%     en het derde het punt (x,y).  Door dan 's' te drukken, kunt
%     u de waarden voor x en y opgeven.
%     Het nummer van de "actieve lijn" wordt onderaan links
%     aangegeven.
%     Ondertussen hebben de volgende toetsen de volgende betekenis :
%         i, I : inzoomen
%         o, O : uitzoomen
%         l, L : links
%         r, R : rechts
%         u, U : naar boven
%         d, D : naar onder
%         x    : volledig uitzoomen
%         0:9 : selecteren lijn (lijn 0 is voorzien als "schaal-box"
%               f1-f12 extensies: f1:lijn 10, f2: lijn 11, ...
%         n    : volgende (next)
%         N    : volgende met evt bijmaken van lijn
%         p    : vorige (previous)
%         s : schaal
%         S : save
%         G : (Get) leest gegevens ('l','o' waren al "bezet")
%            zet data in PUIdata
%         c : clear lijn
%         C : clear alles
%         h : geeft help-info
%         backspace : verwijdert laatste punt
%         t : follow lines through colour points of last selected point
%         z : scroll naar juiste gebied
%
%    D=plotui;   - geeft de beschikbare lijnen - ongeveer zelfde als 'G',
%        alleen hier enkel geschaalde in een cell array, terwijl met 'G'
%        wordt een struct gegeven met alle beschikbare data.
%    plotui('set',<nr>,<X>,<Y>)
%        zet lijn (in img-coordinaten)
%    plotui('line',<nr>)
%        Selecteert een lijn ('lijn' kan ook gebruikt worden)
%    [X,map]=plotui('getx'[,figHandle])
%        Geeft image
%    plotui plot
%        Plot image (in niet-plotui-venster) met schaal

plotCMDs={'convert','topix','getconvfcn'	...
	,'set','get','put','lijn','line','getx'	...
	,'plot','figName'};
if nargin==0
	f=getfigure;
	if isempty(f)
		error('Geen data gevonden')
	end
	uit={};
	ud=get(f,'UserData');
	sch=getappdata(f,'schaal');
	for i=2:length(ud)
		x=get(ud(i),'Xdata');
		if ~isempty(x)
			y=get(ud(i),'YData');
			if isempty(sch)
				uit{end+1}=[x' y']; %#ok<AGROW>
			else
				pt=grafpt([x' y'],sch);
				uit{end+1}=pt; %#ok<AGROW>
			end
		end
	end
	if nargout>1
		scale=sch;
	end
	return
elseif isstruct(varargin{1})
	uit=grafpt(varargin{2},varargin{1});
	return
elseif ischar(varargin{1})&&any(strcmpi(varargin{1},plotCMDs))
	f=getfigure;
	if isempty(f)
		error('Can''t find a plotui-figure for getting the scale')
	end
	switch lower(varargin{1})
		case 'convert'
			sch=getappdata(f,'schaal');
			uit=grafpt(varargin{2},sch);
		case 'topix'	% convert to pixel scaling
			sch=getappdata(f,'schaal');
			uit=calcpixcoor(varargin{2},sch);
		case 'getconvfcn'
			sch=getappdata(f,'schaal');
			[uit,scale] = GetConversionFcns(sch);
		case 'set'
			ud=get(f,'UserData');
			nr=varargin{2};
			bNew=false;
			if nr+2>length(ud)
				ud(nr+2)=line(varargin{3},varargin{4},'Marker','x'	...
					,'Color',[0 0 1],'HitTest','off','PickableParts','none');
				bNew=true;
			else
				set(ud(nr+2),'XData',varargin{3},'YData',varargin{4})
			end
			%?update info
			if bNew
				set(f,'UserData',ud)
			end
		case 'get'
			uit=GetData(f);
		case 'put'
			ud = varargin{2};
			[bOnlyScale] = false;
			if nargin>2
				setoptions({'bOnlyScale'},varargin{3:end})
			end
			if bOnlyScale
				for i=2:length(ud.L)
					ud.L(i).x = [];
					ud.L(i).y = [];
				end
			end
			PutData(f,ud)
		case {'lijn','line'}
			if ischar(varargin{2})
				nc=str2double(varargin{2});
				if isempty(nc)||nc<0
					error('Bad line selection')
				end
			elseif ~isnumeric(varargin{2})||~isscalar(varargin{2})
				error('Bad type of line selection')
			else
				nc=varargin{2};
				if nc<0
					error('Bad line selection')
				end
			end
			UpdateLineInfo(f,nc)
		case 'getx'
			if nargin>1
				f1=varargin{2};
				if ~isempty(f1)&&f1>0
					f=f1;
				end
			end
			h=findobj(f,'Type','image');
			uit=get(h,'CData');
			if nargout>1
				scale=get(f,'colormap');
			end
		case 'figname'
			uit=getappdata(f,'figName');
		case 'plot'
			[X,map]=plotui('getx',0);
			fPlot=gcf;
			if fPlot==f
				nfigure;
			end
			sX=size(X);
			if any(sX<2)
				error('Only "real images" (#rows,#columns > 1)!')
			end
			S=getappdata(f,'schaal');
			%!!!!!!!!!!!!!!!!!!!!!!!!!not yet exact!!!!!!!!!!!!!
			px=[ S.X(1)/S.x0(2) 0];px(2)=S.X(2)-S.x0(1)*px(1);
			py=[-S.Y(1)/S.y0(2) 0];py(2)=S.Y(2)-S.y0(1)*py(1);
			xx=polyval(px,[0.5 sX(2)+0.5]);
			yy=polyval(py,[0.5 sX(1)+0.5]);
			image(xx,yy,X);
			colormap(map);
			axis xy
		otherwise
			error('Wrong use of this function - unknown command')
	end
	return
else
	if ischar(varargin{1})||(isnumeric(varargin{1})&&min(size(varargin{1}))>1)
		if ischar(varargin{1})
			fName=varargin{1};
			[x,map]=imread(fName);
		else
			fName=[];
			x=varargin{1};
			if nargin>1
				map=varargin{2};
			else
				map=[];
			end
		end
		f=findobj('Tag','plotui-figure');
		if isempty(f)
			f=nfigure('Tag','plotui-figure','name','PLOTUI');
		else
			figure(f)
		end
		setappdata(f,'figName',fName)
		if isempty(map)
			a=imagesc(x);
		else
			a=image(x);
			colormap(map)
		end
		set(gca,'XTick',[],'YTick',[])
		set(a,'ButtonDownFcn','plotui(2)','Tag','plotUIimage')
		ud=uicontrol('Style','text','Position',[0 0 100 15]	...
			,'String','0 - #0','horizontalal','left');
		setappdata(f,'lijn',0);
		setappdata(f,'schaal',[]);
		ud(11)=0;	% verleng
		for i=2:11	% (lijn-nrs 0:9, ud(1)=uicontrol, ud(2)=handle lijn 0, ...)
			ud(i)=line('Marker','x','Color',[0 0 1],'HitTest','off','PickableParts','none');
			set(ud(i),'XData',[],'YData',[])	% what does this do?
		end
		set(ud(2),'Color',[1 0 0])
		set(f,'KeyPressFcn','plotui(1)','Pointer','crosshair','UserData',ud)
		set(ud,'HitTest','off')
		set(gca,'DrawMode','fast')
		%warndlg('Dit programmatje is gemaakt zonder veel testen, en werkt dan ook alleen "als alles goed gebeurt".  Raadpleeg Stijn voor het gebruik hiervan.','plotui-waarschuwing')
	else
		switch varargin{1}
		case 1	% Keypress
			c=get(gcf,'CurrentCharacter');
			if isempty(c)
				k=get(gcf,'CurrentKey');
				switch k
				case 'pageup'
					c='U';
				case 'pagedown'
					c='D';
				case {'f1','f2','f3','f4','f5','f6','f7','f8','f9','f10','f11','f12'}
					nc=str2double(k(2:end))+9;
					UpdateLineInfo(gcf,nc)
					return
				case {'insert','home','end','alt'}
					return
				case {'shift','control','windows','applications'}
					return
				end
			end
			xl=get(gca,'XLim');
			yl=get(gca,'YLim');
			dx=diff(xl);
			dy=diff(yl);
			x0=mean(xl);
			y0=mean(yl);
			ch=0;
			switch c
			case 'i'
				xl=[xl(1)+dx/4 xl(2)-dx/4];
				yl=[yl(1)+dy/4 yl(2)-dy/4];
				ch=1;
			case 'I'
				xl=[xl(1)+dx/20 xl(2)-dx/20];
				yl=[yl(1)+dy/20 yl(2)-dy/20];
				ch=1;
			case 'o'
				xl=[x0-dx x0+dx];
				yl=[y0-dy y0+dy];
				ch=1;
			case 'O'
				xl=[xl(1)-dx/18 xl(2)+dx/18];
				yl=[yl(1)-dy/18 yl(2)+dy/18];
				ch=1;
			case 'l'
				xl=xl-dx/2;
				ch=1;
			case char(28)	% leftarrow
				xl=xl-dx/10;
				ch=1;
			case 'L'
				xl=xl-dx;
				ch=1;
			case 'r'
				xl=xl+dx/2;
				ch=1;
			case char(29)	% rightarrow
				xl=xl+dx/10;
				ch=1;
			case 'R'
				xl=xl+dx;
				ch=1;
			case 'u'
				yl=yl-dy/2;
				ch=1;
			case char(30)	% uparrow
				yl=yl-dy/10;
				ch=1;
			case 'U'
				yl=yl-dy;
				ch=1;
			case 'd'
				yl=yl+dy/2;
				ch=1;
			case char(31)
				yl=yl+dy/10;
				ch=1;
			case 'D'
				yl=yl+dy;
				ch=1;
			case 'x'
				h=findobj(gca,'type','image');
				xl=get(h,'XData');
				yl=get(h,'ydata');
				xl=[xl(1)-0.5 xl(end)+0.5];
				yl=[yl(1)-0.5 yl(end)+0.5];
				ch=1;
			case {'0','1','2','3','4','5','6','7','8','9'}
				nc=str2double(c);
				UpdateLineInfo(gcf,nc)
			case 'n'
				nc=getappdata(gcf,'lijn')+1;
				ud=get(gcf,'UserData');
				if nc+2>length(ud)
					nc=0;
				end
				UpdateLineInfo(gcf,nc)
			case 'N'
				nc=getappdata(gcf,'lijn')+1;
				ud=get(gcf,'UserData');
				if nc+2>length(ud)
					ud(nc+2)=line('Marker','x','HitTest','off','PickableParts','none');
					set(ud(nc+2),'XData',[],'YData',[])
					set(gcf,'UserData',ud);
				end
				UpdateLineInfo(gcf,nc)
			case 'p'
				nc=getappdata(gcf,'lijn')-1;
				ud=get(gcf,'UserData');
				if nc<0
					nc=length(ud)-2;
				end
				UpdateLineInfo(gcf,nc)
			case 's'	% schaal
				% testen of "schaallijn" (lijn0) beschikbaar is
				if isempty(getschaallijn(gcf))
					return
				end
				sch=getappdata(gcf,'schaal');
				if isempty(sch)
					xtekst='';
					ytekst='';
					sx0='0';
					sy0='0';
				else
					xtekst=sprintf('%g',sch.X(1));
					ytekst=sprintf('%g',sch.Y(1));
					sx0=sprintf('%g',sch.X(2));
					sy0=sprintf('%g',sch.Y(2));
				end
				f0=gcf;
				f=nfigure;
				p0=get(f0,'Position');
				set(f	...
					,'Position',[p0(1)+10 p0(2)+p0(4)-90-25 256 95]	...
					,'UserData',f0	...
					,'NumberTitle','off'	...
					,'Name','plotui-schaal'	...
				)
				uicontrol('Style','text','Position',[10,72,30,17],'String','x')
				uicontrol('Style','edit','Position',[40 70 100 20],'HorizontalAlignment','left','Tag','x','String',xtekst)
				uicontrol('Style','edit','Position',[150 70 100 20],'HorizontalAlignment','left','Tag','x0','String',sx0)
				uicontrol('Style','text','Position',[10,42,30,17],'String','y')
				uicontrol('Style','edit','Position',[40 40 100 20],'HorizontalAlignment','left','Tag','y','String',ytekst)
				uicontrol('Style','edit','Position',[150 40 100 20],'HorizontalAlignment','left','Tag','y0','String',sy0)
				uicontrol('Style','pushbutton','Position',[10 10 120 21],'String','Stel in','Callback','plotui(3)')
			case 'S'	% save
				ud=get(gcf,'UserData');
				sch=getappdata(gcf,'schaal');
				fid=fopen('plotuid.txt','wt');
				if ~isempty(sch)
					fprintf(fid,'schaal');
					fprintf(fid,' %g',sch.X(1),sch.Y(1),sch.x0,sch.y0,sch.X(2),sch.Y(2));
					fprintf(fid,'\n');
				end
				for i=2:length(ud)
					x=get(ud(i),'XData');
					y=get(ud(i),'YData');
					if ~isempty(x)
						fprintf(fid,'lijn %d\n',i-2);
						fprintf(fid,'%d\n',length(x));
						if isempty(sch)
							fprintf(fid,'%6.1f  %6.1f\n',[x;y]);
						else
							pt=grafpt([x' y'],sch);
							fprintf(fid,'%6.1f  %6.1f    - %10g %10g\n',[x;y;pt']);
						end
					end
				end
				fclose(fid);
			case 'G'	% get (load)
				D=GetData(gcf);
				assignin('base','PUIdata',D)
				fprintf('Lijndata in variabele "PUIdata" gestoken\n')
			case 'c'	% clear lijn
				ud=get(gcf,'UserData');
				lnr=getappdata(gcf,'lijn');
				set(ud(lnr+2),'EraseMode','normal');
				set(ud(lnr+2),'XData',[],'YData',[]);
				set(ud(lnr+2),'EraseMode','none');
				UpdateLineInfo1(ud,lnr)
			case 'C'	% clear alles
				ud=get(gcf,'UserData');
				set(ud(2:end),'EraseMode','normal');
				set(ud(2:end),'XData',[],'YData',[]);
				set(ud(2:end),'EraseMode','none');
				lnr=getappdata(gcf,'lijn');
				UpdateLineInfo1(ud,lnr)
			case 'h'
				helpwin plotui
			case char(8)
				ud=get(gcf,'UserData');
				lnr=getappdata(gcf,'lijn');
				l=ud(lnr+2);
				x=get(l,'XData');
				y=get(l,'YData');
				if ~isempty(x)
					x(end)=[];
					y(end)=[];
					set(l,'EraseMode','normal');
					set(l,'XData',x,'YData',y)
					set(l,'EraseMode','none');
					UpdateLineInfo1(ud,lnr)
				end
			case 't'
				try
					status('Searching lines through graph')
					ud=get(gcf,'UserData');
					lnr=getappdata(gcf,'lijn');
					l=ud(lnr+2);
					x=get(l,'XData');
					if isempty(x)
						error('A point must be selected!')
					end
					y=get(l,'YData');
					L = runthroughgraph([],round([x(end) y(end)])	...
						,'ball',-3,'--bScale');
					status
					if ~isempty(L)
						% do something with data?
						set(l,'EraseMode','normal');
						set(l,'XData',L(:,1),'YData',L(:,2))
						set(l,'EraseMode','none');
						UpdateLineInfo1(ud,lnr)
						assignin('base','Lplotui',L)
						disp('RunThoughGraph done - result put in Lplotui')
						%msgbox('RunThoughGraph done - result put in Lplotui','plotui-runthroughgraph-message')
					end
				catch err
					status
					sErr=sprintf('error (%s) while finding lines in a graph (%s - #%d)'	...
						,err.message,err.stack(1).file,err.stack(1).line);
					DispErr(err,sErr)
					errordlg(sErr)
					return
				end
			case char(127)	% delete
				startButNotContinued = true;
			case 'z'
				ud=get(gcf,'UserData');
				lnr=getappdata(gcf,'lijn');
				l=ud(lnr+2);
				x=get(l,'XData');
				if ~isempty(x)
					x=mean(x);
					y=mean(get(l,'YData'));
					xl=[x-dx/2 x+dx/2];
					yl=[y-dy/2 y+dy/2];
					ch=1;
				end
			end
			if ch
				set(gca,'XLim',xl,'YLim',yl)
			end
		case 2	% ButtonDown
			ud=get(gcf,'UserData');
			pt=get(gca,'CurrentPoint');
			pt=pt(1,1:2);
			switch get(gcf,'selectiontype')
			case 'normal'
				lnr=getappdata(gcf,'lijn');
				l=ud(lnr+2);
				x=get(l,'XData');
				y=get(l,'YData');
				x(end+1)=pt(1);
				y(end+1)=pt(2);
				set(l,'XData',x,'YData',y)
				UpdateLineInfo1(ud,lnr)
			case 'alt'	% right click
				sch=getappdata(gcf,'schaal');
				if isempty(sch)
					fprintf('%1.1f,%1.1f\n',pt);
				else
					ptn=grafpt(pt,sch);
					fprintf('%1.1f,%1.1f  -  %g,%g\n',pt,ptn);
				end
			case 'open'	% double click
			case 'extend'	% shift click
			end
		case 3	% schaal
			fS=gcf;
			tX=findobj(fS,'Tag','x');
			sX=get(tX,'String');
			tY=findobj(fS,'Tag','y');
			sY=get(tY,'String');
			tX0=findobj(fS,'Tag','x0');
			sX0=get(tX0,'String');
			tY0=findobj(fS,'Tag','y0');
			sY0=get(tY0,'String');
			f=get(fS,'UserData');
			close(fS);
			sch=getschaallijn(f,str2double(sX),str2double(sY),str2double(sX0),str2double(sY0));
			if isempty(sch)
				return
			end
			figure(f);
			setappdata(gcf,'schaal',sch);
		end
	end
end

function ptconv=grafpt(pt,sch)
% PTCONV - Zet punt (in pixel-coordinaten) om in grafiek-punt
if ~exist('sch','var')
	sch=getappdata(gcf,'schaal');
end
if isempty(sch)
	sch=struct('Atran',eye(2),'x0',[0 1],'y0',[0 1],'X',[1 0],'Y',[1 0]);
end
ptconv=(sch.Atran*[pt(:,1)'-sch.x0(1);sch.y0(1)-pt(:,2)'].*[sch.X(1)/sch.x0(2);sch.Y(1)/sch.y0(2)])';

function pt=calcpixcoor(ptScaled,sch)
if isempty(sch)
	sch=struct('Atran',eye(2),'x0',[0 1],'y0',[0 1],'X',[1 0],'Y',[1 0]);
end
pt = (ptScaled./[sch.X(1)/sch.x0(2),-sch.Y(1)/sch.y0(2)]) * sch.Atran'	...
	+ [sch.x0(1),sch.y0(1)];

function [f_C2Z,f_Z2C] = GetConversionFcns(sch)
if isempty(sch)
	sch=struct('Atran',eye(2),'x0',[0 1],'y0',[0 1],'X',[1 0],'Y',[1 0]);
end
f_C2Z = @(pt) (sch.Atran*[pt(:,1)'-sch.x0(1);sch.y0(1)-pt(:,2)'].*[sch.X(1)/sch.x0(2);sch.Y(1)/sch.y0(2)])';
f_Z2C = @(ptScaled) (ptScaled./[sch.X(1)/sch.x0(2),-sch.Y(1)/sch.y0(2)]) * sch.Atran'	...
	+ [sch.x0(1),sch.y0(1)];

function sch=getschaallijn(f,X,Y,X0,Y0)
% GETSCHAALLIJN - Bepaalt schalen op basis van lijn 0
ud=get(f,'UserData');
sch=[];
if isempty(f)
	errordlg('Verkeerde figuur...','plotui-error')
	return;
end
if ~exist('X','var')
	sch=1;
	return
end
x0=get(ud(2),'XData');
y0=get(ud(2),'YData');
if length(x0)<3
	errordlg('Minstens 3 punten ingeven voor schaal!','plotui-error')
	return
end

if length(x0)==4&&abs(x0(3)-x0(1))+abs(y0(3)-y0(1))<6
	% not (x0,y0)->(x1,y0)->(x1,y1)
	%     but (x0,y0)->(x1,y0)->(x0,y0)->(x0,y1)
	x0=x0([1 2 2]);
	y0=y0([1 2 4]);
end

[t1,r1]=cart2pol(x0(2)-x0(1),y0(1)-y0(2));
[t2,r2]=cart2pol(x0(3)-x0(2),y0(2)-y0(3));
if length(x0)>3
	[t3,r3]=cart2pol(x0(3)-x0(4),y0(4)-y0(3));
	[t4,r4]=cart2pol(x0(4)-x0(1),y0(1)-y0(4));
	fprintf('Kontrole : X %4.0f,%4.0f (%4.2f%%) , Y %4.0f,%4.0f (%4.2f%%)\n'	...
		,r1,r3,abs(r1-r3)*2/(r1+r3)*100	...
		,r2,r4,abs(r2-r4)*2/(r2+r4)*100)
	fprintf('           X %5.2f� %5.2f�     , Y %5.2f� %5.2f�\n'	...
		,[t1,t3,t2,t4]/pi*180)
end
delta=t2-pi/2-t1;

x0=[x0(1) r1];
y0=[y0(1) r2];
hoeken=[t1 t2 delta];

sch=struct('X',[X X0],'Y',[Y Y0],'x0',x0,'y0',y0,'hoeken',hoeken	...
	,'Atran',[cos(t1) sin(t1);-sin(t1) cos(t1)]);

function f=getfigure
if isempty(findobj('type','figure'))
	warning('PLOTUI:noFig','no plotui-figure found (not any figure found)')
	f=[];
	return
end
if strcmp(get(gcf,'tag'),'plotui-figure')
	f=gcf;
else
	f=findobj('Tag','plotui-figure');
	if isempty(f)
		warning('PLOTUI:noPLOTUIfig','no plotui-figure found')
	elseif length(f)>1
		f=f(1);
		warning('PLOTUI:multiPLOTUIfigs','Multiple plotui-figures found (without having one as current figure)! just one is taken (%d)!',f)
	end
end

function UpdateLineInfo(f,nc)
ud=get(f,'UserData');
if nc+2>length(ud)
	ndOld=length(ud);
	ud(nc+2)=0;	% verleng
	for i=ndOld+1:nc+2
		ud(i)=line('Marker','x','Color',[0 0 1],'HitTest','off','PickableParts','none');
		set(ud(i),'XData',[],'YData',[])
	end
	set(f,'UserData',ud);
end
set(ud(getappdata(f,'lijn')+2),'Color',[0 0 1])
set(ud(nc+2),'Color',[1 0 0])
setappdata(f,'lijn',nc);
UpdateLineInfo1(ud,nc)

function UpdateLineInfo1(ud,nc)
set(ud(1),'String',sprintf('%d - #%d',nc,length(get(ud(nc+2),'XData'))))

function D=GetData(f)
ud=get(f,'UserData');
sch=getappdata(f,'schaal');
L=struct('x',cell(1,length(ud)-1),'y',[],'xs',[],'ys',[],'XY',[]);
bLok=false(1,length(L));
for i=2:length(ud)
	x=get(ud(i),'XData');
	y=get(ud(i),'YData');
	if ~isempty(x)
		bLok(i-1)=true;
		L(i-1).x=x(:);
		L(i-1).y=y(:);
		if isempty(sch)
			L(i-1).XY=[x' y'];
		else
			pt=grafpt([x' y'],sch);
			L(i-1).xs=pt(:,1);
			L(i-1).ys=pt(:,2);
			L(i-1).XY=[x' y' pt];
		end
	end
end
D=struct('L',L(bLok),'schaal',sch);

function PutData(f,UIdata)
sch = UIdata.schaal;
L = UIdata.L;
ud=get(f,'UserData');
for i=1:length(L)
	set(ud(i+1),'XData',L(i).x,'YData',L(i).y)
end
setappdata(f,'schaal',sch)
