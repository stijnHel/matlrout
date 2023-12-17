function varargout=navfig(c,x2,varargin)
% NAVFIG   - functie die het navigeren in grafieken van een figuur toelaat.
%   navfig - stelt "navfig" in voor de huidige figuur
%   navfig('volg',figuren) : geeft aan dat andere figuren moeten meevolgen
%   navfig('link',figuren) : gelijkaardig aan bovenstaande, alleen wordt ook de navigatie
%                            voor deze figuren zelf ingesteld
%               (navfig('link') "linkt" alle figuren)
%       navfig(figuren) is shortcut for navfig('link',figuren)
%   navfig mouse : start volgen van muis (gegevens opvragen langs x, d)
%   navfig nlink : stopt link
%   navfig relink : behoudt links van figuren die nog bestaan
%                    (volgorde kan wijzigen)
%   navfig('addlink',<f>) : adds <f> to linked figures (of current figure)
%   navfig('assen',<assen>) : beperkt navfig tot een aantal assen
%               navfig assen all : laat alle assen terug "meedoen"
%   navfig('savept'[,<var-name>]) - Saves selected points (default NFlog')
%   navfig('clearpt') - clear saved points
%   navfig('stopsave')
%   [X,I]=navfig('getLog') - returns the log of points
%   navfig off   : switches navigation functionallity off
%   navfig('updateAxes',fcn)  - runs "fcn" after updating axes
%           (extra fcn-arguments are possible via updateAxesArgs axes appdata)
%   navfig updateAxesT switches "X-time-display" on
%
% Press "H" (from "navfig-enabled window") to get a list of key-codes.
%
% De werking van navfig kan "gepersonaliseerd" worden met behulp van
%   figure-appdata :
%             NAVFIGkey-data :
%                   {<key>,<doebepfig>,<wattedoen>;...}
%                <key> : letter
%                <doebepfig> : als 0 wordt enkel functie in <wattedoen>
%                                  opgeroepen
%                          als 1 hangt het gedrag af van <wattedoen>
%                <wattedoen> : functie : [doebepfig,x]=wattedoen
%                     of cell : {<doebepfig>,[xmin xmax]} : rechtstreeks
%                                  "bepfig" (???wat vreemd dat doebepfig
%                                          nog gegeven moet worden???)
%    bijv.
%       setappdata(<f>,'NAVFIGkey',{'2',0,'bepfig(0,1)';	...
%                                   '3',1,{<b_bepfig>,[xmin xmax]};	...
%                                   '4',1,'<fcn>'})
%       geeft uitvoeringen voor '2', '3', '4'
%             met '2' wordt enkel een functie opgeroepen
%             met '3' wordt aangegeven of de figuur beperkt moet worden
%                       met b_bepfig, en wordt het minimum en maximum gegeven
%                       (op deze manier worden gelinkte figuren mee aangepast)
%             met '4' wordt een functie opgeroepen om b_bepfig en [xmin en xmax]
%                       te bepalen.
%       Deze data wordt gelezen voor het testen van normale codes
%         waardoor codes "overruled" kunnen worden.
%   Deze data kan gezet en toegevoegd worden door :
%        navfig('keys',<key-data>)
%     of
%        navfig('addkey',<key-data>)
%     of
%        navfig('addkey',<key>,<0/1>,<wat-te-doen>)
%     Bij toevoegen van 'key' worden oude versies ervan vervangen als deze
%         reeds bestaan.
%     navfig addkey <key> zorgt dat deze gelinkt worden aan de huidige grenzen
%     Als figuren gelinkt zijn, krijgen deze figuren ook deze extra data.
%        navfig addkey1 doet hetzelfde, maar dan enkel voor de huidige figuur.
%   navfig verwkey <key> verwijdert de key
%        navfig 'rmkey','verwkey1','rmkey1' doen hetzelfde waarbij ..1
%         enkel voor de huidige figuur.
%   navfig keylist    geeft lijst van geinstalleerde "keys"

% gekende problemen:
%   bij 'x' of 'd' --> enkel waarden gegeven van lijnen "rond" de x-waarde,
%        niet buiten (onderandere voor vermijden van moeilijkheden met
%        korte streepjes)
%        bij 'd' geeft dit problemen als aantallen wisselen

% toetsen-betekenissen :
%    'l' : scroll naar links (halve pagina)
%    'L' : scroll naar links (hele pagina)
%    'r' : scroll naar rechts (halve pagina)
%    'R' : scroll naar rechts (hele pagina)
%    <pijl links/rechts> : scroll 1/50 pagina
%    'H' : give help window
%    's' : scroll naar begin (start)
%    'e' : scroll naar einde
%    'M' : scroll naar midden
%    'i' : zoom in (x 2)
%    'I' : zoom in fijn (+5%)
%    'u' : zoom uit (/ 2)
%    'U' : zoom uit fijn (-5%)
%    '#' : "equalise" assen (allen zelfde hor. schaal)
%    '!' : stop tijdelijk link
%    '&' : toggle relatieve link
%    'S' : vast punt bij zoom is linkse punt
%    '|' : vast punt bij zoom is middelste punt
%    'E' : vast punt bij zoom is rechtse punt
%    'X' : geeft volledige grafiek
%    'P' : print (met dialoog-venster)
%    'c' : sluit venster (close)
%    'C' : sluit venster samen met de gelinkte vensters
%    'a' : zet "markers" (gebruikt functie addpunt)
%    'A' : verwijdert "markers"
%    'n' : geeft volgende venster (van gelinkte vensters)
%    'N' : geeft vorige venster
%    'g' : geeft grid (enkel van huidige as(!))
%    'b' : stelt "berhell(<figuur>,-0.01)" in
%    'B' : stelt "bertconst(<figuur>) in
%    'm' : stelt "navfig mouse" in
%    'x' : geeft inhoud van lijnen in huidige as op huidige positie
%    'd','D' : geeft verschil tussen laatste "'x'-gegevens" tov huidige positie
%    'y' : geeft huidige muis-positie op scherm
%    '^' : bepaal maximum en minimum van getoonde gedeelte
%    'Q' : toont specgram (een lijn per grafiek)
%    't','T','v','V' : sine fits :
%             't'/'T' : pure sine
%             'v'/'V' : sine with first order decrease of amplitude
%             uppercase ==> plot lines
%    'w' : delete lines plotted by sine fits
%    '=' : extend xlim to show focus to all visible points


%used :
%lLrRseMiIuUS|EXPcCaAnNgbBmxdDyF&!#^QtvTVw=

% b=zeros(1,255);
% b(abs('a'):abs('z'))=true;
% b(abs('A'):abs('Z'))=true;
% b(abs('`~!@#$%^&*()-_=+[]\{}|;:''",./<>?'))=true;
% b(abs('lLrRseMiIuUS|EXPcCaAnNgbBmxdDyF&!#^QtvTVw'))=false;
% disp(char(find(b)))
%   "$%'()*+,-./:;<=>?@GHJKOWYZ[\]_`fhjkopqz{}~

global NAVFIGsets NAVFIGlogs

IN=varargin;
ninput=nargin;

if nargin&&all(ishandle(c))
	bNavfigStart=nargin==1;
	f=c;
	if nargin>1
		c=x2;
		ninput=ninput-1;
		if ninput>1
			x2=IN{1};
			IN=IN(2:end);
		end
	end
else
	f=gcf;
	bNavfigStart=nargin==0;
end
if bNavfigStart
	set(f,'KeyPressFcn',@KeyPressed)
	return
end

if ischar(c)&&length(c)>1
	% Add here help-text to avoid "splitting data" (so that "help" can
	% directly use this info).
	NFcmds=lower({'volg','link','rlink','nlink','relink','addlink'	...
		,'assen','updateAxes','addUpdateAxes','updateAxesT'	...
		,'mouse','mdown','mmoved','mup','delui','navfigx','keys'	...
		,'addkey','addkey1','verwkey','rmkey','verwkey1','rmkey1'	...
		,'keylist','savept','clearpt','stopsave','resample','settings'	...
		,'help','longplot','getlinked','getPtFcn','getLog','getSlog','clearLog'	...
		,'off','update','set','??'});
	b=strcmpi(c,NFcmds);
	if ~any(b)
		b=strncmpi(c,NFcmds,length(c));
		if ~any(b)
			error('Unknown command for navfig')
		elseif sum(b)>1
			fprintf('         %s\n',NFcmds{b})
			error('Unclear command for navfig')
		end
		c=NFcmds{b};
	end
	switch lower(c)
		case 'volg'
			setlinked(f,x2)
		case {'link','rlink'}
			if ~exist('x2','var')||isempty(x2)
				x2=sort(findobj('Type','figure','Visible','on'));
			elseif ischar(x2)
				x2=str2num(x2); %#ok<ST2NM>
			end
			if strcmp(c,'rlink')
				rlink=1;
			else
				rlink=0;
			end
			for i=1:length(x2)
				if strcmp(get(x2(i),'Type'),'figure')
					fi=x2(i);
				elseif strcmp(get(x2(i),'Type'),'axes')
					fi=get(x2(i),'Parent');	%!!!!poging maar werkt niet!!!
				else
					error('Verkeerde input voor navfig link')
				end
				set(fi,'KeyPressFcn',@KeyPressed);
			end
			setlinked(x2,x2,rlink)
			return
		case 'getlinked'
			varargout={getlinked(f,1)};
		case 'nlink'
			setlinked(getlinked(f,1),[])
		case 'relink'
			fs=getlinked(f,1);
			if length(fs)==1
				setlinked(f,[]);
			else
				setlinked(f,fs);
			end
		case 'addlink'
			fLink=union(getlinked(f,1),x2);
			setlinked(fLink,fLink)
		case 'assen'
			if ischar(x2)
				if strcmpi(x2,'all')
					rmappdata(f,'NAVFIGas')
					as=get(f,'children');
					for i=1:length(as)
						if isappdata(as(i),'noNavfig')
							remappdata(as(i),'noNavfig')
						end
					end
				else
					error('Verkeerde input bij navfig assen')
				end
			else
				setappdata(f,'NAVFIGas',x2)
				asNoNavfig=setdiff(findobj(f,'Type','axes'),x2);
				for i=1:length(asNoNavfig)
					setappdata(asNoNavfig(i),'noNavfig',true)
				end
			end
		case 'updateaxest'
			navfig(f,'updateAxes',@axtick2date)
			if isempty(get(f,'SizeChangedFcn'))
				set(f,'SizeChangedFcn',@(f,~)axtick2date(f))
			end
		case {'updateaxes','addupdateaxes'}
			if ninput<2
				error('navfig(''updateAxes'') must have an update function as second argument!')
			end
			if isempty(get(f,'KeyPressFcn'))
				navfig(f)	% start navfig-functionality
			end
			bAdd = strcmpi(c,'addUpdateAxes');
			assen=GetNormalAxes(f);
			if ischar(x2)&&strcmpi(x2,'stop')
				x2=[];
				set(assen,'XTickMode','auto','XTickLabelMode','auto')
				set(f,'SizeChangedFcn',[])
			end
			if ischar(x2) && ~isempty(x2)
				x2 = str2func(x2);
			end
			for i=1:length(assen)
				if bAdd
					fcnUpd = getappdata(assen(i),'updateAxes');
					if isempty(fcnUpd)
						fcnUpd = x2;
					else
						if ~iscell(fcnUpd)
							fcnUpd = {fcnUpd};
						end
						fcnUpd{1,end+1} = x2; %#ok<AGROW>
					end
				else
					fcnUpd = x2;
				end
				setappdata(assen(i),'updateAxes',fcnUpd)
				if isempty(x2)
					% reset timeformat (assuming axtick2date!!)
					setappdata(assen(i),'TIMEFORMAT',[])
				end
			end
		case 'mouse'
			set(f,'WindowButtonDownFcn','navfig(''mdown'')'	...
				,'WindowButtonMotionFcn','navfig(''mmoved'')'	...
				,'WindowButtonUpFcn','navfig(''mup'')');
		case 'mdown'
			pm=get(f,'currentpoint');
			ui=getappdata(f,'navfigUI');
			styp=get(f,'SelectionType');
			switch styp
				case 'alt'
					if isempty(ui)
						ui=uicontrol('Position',[pm 100 15],'Style','text'	...
							...,'ToolTip','navfig-info : click om te sluiten'	...
							,'CallBack','navfig(''delui'')'	... werkt niet
							);
						setappdata(f,'navfigUI',ui)
					else
						pui=get(ui,'Position');
						pui(1:2)=pm;
						set(ui,'Position',pui)
					end
				case 'extend'
					delete(ui)
					rmappdata(f,'navfigUI')
					return
			end
		case 'mmoved'
		case 'mup'
		case 'delui'
			ui=getappdata(f,'navfigUI');
			if ~isempty(ui)
				delete(ui)
				rmappdata(f,'navfigUI');
			end
		case 'navfigx'
			ll=FindLines(gca);
			setappdata(f,'navfigX',get(ll(1),'XData'))
		case 'keys'
			if nargin==1
				varargout = {getappdata(f,'NAVFIGkey')};
				return
			end
			figs=getlinked(f,1);
			figs=[f;figs(:)];
			for f1=figs(:)'
				setappdata(f1,'NAVFIGkey',x2)
			end
		case {'addkey','addkey1'}
			if strcmpi(c,'addkey1')||(	...
					isstruct(NAVFIGsets)&&isfield(NAVFIGsets,'bLinkKeys')	...
					&&NAVFIGsets.bLinkKeys)
				figs=f;
			else
				figs=getlinked(f,1);
				figs=[f;figs(:)];
			end
			K=getappdata(f,'NAVFIGkey');
			if ninput==2&&ischar(x2)&&length(x2)==1
				x=get(gca,'xlim');
				x2={x2,1,{1,x}};
			end
			if ~isempty(K)	% als reeds bestaande keys toegevoegd worden
				% worden deze eerst verwijderd.
				if ~iscell(K)||size(K,2)~=3
					error('!!!Verkeerde NAVFIGkey-data!!!')
				end
				if ninput==2
					[~,a2,~]=intersect(K(:,1),x2(:,1));
					if ~isempty(a2)
						K(a2,:)=[];
					end
				else
					i=find(strcmp(x2,K(:,1)));
					if ~isempty(i)
						K(i,:)=[];
					end
				end
			end
			if ninput==2
				if isempty(K)
					K=x2;
				else
					K=vertcat(K,x2);
				end
			elseif ninput==4
				K=vertcat(K,{x2,IN{1},IN{2}});
			else
				error('Verkeerd aantal ingangen voor navfig addkey')
			end
			for f1=figs(:)'
				setappdata(f1,'NAVFIGkey',K)
			end
		case {'verwkey','rmkey','verwkey1','rmkey1'}
			if c(end)=='1'
				figs=f;
			else
				figs=getlinked(f,1);
				figs=[f;figs(:)];
			end
			if ninput==1
				for f1=figs(:)'
					if isappdata(f1,'NAVFIGkey')
						rmappdata(f1,'NAVFIGkey')
					end
				end
				return
			end
			K=getappdata(f,'NAVFIGkey');
			if ~isempty(K)	% als reeds bestaande keys toegevoegd worden
				% worden deze eerst verwijderd.
				if ~iscell(K)||size(K,2)~=3
					error('!!!Verkeerde NAVFIGkey-data!!!')
				end
				i=find(strcmp(x2,K(:,1)));
				if ~isempty(i)
					K(i,:)=[];
				end
			end
			for f1=figs(:)'
				setappdata(f1,'NAVFIGkey',K)
			end
		case 'keylist'
			K=getappdata(f,'NAVFIGkey');
			if isempty(K)
				if nargout
					varargout{1}=[];
				else
					fprintf('No keys assigned\n')
				end
			elseif nargout
				for i=1:size(K,1)
					c=K{i};
					if length(c)>1 || (c>='0'&&upper(c)<='Z')
						K{i,4} = c;
					elseif c==' '
						K{i,4} = ['''',c,''''];
					else
						K{i,4} = sprintf('<%d|0x%02x>',abs([c c]));
						if c>1&&c<=26
							K{i,4} = sprintf('%s(ctrl-%c)',K{i,4},char(c+64));
						end
					end
				end
				varargout{1}=K;
			else
				fprintf('Keys assigned: ');
				for i=1:size(K,1)
					c=K{i};
					if length(c)>1
						fprintf('"%s"',c)
					elseif c>='0'&&upper(c)<='Z'
						fprintf('''%c''',c)
					else
						fprintf('<%d|0x%02x>',abs([c c]))
						if c>1&&c<=26
							fprintf('(ctrl-%c)',char(c+64))
						end
					end
					if i<size(K,1)
						fprintf(', ')
					end
				end
				fprintf('\n')
			end
		case 'savept'
			if ninput>1
				varname=x2;
			else
				varname='NFlog';
			end
			setappdata(f,'NAVFIGlogname',varname)
			assignin('base',varname,[]);
		case 'clearpt'
			varname=getappdata(f,'NAVFIGlogname');
			if ~isempty(varname)
				assignin('base',varname,[]);
			end
		case 'stopsave'
			if isappdata(f,'NAVFIGlogname')
				rmappdata(f,'NAVFIGlogname')
			end
		case 'resample' % resamples sine fitted plot
			if ninput<2
				nResample=10;
			else
				nResample=x2;
			end
			setappdata(f,'NAVFIGresample',nResample);
		case 'getptfcn'
			if ninput<2
				getPtFcn=@DefPtSelFcn;
			else
				getPtFcn=x2;
			end
			setappdata(f,'NAVFIGgetPtFcn',getPtFcn);
		case 'settings'
			if ninput==1
				a={};
			else
				a=[{x2},IN];
			end
			if ~isstruct(NAVFIGsets)
				NAVFIGsets=struct(a{:});
			else
				NAVFIGsets=defSetFcn(NAVFIGsets,a{:});
			end
			if nargout
				varargout={NAVFIGsets};
			end
			return
		case 'set'
			NAVFIGsets.(x2)=IN{1};
		case 'getlog'
			varargout={NAVFIGlogs.pt,{'tPt','hFig','hAx','type','X','Y'}};
		case 'getslog'
			varargout={NAVFIGlogs.spt,{'tPt','hFig','X','Y'}};
		case 'clearlog'
			NAVFIGlogs=[];
		case {'help','??'}
			fprintf('possible navfig-commands:\n')
			NFcmds=sort(NFcmds);
			fprintf('         %s\n',NFcmds{:})
			fprintf('   More info can be found via "F1" key press in window.\n')
			return
		case 'longplot'
			%?started to implement a long plot but not finished (at all)?
				% possible goal: make it work faster by local storage of
				% data and use only shown (clipped/decimated) data to plot
			setappdata(f,'NAVFIGlongplot',true)
		case 'off'
			set(f,'KeyPressFcn',[])
		case 'update'	% update (care for linked axes, x-ticks, ...)
			KeyPressed(f,struct('Character',char(0),'Modifier',{'simul'},'Key',char(0)))
		otherwise
			error('Onbekende opdracht voor navfig')
	end
elseif ischar(c)&&isscalar(c)
	if nargin==1
		k = c;
	else
		if c==0
			c = [];
		end
		k = x2;
	end
	KeyPressed(f,struct('Character',c,'Modifier',{'simul'},'Key',k))
else
	error('verkeerd gebruik van navfig')
end

function DefPtSelFcn(ax,pt)
%DefPtSelFcn - Default function for displaying selected points
l=findobj(ax,'Tag','NAVFIGselPts');
if isempty(l)
	line(pt(1),pt(2),'Linestyle','none','marker','x','Color',[1 0 0]	...
		,'Tag','NAVFIGselPts')
elseif isscalar(l)
	X=get(l,'XData');
	Y=get(l,'YData');
	X(end+1)=pt(1);
	Y(end+1)=pt(2);
	set(l,'XData',X,'YData',Y);
else
	error('Multiple NAVFIG-selection display lines available?!')
end

function [D,oneX,ptV]=getaxdataX(ax,pt)
% GETAXDATA - Geeft datapunten van lijnen (enkel kijkend volgens X)
ptV = pt;
if isappdata(get(ax,'parent'),'navfigX')
	X=getappdata(get(ax,'parent'),'navfigX');
elseif isappdata(ax,'navfigX')
	X=getappdata(ax,'navfigX');
else
	X=[];
end
ll=FindLines(ax);
D=[pt;zeros(length(ll),2)];
if isempty(ll)
	if nargout>1
		oneX=[];
	end
	return
end
lNOK=zeros(1,length(ll));	% niet false om compatibiliteitsreden
for i=1:length(ll)
	tg=get(ll(i),'Tag');
	if strcmp(tg,'NAVFIGselPts')
		lNOK(i)=true;	% don't use pointer line as "line"
	end
end
BxyRuler = false(1,2);
if isempty(X)
	for i=1:length(ll)
		X=get(ll(i),'XData');
		if ~isvector(X)
			X=X(1,:);	%!!!!!!
		end
		if ~isnumeric(X)
			X = ruler2num(X,get(ax,'XAxis'));
			BxyRuler(1) = true;
		end
		if isempty(X) || min(X)>pt(1) || max(X)<pt(1)
			lNOK(i)=1;
		else
			Y=get(ll(i),'YData');
			if ~isvector(Y)
				if size(Y,1)==4
					Y=Y(2,:);	% supposing bar-plot(!)
				else
					Y=max(Y);	%!!!!!!!!!
				end
			end
			if ~isnumeric(Y)
				Y = ruler2num(Y,get(ax,'YAxis'));
				BxyRuler(2) = true;
			end
			[~,j]=min(abs(X-pt(1)));
			D(i+1,:)=[double(X(j)) double(Y(j))];
		end
	end
	if any(BxyRuler)
		ptV = num2cell(pt);
		if BxyRuler(1)
			ptV{1} = num2ruler(pt(1),get(ax,'XAxis'));
		end
		if BxyRuler(1)
			ptV{2} = num2ruler(pt(2),get(ax,'YAxis'));
		end
		ptV{1} = string(ptV{1});
		ptV{2} = string(ptV{2});
	end
else
	[~,j]=min(abs(X-pt(1)));
	D(2:end,1)=X(j);
	for i=1:length(ll)
		Y=get(ll(i),'YData');
		if length(Y)~=length(X)
			lNOK(i)=1;
			%???wat doen???
		else
			D(i+1,2)=Y(j);
		end
	end
end
if any(lNOK)
	D(find(lNOK)+1,:)=[];
end

if nargout>1
	if size(D,1)>1
		oneX=all(D(2:end,1)==D(2,1));
	else
		oneX=[];
	end
end

function XL=getxlim(as,xislog)
% GETXLIM - Geeft extremen van inhoud van assen
l=FindLines(as);
if isempty(l)
	L=get(as,'children');
	if iscell(L)
		for i=1:length(L)
			L{i}=L{i}(:)';
		end
		L=[L{:}];
	else
		L=L(:)';
	end
	XL=[];
	for l=L
		S=get(l);
		if isfield(S,'XData')
			if xislog
				bxPos=S.XData(:)>0;
				xl1=[min(S.XData(bxPos)) max(S.XData(bxPos))];
			elseif strcmp(S.Type,'image') && length(S.XData)>2  && all(diff(S.XData)>0)
				xl1 = [1.5*S.XData(1)-0.5*S.XData(2) 1.5*S.XData(end)-0.5*S.XData(end-1)];
			else
				xl1=[min(S.XData(:)) max(S.XData(:))];
			end
		elseif isfield(S,'Position')
			xl1=S.Position([1 1]);
		else
			xl1=[];
		end
		if ~isempty(xl1)
			if isempty(XL)
				XL=xl1;
			else
				XL=[min(XL(1),xl1(1)) max(XL(2),xl1(2))];
			end
		end
	end
	if isempty(XL)
		XL=[0 1];	% !!!??naar andere objecten zoeken of op basis van axis auto?
	end
	return
end
XL=[+inf -inf];
for i=1:length(l)
	lp=getappdata(ancestor(l(i),'figure'),'NAVFIGlongplot');
	if isempty(lp)
		lp=false;
	end
	if lp
		X=plotlong('getX',l(i));
		if isempty(X)	% not normal!!!!!! this is a quickquick bug fix (or trial for...)!!!!!
			X=get(l(i),'XData');
		end
	else
		X=get(l(i),'XData');
	end
	if xislog
		X=X(X>0);
	elseif ~isvector(X)
		X=X(:);
	end
	if ~isempty(X)
		if isdatetime(X)
			X = datenum(X);
		end
		XL(1)=min(XL(1),min(X));
		XL(2)=max(XL(2),max(X));
	end
end
x = xlim;
if isdatetime(x)
	XL = datetime(XL,'ConvertFrom','datenum','TimeZone',x.TimeZone);
end

function fs=GetAvailableHandles(fs)
fpos=union(get(0,'Children'),findobj('Type','axes'));
%fs=intersect(fs,fpos);	% not used to keep the order
for i=1:length(fs)
	if ~any(fs(i)==fpos)
		fs(i)=0;
	end
end
fs=fs(fs~=0);

function [fs,rlink]=getlinked(f,overruleStop)
rlink=0;
if nargin>1 && overruleStop
	tempstop=0;
else
	tempstop=getappdata(f,'tempstoplink');
end
if isequal(tempstop,1)
	fs1=[];
else
	fs1=getappdata(f,'linkednavfig');
	rlink=getappdata(f,'rlink');
end
if ~isempty(fs1)&&(isnumeric(fs1)||any(ishghandle(fs1)))
	fs=GetAvailableHandles(fs1);
	if length(fs1)>length(fs)
		warning('NAVFIG:figRelinked','!!!!figuren herlinkt!!!!')
		setlinked(fs,fs)
	end
else
	fs=[];
end

function setlinked(f,fs,rlink)
if ~exist('rlink','var')
	rlink=[];
end
fs=GetAvailableHandles(fs);
for i=1:length(f)
	f_i=ancestor(f(i),'figure');
	setappdata(f_i,'linkednavfig',fs)
	if ~isempty(rlink)||isempty(fs)
		setappdata(f_i,'rlink',rlink)
	end
end

function [X,Y,j]=GetXY(l,xl)
X=get(l,'XData');
Y=get(l,'YData');
bOK=~isnan(X)&~isnan(Y);
X=X(bOK);
Y=Y(bOK);
if nargin>1
	b=X>=xl(1)&X<=xl(2);
	X=X(b);
	Y=Y(b);
end
if nargout>2
	j=find(b);
end

function b = IsPtInRange(pt,ax)
%IsPtInRange - is a point (x,y) in axis-range
%     taking into account non-numeric possibilities of xl and yl
%         b = IsPtInRange(pt,ax)
%            pt assumed to be numeric

xl = get(ax,'XLim');
if ~isnumeric(xl)
	xl = ruler2num(xl,get(ax,'XAxis'));
end
yl = get(ax,'YLim');
if ~isnumeric(yl)
	yl = ruler2num(yl,get(ax,'YAxis'));
end
b = pt(1)>=xl(1) && pt(1)<=xl(2) && pt(2)>=yl(1) && pt(2)<=yl(2);


function x=doezoom(f,x,dx,xislog)
zoomtype=getappdata(f,'zoomtype');
if isempty(zoomtype)
	zoomtype=1;
end
if xislog
	switch zoomtype
		case 1	% links
			x=[x(1) x(1)*dx];
		case 2	% midden
			x=sqrt(prod(x))*sqrt([1/dx dx]);
		case 3
			x=[x(2)/dx x(2)];
	end
else
	switch zoomtype
		case 1	% links
			x=[x(1) x(1)+dx];
		case 2	% midden
			x=(x(1)+x(2))/2+[-dx dx]/2;
		case 3
			x=[x(2)-dx x(2)];
	end
end

function KeyPressed(f,ev)
global NAVFIGsets NAVFIGlogs
global TESTtxtCOR
f = ancestor(f,'figure');	% to allow adding KeyPressFcn to objects in a figure
bUIhandling = getappdata(f,'uihandlingactive');
if ~isempty(bUIhandling) && bUIhandling
	return	% don't handle
elseif isempty(ev)
	error('Wrong use of this function (too low Matlab version?)')
end
c=ev.Character;
bUI=true;
if isempty(c)
	% system key
	c=ev.Key;
else
	doYouWantToDoSomething = false;
end
if ~isempty(ev.Modifier)
	if any(strcmp('simul',ev.Modifier))
		bUI=false;
	end
end

as=GetNormalAxes(f);
asL=getlinked(f,1);
if ~isempty(asL)&&any(strcmp(get(asL,'type'),'axes'))
	b=false;
	for i=1:length(asL)
		if strcmp(get(asL(i),'type'),'axes')
			if get(asL(i),'parent')==f
				b=true;
				break;
			end
		end
	end
	if b
		as=intersect(as,asL);
	end
end
extra=getappdata(f,'NAVFIGkey');
as1=getappdata(f,'NAVFIGas');
if ~isempty(as1)
	as=as1;
end
if isempty(as)
	return
end
x=get(as(1),'XLim');
xislog=strcmp(get(as(1),'XScale'),'log');
x0=x;
if xislog
	if x(1)<=0
		h=findobj(f,'-property','XData');
		if isempty(h)
			x(1)=x(2)/1e5;
		else
			xmin=x(2);
			for i=1:length(h)
				x1=get(h(i),'XData');
				xmin=min(xmin,min(x1(x1>0)));
			end
			x(1)=xmin;
		end
	end
	dx=x(2)/x(1);
else
	dx=diff(x);
end
doebepfig=0;
bUndo=false;
reedsverwerkt=0;
if ~isempty(extra)
	if ~iscell(extra)||size(extra,2)~=3
		error('!!!Verkeerde NAVFIGkey-data!!!')
	end
	i=find(strcmp(c,extra(:,1)));
	if length(i)>1
		error('!!!Meerdere mogelijkheden in navfig-uitbreiding!!!')
	elseif ~isempty(i)
		reedsverwerkt=1;
		if extra{i,2}
			if ischar(extra{i,3})
				eval(['[doebepfig,x]=' extra{i,3} ';']);
			elseif iscell(extra{i,3})
				doebepfig=extra{i,3}{1};
				x=extra{i,3}{2};
			else
				[doebepfig,x]=extra{i,3}(f);
			end
		else
			if ischar(extra{i,3})
				eval(extra{i,3});
			else
				extra{i,3}(f)
			end
			return
		end
	end	% key gevonden in extra data
end	% extra data bestaat
if ~reedsverwerkt
	switch c
		case 0
			doebepfig=1;
		case 'l'
			if xislog
				x=x/sqrt(dx);
			else
				x=x-dx/2;
			end
			doebepfig=1;
		case {'L','pageup'}
			if xislog
				x=x/dx;
			else
				x=x-dx;
			end
			doebepfig=1;
		case 28	% links
			if xislog
				x=x/dx^(1/50);
			else
				x=x-dx/50;
			end
			doebepfig=1;
		case 'r'
			if xislog
				x=x*sqrt(dx);
			else
				x=x+dx/2;
			end
			doebepfig=1;
		case {'R','pagedown'}
			if xislog
				x=x*dx;
			else
				x=x+dx;
			end
			doebepfig=1;
		case 29	% rechts
			if xislog
				x=x*dx^(1/50);
			else
				x=x+dx/50;
			end
			doebepfig=1;
		case {30,31}
			if c==30	% op
				s=1;
			else	% neer
				s=-1;
			end
			bUpDown=getappdata(f,'bUpDown');
			if isempty(bUpDown)
				bUpDown=~isempty(findobj(f,'Type','image'));
				setappdata(f,'bUpDown',bUpDown)
			end
			if bUpDown
				if strcmp(get(as(1),'YDir'),'reverse')
					sY=-1;
				else
					sY=1;
				end
				yl=ylim(as(1));
				set(as,'ylim',yl+s*sY*diff(yl)/3);
			end
		case {'s','home'}	% start
			XL=getxlim(as,xislog);
			if xislog
				x=XL(1)*[1 dx];
			else
				x=[XL(1) XL(1)+dx];
			end
			doebepfig=1;
		case {'e','end'}	% einde
			XL=getxlim(as,xislog);
			if xislog
				x=XL(2)*[1/dx 1];
			else
				x=[XL(2)-dx XL(2)];
			end
			doebepfig=1;
		case 'M'	% midden
			if xislog
				x=sqrt(prod(getxlim(as,xislog)))*[1/sqrt(dx) sqrt(dx)];
			else
				XL=mean(getxlim(as,xislog));
				x=[XL-dx/2 XL+dx/2];
			end
			doebepfig=1;
		case 'i'
			if xislog
				x=doezoom(f,x,sqrt(dx),xislog);
			else
				x=doezoom(f,x,dx/2,xislog);
			end
			doebepfig=1;
		case 'I'
			if xislog
				x=doezoom(f,x,dx^0.95,xislog);
			else
				x=doezoom(f,x,dx*0.95,xislog);
			end
			doebepfig=1;
		case 'u'
			if xislog
				x=doezoom(f,x,dx^2,xislog);
			else
				x=doezoom(f,x,dx*2,xislog);
			end
			doebepfig=1;
		case 'U'
			if xislog
				x=doezoom(f,x,dx^1.05,xislog);
			else
				x=doezoom(f,x,dx*1.05,xislog);
			end
			doebepfig=1;
		case '='
			S=getsigs(f);
			if ~iscell(S)
				S={S};
			end
			x=[Inf,-Inf];
			for i=1:length(S)
				B=S{i}(:,3)>0 & S{i}(:,4)>0;
				if any(B)
					x(1)=min(x(1),min(S{i}(B,1)));
					x(2)=max(x(2),max(S{i}(B,1)));
				end
			end
			if x(2)>x(1)
				doebepfig=true;
			else
				warning('No point found!')
			end
		case 'S'
			setappdata(f,'zoomtype',1)
		case '|'
			setappdata(f,'zoomtype',2)
		case 'E'
			setappdata(f,'zoomtype',3)
		case 19	% ctrl-S - zoom to match first point
			x1=getxlim(as,xislog);	% full range
			if x1(1)<x(2)
				x(1)=x1(1);
				doebepfig=1;
			end
		case 20	% ctrl-T - tile linked figures
			andere=getlinked(f,1);
			tile(andere)
		case 13	% ctrl-M - maximize figure(s)
			if strcmp(ev.Key,'m')	% don't maximize when pressing return or enter!
				andere=getlinked(f,1);
				maximizeFig(andere,'toggle')
			end
		case 5	% ctrl-E - zoom to match last point to the end of xlim
			x1=getxlim(as,xislog);
			if x1(2)>x(1)
				x(2)=x1(2);
				doebepfig=1;
			end
		case 'X'
			x=getxlim(as,xislog);
			if diff(x)<=0
				if x(1)==0
					x=[-1 1];
				else
					x=sort(x(1)*[.9 1.1]);
				end
			end
			doebepfig=1;
		case 'P'
			printdlg(f)
		case 'c'
			close(f);
		case 'C'
			f=union(f,getlinked(f,1));
			close(f);
		case 'a'
			addpunt
		case 'A'
			verwpunt
		case 'n'	% toon volgende figuur
			andere=getlinked(f,1);
			if ~isempty(andere)&&(isnumeric(andere)||any(ishghandle(andere)))
				for i=1:length(andere)
					andere(i)=ancestor(andere(i),'figure');
					if i>1&&andere(i)==andere(i-1)
						andere(i)=0;
					end
				end
				Bhandle=ishghandle(andere);
				if any(~Bhandle)
					warning('NAVFIG:Relinked','figuren "herlinkt"')
					navfig relink
					andere=getlinked(f,1);
					if length(andere)<2
						return
					end
					andere=andere(Bhandle);
				end
				andere=andere(strcmp(get(andere,'type'),'figure'));
				i=find(andere==f);
				if i==length(andere)
					i=0;
				end
				figure(andere(i+1));
			end
		case 'N'	% toon vorige figuur
			andere=getlinked(f,1);
			if ~isempty(andere)
				B=true(size(andere));
				for i=1:length(andere)
					andere(i)=ancestor(andere(i),'figure');
					if i>1&&andere(i)==andere(i-1)
						B(i)=false;
					end
				end
				andere=andere(B);
				i=find(andere==f);
				if i==1
					i=length(andere)+1;
				end
				figure(andere(i-1));
			end
		case 'g'
			if strcmp(get(as(1),'XGrid'),'on')
				sGrid='off';
			else
				sGrid='on';
			end
			set(GetNormalAxes(f),'XGrid',sGrid,'YGrid',sGrid)
		case 'b'
			berhell(f,-0.01);
			if bUI
				msgbox('berhell(<f>,-0.01) geinstalleerd','navfig-msgs')
			end
		case 'B'
			bertconst(f)
			if bUI
				msgbox('bertconst(<f>) geinstalleerd','navfig-msgs')
			end
		case 'm'
			navfig mouse
			if bUI
				msgbox('navfig(''mouse'') geinstalleerd','navfig-msgs')
			end
		case 'x'
			getPtFcn=getappdata(f,'NAVFIGgetPtFcn');
			ax=get(f,'CurrentAxes');
			pt=get(ax,'CurrentPoint');pt=pt(1,1:2);
			if isempty(NAVFIGlogs)||~isfield(NAVFIGlogs,'pt')
				NAVFIGlogs.pt=zeros(0,6);
			end
			NAVFIGlogs.pt(end+1,:)=[now double(f) double(ax) 0 pt];
			if ~isempty(getPtFcn)
				getPtFcn(ax,pt);
			end
			if strcmp(get(gco,'type'),'image')
				[v,pt] = GetImgValue(gco,pt);
				fprintf('(%5g,%5g) - img: %g\n',pt,v);
				setappdata(ax,'navfigLastData',struct('type','image','pt',pt,'v',v));
				return
			end
			if ~IsPtInRange(pt,ax)
				return
			end
			[D,oneX,ptV]=getaxdataX(ax,pt);
			if iscell(ptV)
				fprintf('(%s,%s) - ',ptV{:});
			elseif isequal(getappdata(as(1),'updateAxes'),@axtick2date)
				t=Tim2MLtime(pt(1));
				fprintf('(%5g,%5g - %s) - ',pt,datestr(t));
			else
				fprintf('(%5g,%5g) - ',pt);
			end
			if isempty(oneX)
			elseif oneX
				fprintf('(%g) - %g',D(2,:));
				if size(D,1)>2
					fprintf(',%g',D(3:end,2))
				end
			else
				fprintf('(%8g,%5g)  ',D(2:end,:)')
			end
			fprintf('\n')
			setappdata(ax,'navfigLastData',D);
			varname=getappdata(f,'NAVFIGlogname');
			if ~isempty(varname)
				D=D(:)';
				try
					V=evalin('base',varname);
				catch err %#ok<NASGU>
					V=[];
				end
				if isempty(V)
					V=[0 D];
				else
					V(end+1,1:1+length(D))=[0 D];
				end
				assignin('base',varname,V);
			end
		case {'d','D'}
			ax=get(f,'CurrentAxes');
			D=getappdata(ax,'navfigLastData');
			pt=get(ax,'CurrentPoint');pt=pt(1,1:2);
			if isempty(D)
				return
			elseif isstruct(D)
				switch D.type
					case 'image'
						[v,pt] = GetImgValue(gco,pt);
						dPt = pt-D.pt;
						dv = v-D.v;
						fprintf('(%5g,%5g) d(%5g,%5g) - %g d(%g)\n',pt,dPt,v,dv);
						if c=='D'
							D.pt = pt;
							D.v = v;
							setappdata(ax,'navfigLastData',D);
						end
					otherwise
						warning('Unknown type?!')
				end
				return
			end
			NAVFIGlogs.pt(end+1,:)=[now double(f),double(ax) 1 pt];
			if ~IsPtInRange(pt,ax)
				return
			end
			[D1,oneX,ptV]=getaxdataX(ax,pt);
			if size(D1,1)~=size(D,1)
				warning('New point not compatible with previous point?!')
			end
			if c=='D'
				D(1,:)=pt;
			end
			D2=[pt;D1(2:end,:)-D(2:end,:)];
			if iscell(ptV)
				fprintf('(%s,%s) - ',ptV{:});
			else
				fprintf('(%5g,%5g) - ',pt);
			end
			if isempty(oneX)
				fprintf('%g,%g',D2-D);
			elseif oneX
				fprintf('(%g) - %g',D2(2,:));
				if size(D,1)>2
					fprintf(',%g',D2(3:end,2))
				end
			else
				fprintf('%8g(%5g)  ',D2(2:end,:)')
			end
			if c=='D'
				setappdata(ax,'navfigLastData',D1);
			end
			fprintf('\n')
			varname=getappdata(f,'NAVFIGlogname');
			if ~isempty(varname)
				D=D1(:)';
				try
					V=evalin('base',varname);
				catch err %#ok<NASGU>
					V=[];
				end
				if size(V,2)~=length(D)+1
					V=[1 D];
				else
					V(end+1,:)=[1 D];
				end
				assignin('base',varname,V);
			end
		case 'y'
			y=get(f,'CurrentPoint');
			if isempty(NAVFIGlogs)||~isfield(NAVFIGlogs,'spt')
				NAVFIGlogs.spt=zeros(0,4);
			end
			NAVFIGlogs.spt(end+1,:)=[now double(f) y];
			disp(y);
			varname=getappdata(f,'NAVFIGlogname');
			if ~isempty(varname)
				try
					V=evalin('base',varname);
				catch err %#ok<NASGU>
					V=[];
				end
				if size(V,2)~=2
					V=y;
				else
					V(end+1,:)=y;
				end
				assignin('base',varname,V);
			end
		case 'F'
			try
				fFFT=plotffts(f);
				setappdata(fFFT,'figOrig',f)
				setappdata(fFFT,'sigPart',x)
			catch err
				sErr=['fout trad op bij plotffts "' err.message '"'];
				DispErr(err,sErr)
				errordlg(sErr,'NAVFIG-error')
			end
		case '&'	% toggle rlink
			rlink=getappdata(f,'rlink');
			if isempty(rlink)
				rlink=0;
			end
			rlink=~rlink;
			fs=getlinked(f,1);
			for i=1:length(fs)
				setappdata(fs(i),'rlink',rlink);
			end
			if bUI
				if rlink
					msgbox('relatieve link is opgezet','navfig-msgs')
				else
					msgbox('relatieve link is afgezet','navfig-msgs')
				end
			end
		case '!'	% toggle tijdelijk link-stop
			fs=getlinked(f,1);
			if isempty(fs)
				errordlg('navfig link afzetten gaat maar als deze actief is','navfig-error')
				return
			end
			tempstop=getappdata(f,'tempstoplink');
			if isempty(tempstop)
				tempstop=0;
			end
			tempstop=~tempstop;
			for i=1:length(fs)
				setappdata(fs(i),'tempstoplink',tempstop);
			end
			if bUI
				if tempstop
					msgbox('link is tijdelijk stopgezet','navfig-msgs')
				else
					msgbox('link is terug opgezet','navfig-msgs')
				end
			end
		case '#'	% equalize-assen (alle gelijke grootte vanaf startpunt)
			fs=getlinked(f,1);
			equalizeXlim(f,fs)
		case '^'	% give min/max of displayed part
			l=FindLines(gca);
			for i=1:length(l)
				[X,Y,j]=GetXY(l(i),x);
				[mn,imn]=min(Y);
				[mx,imx]=max(Y);
				imn=j(imn);
				imx=j(imx);
				fprintf('%10g(%5d) - %10g --- %10g(%5d) - %g\n',X(imn),imn,mn,X(imx),imx,mx)
			end
		case 27		% escape - automatic scaling
			set(as,'XLimMode','auto')	% only on current axes!
			CheckUpdateFcn(as)
		case 'Q'	% specgram
			if isempty(NAVFIGsets)||~isfield(NAVFIGsets,'SG_nFFT')
				NAVFIGsets.SG_nFFT=256;
			end
			ax=GetNormalAxes(f);
			if exist('nfigure','file')
				nfigure;
			else
				figure;
			end
			for i=1:length(ax)
				ax1=axes('Position',get(ax(i),'Position'));
				l=FindLines(ax(i));
				if isempty(l)
					continue
				end
				len=length(get(l(1),'XData'));
				while length(l)>1
					len1=length(get(l(2),'XData'));
					if len>=len1
						l(2)=[];
					else
						l(1)=[];
						len=len1;
					end
				end
				[X,Y]=GetXY(l);
				nFFT=min(length(Y),NAVFIGsets.SG_nFFT);
				m_dx = median(diff(X));
				if m_dx<=0
					error('Negative timesteps are not allowed')
				elseif max(diff(X))/m_dx>1.5 || min(diff(X))/m_dx<0.5
					warning('Large variation in timestep?! (%g - %g, median: %g)'	...
						, min(diff(X)), max(diff(X)), m_dx)
				end
				[Z,F,T] = specgram(Y-mean(Y),nFFT,1/m_dx);
				newplot()
				imagesc(T+X(1),F,20*log10(abs(Z)+eps));axis xy; colormap(jet);
				navfig
				axT=get(ax(i),'Title');
				set(get(ax1,'Title'),'String',get(axT,'String')	...
					,'Interpreter',get(axT,'Interpreter'))
			end
		case {'t','T','v','V'}	% fitSine
			l=FindLines(f);
			D=[];
			for i=1:length(l)
				[X,Y,j]=GetXY(l(i),x);
				if length(X)>10&&std(Y)>0
					if lower(c)=='t'
						D1=fitsine(X',Y');
					else
						D1=fitDsine(X',Y');
					end
					if isempty(D1)
						continue
					end
					D1.lSource=l(i);
					D1.lIndex=j;
					D1.color=get(l(i),'color');
					if c<='Z'	% upper case letter
						nResample=getappdata(f,'NAVFIGresample');
						if isempty(nResample)
							nResample=0;
						end
						if nResample>1
							t=(D1.t(1):mean(diff(D1.t))/nResample:D1.t(end))';
							y=fitDsine(D1,t);
						else
							t=D1.t;
							y=D1.y;
						end
						h=uicontextmenu;
						uimenu(h,'label',sprintf('sine f=%gHz,A=%g, lC=[%1.0f%1.0f%1.0f]'	...
							,D1.f,D1.A,D1.color*9));
						uimenu(h,'label',sprintf('#%d',length(D)+1))
						uimenu(h,'label','delete','callback','delete(gco)')
						line(t,y,'color',[0.95 0.05 0.95],'parent',get(l(i),'parent')	...
							,'Tag','sineFitPlot','UserData',D1	...
							,'UIcontextMenu',h)
					end
					if isempty(D)
						D=D1;
					else
						D(end+1)=D1;
					end
				end
			end
			if isempty(D)
				errordlg('No lines found')
			else
				assignin('base','Dfit',D);
				if isempty(NAVFIGsets)||~isfield(NAVFIGsets,'fitSine_cnt')
					NAVFIGsets.fitSine_cnt=0;
				end
				if NAVFIGsets.fitSine_cnt<1&&bUI
					msgbox('sine fit results put in "Dfit" (this message is given only once)','navfig/fitSine','modal')
				end
				NAVFIGsets.fitSine_cnt=NAVFIGsets.fitSine_cnt+1;
			end
			if isempty(NAVFIGsets)||~isfield(NAVFIGsets,'fitSine_web')
				NAVFIGsets.fitSine_web=true;
			end
			if NAVFIGsets.fitSine_web
				print2html(D,3,'web')
			end
		case {'H','f1'}
			helpS=['navfig-keycodes:',newline,	...
				'"i" : zoom in (half scale), "I" zoom in 9/10 scale',newline,	...
				'"o" : zoom out (double scale), "O" zoom in 10/9 scale',newline,	...
				'"l" : go left (1/2 screen), "L"  go left (full screen)',newline,	...
				'"r" : go left (1/2 screen), "L"  go left (full screen)',newline,	...
				'"<--"/"-->" go left/right (1/50 screen)',newline,	...
				'"X" : full measurement view',newline,	...
				'"F" : plot FFT''s (showed part)',newline,	...
				'"Q" : plot spectrogram (full data)',newline,	...
				'"s"/"e" : go to start/end',newline,	...
				'"S"/"|"/"E" : zoom around start/middle/end (of figure)',newline,	...
				'"g" : toggle grid on/off',newline,	...
				'"t"/"T" : fit sine (with or without drawing of sine)',newline,	...
				'"v"/"V" : fit decaying sine (with or without drawing of sine)',newline,	...
				'"w" : remove drawn fitted sine waves',newline,	...
				'"m" : follow mouse (see next)',newline,	...
				'"x" : print values on current point (mouse position after "m")',newline,	...
				'"d" : print changes compared to last "x" ("D" same and change last point)',newline,	...
				'"y" : print coordinates (screen coordinates)',newline,	...
				'"a"/"A" : show line marker points or hide them',newline,	...
				'"ESC" : back to autoscaling',newline,	...
				'"n" : go to next linked figure',newline	...
				'"ctrl-B" : add contextmenu to lines',newline	...
				'"ctrl-C" : plot XCORR',newline		...
				'"ctrl-D" : install axtick2date',newline	...
				'"ctrl-E" : Zoom to make last point as max scale',newline	...
				'"ctrl-G" : Start axis with clicked point',newline	...
				'"ctrl-M" : Maximize figure (and linked figures)',newline	...
				'"ctrl-S" : Zoom to make first point as min scale',newline	...
				'"ctrl-T" : Tile linked figures (all if not linked!)',newline	...
				'"ctrl-X" : Manual zoom',newline	...
				'"ctrl-Y" : Manual zoom in Y-direction',newline		...
				'"ctrl-Z" : Undo last zoom-action'	...
				];
			K = navfig('keylist');
			if ~isempty(K)
				K = K(:,[4 1 3 1])';
				[K{2,:}] = deal(': ');
				[K{4,:}] = deal(newline);
				for i=1:size(K,2)
					if iscell(K{3,i})
						if length(K{3,i})==2 && isequal(K{3,i}{1},1) && length(K{3,i}{2})==2
							K{3,i} = sprintf('zoom %g..%g',K{3,i}{2});
						else
							K{3,i} = 'zoom';
						end
					elseif ~ischar(K{3,i})	% what's the use of this?
						K{3,i} = char(K{3,i});
					end
				end
				helpS = ['app-specific codes:',newline	...
					,K{:}	...
					,helpS];
			end
			helpdlg(helpS,'NAVFIG-help')
		case 'w'	% delete lines from fitSine
			delete(findobj(f,'Tag','sineFitPlot'))
		case 2	% add uicontext-capability to lines
			AddLineUIcontexts(f)
		case 3	% ctrl-c - plot xcorr
			fXCORR=nfigure;
			for i=1:length(as)
				asXCORR=axes('Parent',fXCORR,'Position',get(as(i),'Position'));
				l=FindLines(as(i));
				if ~isempty(l)
					l=l(end:-1:1);
				end
				nLines=0;
				copyProps={'Color','LineStyle','LineWidth','Marker'	...
					,'MarkerSize','MarkerEdgeColor','MarkerFaceColor'};
				bHold=false;
				for j=1:length(l)
					X=get(l(j),'XData');
					B = X>=x(1)&X<=x(2);
					X = X(B);
					if length(X)>5&&X(end)-X(1)>0
						if std(diff(X))/((X(end)-X(1))/(length(X)-1))>1e-4
							warning('Too much variation in dx!')
						else
							Y=get(l(j),'YData');
							[Y,X]=PlotXCOR(Y(B),'--bPlot');
							lXCORR=plot(asXCORR,X,Y);
							for k=1:length(copyProps)
								set(lXCORR,copyProps{k},get(l(j),copyProps{k}));
							end
							if nLines==0
								nLines=1;
								grid
								if j<length(l)
									hold all
									bHold=true;
								end
							end
						end		% plot line
					end		% line not too short and 
				end		% for j
				if bHold
					hold off
				end
				sTit = get(get(as(i),'title'),'String');
				if isempty(sTit)
					sTit = 'XCORR';
				else
					sTit = ['XCORR - ' sTit]; %#ok<AGROW>
				end
				title(asXCORR,sTit)
			end
			navfig
		case 4	% ctrl-d - axtick2date
			assen=GetNormalAxes(f);
			if isempty(assen)
				return
			end
			a=getappdata(assen(1),'updateAxes');
			if isempty(a)
				navfig('updateAxesT')
			else
				navfig('updateAxes','stop')
			end
			doebepfig=1;
		case 7	% ctrl-g - go to selected point (ref point)
			ax=get(f,'CurrentAxes');
			pt=get(ax,'CurrentPoint');pt=pt(1);
			zt=getappdata(f,'zoomtype');
			if isempty(zt)
				zt=1;
			end
			switch zt
				case 1	% start
					xRef=x(1);
				case 2
					if xislog
						xRef=sqrt(x(1)*x(2));
					else
						xRef=mean(x);
					end
				otherwise
					xRef=x(2);
			end
			if xislog
				x=x*(pt/xRef);
			else
				x=x+(pt-xRef);
			end
			doebepfig=1;
		case 8	% ctrl-h - zoom to the selected point
			ax=get(f,'CurrentAxes');
			pt=get(ax,'CurrentPoint');
			x(2)=pt(1);
			doebepfig=1;
		case 24	% ctrl-x - manual (graphical) zoom in X
			[xMin,xMax,~,~,bOK]=SelectRect(f,'x');
			if ~bOK
				return
			end
			if xMax>xMin
				x=[xMin xMax];
				doebepfig=1;
			end
		case 25	% ctrl-y - manual (graphical) zoom in Y
			[~,~,yMin,yMax,bOK]=SelectRect(f,'y');
			if ~bOK
				set(gca,'Ylimmode','auto')
				return
			end
			if yMax>yMin
				set(gca,'ylim',[yMin yMax]);
			end
		case 26	% ctrl-z - undo
			nfgHist=getappdata(f,'NAVFIGhist');
			if ~isempty(nfgHist)
				x=nfgHist(end).xlim;
				doebepfig=1;
				set(as,'XLimMode',nfgHist(end).xlimmode)	% !only on current axes!
				nfgHist(end)=[];
				setappdata(f,'NAVFIGhist',nfgHist)
				bUndo=true;
			end
		case 14	% ctrl-n - next visible point
			h=[FindLines(as);findobj(as,'Type','image')];
			newX=Inf;
			minX=x(2);
			for i=1:length(h)
				xdata=get(h(i),'xdata');
				if any(isnan(xdata)|isinf(xdata))
					xdata(isnan(xdata)|isinf(xdata))=[];
				end
				j=find(xdata>minX,1);
				if ~isempty(j)
					newX=min(newX,xdata(j));
				end
			end
			if ~isinf(newX)
				x=x+(newX-x(1));
			end
			doebepfig=1;
		case 16 % ctrl-p - previous visible point
			h=[FindLines(as);findobj(as,'Type','image')];
			newX=-Inf;
			maxX=x(1);
			for i=1:length(h)
				xdata=get(h(i),'xdata');
				if any(isnan(xdata)|isinf(xdata))
					xdata(isnan(xdata)|isinf(xdata))=[];
				end
				j=find(xdata<maxX,1,'last');
				if ~isempty(j)
					newX=max(newX,xdata(j));
				end
			end
			if ~isinf(newX)
				x=x+(newX-x(2));
			end
			doebepfig=1;
		case 17		% ctrl-q - zoom in on visible range
			X=getsigs(f,'-bKeepCell');
			x=[Inf -Inf];
			for i=1:length(X)	% all axes
				for j=1:length(X{i})	% all lines
					if any(X{i}{j}(:,3))
						x(1)=min(x(1),min(X{i}{j}(X{i}{j}(:,3)>0,1)));
						x(2)=max(x(2),max(X{i}{j}(X{i}{j}(:,3)>0,1)));
					end
				end		% for j
			end		% for i
			if x(1)<x(2)
				doebepfig=1;
			elseif x(1)==x(2)
				warning('Only one point found -- no zoom done')
			end
		case '?'
			if isequal(getappdata(as(1),'updateAxes'),@axtick2date)
				t=Tim2MLtime(x);
				fprintf('   limit: %s - %s, %gs\n',datestr(t(1))	...
					,datestr(t(2)),diff(t)*86400)
			else
				fprintf('   limit: %g - %g, %gs\n',x,diff(x))
			end
		otherwise
			% not handled keypress
	end	% switch c
end	% nog niet verwerkt
if doebepfig
	[andere,rlink]=getlinked(f);	%!!!!! is al eerder gedaan (asL) !!!
	if length(andere)<2||~any(ishandle(andere))
		andere=[];
	end
	lp=getappdata(f,'NAVFIGlongplot');
	if ~bUndo
		nfgHist=getappdata(f,'NAVFIGhist');
		if isempty(nfgHist)
			nfgHist=struct('xlim',cell(1,0),'xlimmode',[]);
		end
		nfgHist(1,end+1).xlim=get(as(1),'xlim');
		nfgHist(end).xlimmode=get(as(1),'XLimMode');
		setappdata(f,'NAVFIGhist',nfgHist)
	end
	if isempty(lp)
		lp=false;
	end
	if isempty(andere)
		if isdatetime(get(gca,'xlim'))&&isnumeric(x)
			x = datetime(x,'convertFrom','datenum');
		end
		if ~isequal(x,x0)
			set(as,'XLim',x);
		end
		assen=as;
	elseif isequal(rlink,1)
		dx1=x(1)-x0(1);
		rdx=diff(x)/diff(x0);
		assen=GetNormalAxes(andere);
		assen=RemoveNoLink(assen);
		for i=1:length(assen)
			x1=get(assen(i),'xlim');
			set(assen(i),'xlim',[x1(1)+dx1,x1(1)+dx1+diff(x1)*rdx])
		end
	else
		andere=RemoveNoLink(andere);
		try
			if ~isequal(x,x0)
				bepfigs(x,andere)
			end
		catch
			warning('NAVFIG:Relinked','figuren "herlinkt"')
			navfig relink
			andere=getlinked(f);
			bepfigs(x,andere)
		end
		assen=GetNormalAxes(andere);
	end
	if lp
		plotlong(x,assen)
	end
	CheckUpdateFcn(assen)
	if isempty(NAVFIGsets)||~isfield(NAVFIGsets,'bTEXTcorrection')
		NAVFIGsets.bTEXTcorrection=true;
	end
	if isempty(TESTtxtCOR)
		TESTtxtCOR=true;
	end
	if TESTtxtCOR	...
			&&NAVFIGsets.bTEXTcorrection	...
			&&~isempty(findobj(assen,'Type','text'))
		%(!!!!!!!!!trial to solve matlab but related to text shown on wrong places!!!!!!)
		try
			TESTtxtCOR=false;
			fCur=gcf;
			f=get(assen,'Parent');
			if iscell(f)
				f=unique([f{:}]);
			end
			for i=1:length(f)
				getframe(f(i));	%(!!!!!!!!!) this is added to avoid having text shown wrongly in graphs(!!Matlab-bug)
			end
			if length(f)>1&&fCur~=f(i)
				figure(fCur)
			end
			TESTtxtCOR=true;
		catch err
			DispErr(err,'Error when correcting text-fields - correction is stopped')
			NAVFIGsets.bTEXTcorrection=false;
		end
		%(!!!!!!!!!!!!!)
	end
end

function [xMin,xMax,yMin,yMax,bOK]=SelectRect(f,typ)
%SelectRect - Lets a user select a rectangle
ptr=get(f,'Pointer');
switch typ
	case 'x'
		set(f,'Pointer','crosshair')
	case 'y'
		set(f,'Pointer','cross')
	case 'xy'
		set(f,'Pointer','crosshair')
		%set(f,'Pointer','fullcrosshair')
	otherwise
		warning('Not expected SelectRect-type! (%s)',typ)
end
setappdata(f,'uihandlingactive',true)
k=waitforbuttonpress;
if k
	set(f,'Pointer',ptr)
	xMin=0;
	xMax=0;
	yMin=0;
	yMax=0;
	bOK=false;
else
	ax=gca;
	pt1=get(ax,'CurrentPoint');
	rbbox;
	set(f,'Pointer',ptr)
	drawnow		% does this help for updating the position?  It seems to be.
	pt2=get(ax,'CurrentPoint');
	xMin=min(pt1(1),pt2(1));
	xMax=max(pt1(1),pt2(1));
	yMin=min(pt1(1,2),pt2(1,2));
	yMax=max(pt1(1,2),pt2(1,2));
	bOK=true;
end
pause(0.01)
rmappdata(f,'uihandlingactive')

function l=FindLines(h)
l=[findobj(h,'Type','line','Visible','on');
	findobj(h,'Type','stair','Visible','on');
	findobj(h,'Type','patch','Visible','on')];
l = l(end:-1:1);

function assen=RemoveNoLink(assen)
i=1;
assen=assen(:)';
while i<=length(assen)
	if strcmp(get(assen(i),'Type'),'figure')
		if isappdata(assen(i),'NAVFIGas')
			asFig=getappdata(assen(i),'NAVFIGas');
			assen=[assen(1:i-1),asFig(:)'];
			i=i+length(asFig);
		else
			i=i+1;
		end
	elseif isappdata(assen(i),'noNavfig')&&getappdata(assen(i),'noNavfig')
		assen(i)=[];
	else
		i=i+1;
	end
end

function AddLineUIcontexts(f)
l = findobj(f,'Type','line');
hMn = uicontextmenu(f);
uimenu(hMn,'Label','gradient','Callback','berhell')
uimenu(hMn,'Label','t-constant','Callback','bertconst')


set(l,'UIcontextmenu',hMn)
fprintf('Contextmenu-capabilities added to lines in figure %d.\n',double(f))

function CheckUpdateFcn(assen)
for i=1:length(assen)
	fcn=getappdata(assen(i),'updateAxes');
	fcnArgs=getappdata(assen(i),'updateAxesArgs');
	if isempty(fcnArgs)
		fcnArgs={};
	elseif ~iscell(fcnArgs)
		fcnArgs={fcnArgs};
	end
	if ~isempty(fcn)
		if isempty(fcnArgs)&&ischar(fcn)
			eval(fcn)
		elseif iscell(fcn)
			for j=1:length(fcn)
				fcn{j}(assen(i),fcnArgs{:})
			end
		else
			fcn(assen(i),fcnArgs{:})
		end
	end
end

function [v,pt] = GetImgValue(hImg,pt)
Ximg = get(hImg,'XData');
Yimg = get(hImg,'YData');
Cimg = get(hImg,'CData');
if length(Ximg)==2&&size(Cimg,2)~=2
	Ximg = linspace(Ximg(1),Ximg(2),size(Cimg,2));
end
if length(Yimg)==2&&size(Cimg,1)~=2
	Yimg = linspace(Yimg(1),Yimg(2),size(Cimg,1));
end
if Ximg(1)==1 && all(diff(Ximg)==1) && Yimg(1)==1 && all(diff(Yimg)==1)
	pt = round(pt);
	v = Cimg(max(1,min(end,pt(2))),max(1,min(end,pt(1))));
else
	x = max(Ximg(end),min(Ximg(1),pt(1)));	% allow out of range values
	y = max(Yimg(end),min(Yimg(1),pt(2)));	% allow out of range values
	v = interp2(Ximg,Yimg,Cimg,x,y);
end
