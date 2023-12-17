function [varargout] = volglijn(lvar,lvast,lvolg)
% VOLGLIJN - verplaatsen van lijn op basis pointer op andere lijn
%      volglijn(lvariabel,lvast,lvolg)
%           lvariabel : handle van lijn(en) die moet(en) volgen
%                      (normally time based plots)
%           lvast     : handle van lijn waarop gevolgd moet worden
%                       (XY-plot)
%           lvolg     : x-data voor "variable lijn"
%                    of handle van lijn met deze x-data
%                    als niet gegeven wordt lijn uit "var-axes" genomen.
%
%     Drukken van de volgende toetsen heeft het volgende effect :
%          'l'    : Toont de volgende lijnen door deze naar de juiste
%                   plaats te scrollen.
%          'i'    : Zoomt de grafieken met de volgende lijnen in.
%          'u'    : Zoomt de grafieken met de volgende lijnen uit.
%          'I'    : Zoom in in the XY-plot
%          'U'    : Zoom out in the XY-plot
%          'f'    : find centre point in x-plots to XY-plot
%          'n' of pijl rechts : selecteert volgend punt
%          'p' of pijl links : selecteert vorig punt
%          pijl boven : 10 punten verder
%          pijl onder : 10 punten terug
%          PgUp   : 100 punten terug
%          PgDn   : 100 punten verder
%          Home/End: start/stop meting
%          's' : toon andere figuren
%          'C' : sluit figuren
%          't' : toon punt
%          'P' : zet punt van op het midden van de Y/t graph(lvariabel)
%          'S' : stop volg (zelfde als volglijn stopvolg)
%          'R' : herstart (restart) volg (zelfde als volglijn volgopnieuw)
%          'L' : make markers to the right limit
%          'v' : volg lijnen (door lijnen in centrum van as te houden) aan/afzetten
%          'M' : show/toggle logged points
%          'ctrl-P' : mark point 1
%          'ctrl-Q' : mark point 2
%          'ctrl-R' : reset pointer lines (similar to "L")
%          'ctrl-L' : plot(/toggle) line of zoomed parts in T-plots
%
%    andere volglijn-mogelijkheden :
%        volglijn stop : stopt met volgen (laat lijnen staan)
%        volglijn stopvolg : stopt met volgen (maar kan nog gebruikt worden
%                            met muisklikken)
%        volglijn volgopnieuw : volg opnieuw
%        volglijn clear : verwijdert de volgende lijnen
%        volglijn clearall : verwijdert alle grafische elementen ivm volglijn
%        volglijn('fupdate',<function_handle>)
%               function(f,<idx>,<coor>)
%        volglijn('setKeyFun',<function_handle>)
%           example: volglijn('setKeyFun',@(S,c) disp(['key: "',c,'"']))
%                  S : struct with handles to different parts
%                  c : character or key pressed

% toe te voegen
% - als te volgen assen "axtick2date" zijn, juist updaten bij scrollen
%       --> klaar?
% - delete-function bij marker-lijnen
% - mogelijkheid om XY-plot te zoomen naar getoonde deel in Y/t plots
%   en/of volledige track (zeker bij "belgie-mode")

% Er is gestart met meerdere "vaste lijnen", maar nog niets werkends.

global lastVLfvast

if isempty(get(0,'children'))
	return
end

try
	upd_lijn=false;
	bVolg=false;
	bLimAxes=false;
	nMinPts=4;
	dxl=[];
	f=gcbf;
	if isempty(f)
		f=gcf;
	end
	bCallUpdateFcn = true;
	
	S=getappdata(f,'volglijn_fvast');
	if isempty(S)
		if ~isempty(lastVLfvast)
			f=lastVLfvast;
			S=getappdata(f,'volglijn_fvast');
		end
	else
		lastVLfvast=f;
	end
	if ~isempty(S)
		VL1=S.VL1;
		VLx=S.VLx;
		VLl=S.VLl;
		VLvx=S.VLvx;
		VLa=S.VLa;
		VLDy=S.VLDy;
		VLcurl=S.VLcurl;
		bVolg=S.bVolg;
	end
	
	if (nargin==3 && ~islogical(lvolg))||(nargin&&~ischar(lvar))
		if nargin<3
			lvolg=[];
		end
		tlvar=get(lvar(1),'type');
		VLx=[0 0];
		% !!! this works only if all types of lvar are the same!!!!
		if strcmp(tlvar,'figure')
			fvar=lvar;
			Avar=GetNormalAxes(lvar);
			lvar=FindLines(Avar,nMinPts);
		elseif strcmp(tlvar,'axes')
			fvar=get(lvar,'parent');
			if iscell(fvar)
				fvar=unique([fvar{:}]);
			end
			Avar=lvar;
			lvar=FindLines(Avar,nMinPts);
		elseif any(strcmp(tlvar,{'line','stair'}))
			Avar=get(lvar,'Parent');
			if length(lvar)>1
				Avar=unique([Avar{:}]);
			end
			fvar=ancestor(Avar,'figure');
			if length(lvar)>1
				fvar=unique([fvar{:}]);
			end
		else
			error('Verkeerde input voor "lvar"')
		end
		VLl=zeros(1,length(Avar));
		for i=1:length(Avar)
			VLl(i)=line(VLx,get(Avar(i),'ylim')	...
				,'parent',Avar(i)	...
				,'color',[1 0 0]	...
				...,'erasemode','xor'	... old Matlab (removed useful functionality...)
				,'Tag','volglijn'	...
				);
		end
		fvast=0;
		switch get(lvast,'type')
			case {'line','patch','stair'}
				VLa=get(lvast,'parent');
				fvast=get(VLa,'parent');
			case {'axes','figure'}
				if strcmp(get(lvast,'type'),'figure')
					fvast=lvast;
					VLa=GetNormalAxes(lvast);
					if length(lvast)>1
						warning('VOLGLIJN:multiAxes','!!!!meerdere assen in figuur (lvast), de eerste wordt genomen!!!')
					end
				else
					fvast=get(lvast,'parent');
					VLa=lvast;
				end
				lvast=findobj(VLa,'type','patch');
				if isempty(lvast)
					lvast=FindLines(VLa,[],length(get(lvar(1),'XData')));
					if isempty(lvast)
						error('Kan geen lijn in vaste as vinden')
					end
				end
				if length(lvast)>1
					warning('VOLGLIJN:multiLine','!Meerdere lijnen in vaste as gevonden!!')
					%lvast=lvast(1);
				end
		end
		u=get(VLa(1),'Units');
		set(VLa(1),'Units','pixels')
		p=get(VLa(1),'Position');
		set(VLa(1),'Units',u);
		xl=get(VLa(1),'XLim');
		yl=get(VLa(1),'YLim');
		VLDy=diff(xl)/diff(yl)/p(3)*p(4);
		if length(lvast)>1
			VL1=cell(1,length(lvast));	% start with cell(!)
			for i=1:length(lvast)
				VL1{i}=get(lvast(i),'XData')+1i*get(lvast(i),'YData')*VLDy;
				VL1{i}=VL1{i}(:);
			end
			N=cellfun('length',VL1);
			if ~all(length(VL1{1})==N)
				maxN=max(N);
				for i=find(N<maxN)
					VL1{i}(end+1:maxN)=NaN;
				end
				warning('Sorry, with multiple lines, all lines should have the same length!  Things can go wrong.')
			end
			VL1=cat(2,VL1{:});
		else
			VL1=get(lvast,'XData')+1i*get(lvast,'YData')*VLDy;
			VL1=VL1(:); 
		end
		if isempty(lvolg)
			lvolg=FindLines(get(VLl(1),'parent'));
			for i=1:length(lvolg)
				VLvx=get(lvolg(i),'XData');
				if length(VLvx)>2
					break;
				end
			end
		elseif length(lvolg)==1
			VLvx=get(lvolg,'XData');
		else
			VLvx=lvolg;
		end
		set(fvast	...
			,'WindowButtonDownFcn','volglijn'	...
			,'WindowButtonMotionFcn','volglijn'	...
			,'KeyPressFcn','volglijn(''key'')'	...
			...,'DeleteFcn','volglijn(''clearall'');delete(gcf)'	...
			)
		l=FindLines(fvar,[],length(VLvx));	% refinding lvar's?!
		set(l,'ButtondownFcn',@PtSelectedT)
		axes(VLa)
		bVolg=false;
		VLcurl=line(0,0,'Color',[1 0 0]...,'EraseMode','xor'	...
			,'LineStyle','none','Marker','o'	...
			,'Tag','volglijnDot'	...
			,'HitTest','off'	...
			,'DeleteFcn','volglijn(''clearall'');'	...
			);
		S=struct('VL1',VL1  ...
			,'VLx',VLx  ...
			,'VLl',VLl ...
			,'VLvx',VLvx    ...
			,'VLa',VLa ...
			,'VLDy',VLDy    ...
			,'VLcurl',VLcurl    ...
			,'fvast',fvast  ...
			,'fvar',fvar    ...
			,'bVolg',bVolg	...
			,'lvar',lvar	...
			,'lvast',lvast	...
			);
		setappdata(fvast,'volglijn_fvast',S);
		setappdata(fvast,'VL_AXlink',[])
		for i=1:length(fvar)
			setappdata(fvar(i),'VL_fvar',fvast)
		end
		lastVLfvast=fvast;
		volglijn key home
	elseif nargin && ischar(lvar)
		if isempty(S)
			if ~strcmp(get(gcf,'beingdeleted'),'on')
				warning('VOLGLIJN:MissingData','Gebruik van volglijn zonder de nodige data')
			end
			return
		end
		switch lower(lvar)
			case 'stop'
				if ishandle(VLa)
					fig=get(VLa,'parent');
				else
					fig=gcf;
				end
				set(fig,'WindowButtonMotionFcn','','WindowButtonDownFcn','','KeyPressFcn','');
				%rmappdata(S.fvast,'volglijn_fvast')
				lastVLfvast=[];
			case 'herstart'
				set(get(VLa,'parent'),'WindowButtonMotionFcn','volglijn'	...
					,'WindowButtonDownFcn','volglijn'	...
					,'KeyPressFcn','volglijn(''key''');
			case 'stopvolg'
				set(get(VLa,'parent'),'WindowButtonMotionFcn','');
			case 'volgopnieuw'
				set(get(VLa,'parent'),'WindowButtonMotionFcn','volglijn');
			case 'clear'
				volglijn stop
				rmappdata(S.fvast,'volglijn_fvast')
				if ~isempty(VLcurl)&&ishghandle(VLcurl)&&VLcurl~=0
					delete(VLcurl)
					VLcurl=[];
				end
			case 'clearall'
				volglijn clear
				if ~isempty(VLl)
					for i=1:length(VLl)
						if isgraphics(VLl(i))
							delete(VLl(i))
						end
					end
					VLl=[];
				end
			case 'resetmarkers'
				for i=1:length(VLl)
					ax=get(VLl(i),'Parent');
					set(VLl(i),'Visible','off');
					drawnow
					yl=get(ax,'YLim');
					set(VLl(i),'YData',yl,'Visible','on')
				end
			case 'fupdate'
				setappdata(S.fvast,'volglijn_fUpdate',lvast)
			case 'togglevolg'
				S.bVolg=~bVolg;
				setappdata(S.fvast,'volglijn_fvast',S);
			case 'link'
				setappdata(S.fvast,'VL_AXlink',GetNormalAxes(lvast))
				navfig('link',[S.fvast lvar(:)'])
			case 'setpt'
				i=lvast;
				upd_lijn=true;
				if nargin>2
					bCallUpdateFcn = lvolg;
				end
			case 'key'
				if nargin>1
					c=lvast;
				else
					c=get(gcf,'CurrentCharacter');
					if isempty(c)
						c=get(gcf,'CurrentKey');
					end
				end
				xd=get(VLl(1),'xdata');
				xd=xd(1);
				xl=get(get(VLl(1),'parent'),'xlim');
				dxl=diff(xl)/2;
				if isnan(xd)||isinf(xd)
					warning('VOLGLIJN:InfNaN','Er wordt gestopt met de volglijn-key-verwerking door Inf of NaN')
					return
				end
				i=getappdata(VLl(1),'VL_i');
				if isempty(i)
					i=1;
				end
				switch c
					case 'l'
						if xd<xl(1)||xd>xl(2)
							xl=xd+[-dxl dxl];
							bLimAxes=true;
						end
					case 'i'
						xl=xd+[-dxl dxl]/2;
						bLimAxes=true;
					case 'u'
						xl=xd+[-dxl dxl]*2;
						bLimAxes=true;
					case {29,'n',' ','1'}
						if i<length(VLvx)
							upd_lijn=true;
							i=i+1;
						end
					case {28,'p','9'}
						if i>1
							upd_lijn=true;
							i=i-1;
						end
					case {30,'2'}	% up
						if i<length(VLvx)
							upd_lijn=true;
							i=min(length(VLvx),i+10);
						end
					case {31,'8'}	% down
						if i>1
							upd_lijn=true;
							i=max(1,i-10);
						end
					case '3'	% up
						if i<length(VLvx)
							upd_lijn=true;
							i=min(length(VLvx),i+100);
						end
					case '7'	% down
						if i>1
							upd_lijn=true;
							i=max(1,i-100);
						end
					case '4'	% up
						if i<length(VLvx)
							upd_lijn=true;
							i=min(length(VLvx),i+1000);
						end
					case '6'	% down
						if i>1
							upd_lijn=true;
							i=max(1,i-1000);
						end
					case 'pageup'
						if i>1
							upd_lijn=true;
							i=max(1,i-100);
						end
					case 'pagedown'
						if i<length(VLvx)
							upd_lijn=true;
							i=min(length(VLvx),i+100);
						end
					case {'home','0'}
						upd_lijn=true;
						i=1;
					case {'end','e'}
						upd_lijn=true;
						i=length(VLvx);
					case 's'	% toon andere figuur
						for iF=1:length(S.fvar)
							figure(S.fvar(iF))
						end
						figure(S.fvast)
						upd_lijn=true;bVolg=true;	% (scroll to markers)
					case 'S'	% stop volg
						volglijn stopvolg
					case 'R'
						volglijn volgopnieuw
					case 'v'
						volglijn togglevolg
					case 'f'
						upd_lijn=true;
						i=findclose(mean(xl),VLvx);
					case 'P'	% ga naar punt van lvar
						ax=get(VLl(1),'Parent');
						xl=get(ax,'XLim');
						i=findclose(VLvx,mean(xl));
						upd_lijn=true;
					case 'L'	% remake pointer lines
						set(VLl,'Visible','off')
						ax=get(VLl,'Parent');
						if iscell(ax)
							ax=cat(2,ax{:});
						end
						xl=get(ax(1),'XLim');
						set(ax,'XLim',xl(1)+[0.1 0.9]*diff(xl))
						
						ff = ancestor(ax,'figure');
						if iscell(ff)
							ff = [ff{:}];
						end
						addpunt(ff)
						drawnow
						verwpunt(ff)
						
						for i=1:length(VLl)
							yl=get(get(VLl(i),'Parent'),'YLim');
							set(VLl(i),'YData',yl(1)+[0.1 0.9]*diff(yl))
						end
						set(ax,'XLim',xl)
						set(VLl,'Visible','on')
					case 'M'
						volglijn('addlogpts')
					case 'C'
						close(S.fvast);
						close(S.fvar);
					case {'I','U'}	% zoom in "vaste figuur" (XY-grafiek)
						axC=get(VLcurl,'parent');
						xlC=get(axC,'Xlim');
						ylC=get(axC,'Ylim');
						if c=='I'
							dx=diff(xlC)/2;
							dy=diff(ylC)/2;
						else
							dx=diff(xlC)*2;
							dy=diff(ylC)*2;
						end
						if ~any(isnan(VL1(i)))
							set(axC,'Xlim',real(VL1(i))+[-.5 .5]*dx	...
								,'Ylim',imag(VL1(i))/VLDy+[-.5 .5]*dy	...
								)
						end
					case 't'	% toon punt
						ShowPt(S,i)
					case 27		% ESC - automatic axes in XY-graph
						set(S.VLa,'XLimMode','auto','YLimMode','auto')
						axis(S.VLa,'equal')	% otherwise it might look ugly
					case 'x'
						fprintf('Active point: %d\n',i)
						LOGidx = getappdata(S.fvast,'LOGidx');
						LOGidx(1,end+1) = i;
						setappdata(S.fvast,'LOGidx',LOGidx)
					case 'X'
						xl = [min(S.lvast.XData),max(S.lvast.XData)];
						yl = [min(S.lvast.YData),max(S.lvast.YData)];
						SetAxisLimits(S.VLa,xl,yl);
					case 12	% ctrl-L
						volglijn('ShowZoomed')
					case 16	% ctrl-P - set marker 1
						SetMarker('marker1',i,S)
					case 17 % ctrl-Q - set marker 2
						SetMarker('marker2',i,S)
					case 18	% ctrl-R - reset pointer lines
							% similer to 'L' (but different)!!!!
						set(VLl,'Visible','off')
						for i=1:length(VLl)
							X=getsigs(get(VLl(i),'Parent'));
							if isnumeric(X)
								X={X};
							end
							mnX=Inf;
							mxX=-Inf;
							for j=1:length(X)
								X{j}=X{j}(X{j}(:,3)>0,2);
								if ~isempty(X{j})
									mnX=min(mnX,min(X{j}));
									mxX=max(mxX,max(X{j}));
								end
							end
							if ~isinf(mnX)
								if mnX==mxX
									if mnX==0
										mnX=-1;
										mxX=1;
									else
										mnX=mnX*.9;
										mxX=mxX*1.1;
									end
								end
								set(VLl(i),'YData',[mnX mxX])
							end
						end
						set(VLl,'Visible','on')
					case 'a'
						set(S.lvar,'Marker','x');
						set(S.lvast,'Marker','x');
					case 'A'
						set(S.lvar,'Marker','none');
						set(S.lvast,'Marker','none');
					case 'Z'
						volglijn('MatchZoom')
					case 'f1'
						CR=newline;
							helpS=['keycodes:',CR,	...
								'" ","n","1" : next point',CR,	...
								'"2","3","4" : forward - increasing step size',CR,	...
								'"p","9" : previous point',CR,	...
								'"8","7","6" : back - increasing step size',CR,	...
								'"0" : first point (start)',CR,	...
								'"e" : last point (end)',CR,	...
								'"I" : zoom in (XY-plot)',CR,	...
								'"O" : zoom out (XY-plot)',CR,	...
								'"i" : zoom in (T-plot)',CR,	...
								'"o" : zoom out (T-plot)',CR,	...
								'<arrows> : scroll in XY-plot',CR,	...
								'"a" : show points on lines',CR,	...
								'"A" : hide points on lines',CR,	...
								'"x" : show index of current point',CR,	...
								'"L" : remake marker lines',CR,	...
								'"M" : show/toggle logged points',CR	...
								'"S" : stop following',CR,	...
								'"R" : restart following',CR,	...
								'"v" : start/stop keeping marker in the middle'	...
								'"X" : full measurement view',CR,	...
								'"Z" : zoom to zoomed parts in T-plots',CR,	...
								'"ctrl-P": mark point 1',CR,	...
								'"ctrl-Q": mark point 2',CR,	...
								'"ctrl-R": reset pointer lines (similar to "L")',CR,	...
								'"ctrl-L": plot(/toggle) line of zoomed parts in T-plots',CR,	...
								];
							helpdlg(helpS,'VolgLijn-help')
					otherwise
						funKey=getappdata(S.fvast,'funKey');
						if ~isempty(funKey)
							funKey(S,c)
						end
				end
			case 'setkeyfun'
				setappdata(S.fvast,'funKey',lvast)
			case 'getlog'
				LOGidx = getappdata(S.fvast,'LOGidx');
				LOG = struct('idx',LOGidx	...
					,'t',S.VLvx(LOGidx)	...
					,'X',S.lvast.XData(LOGidx),'Y',S.lvast.YData(LOGidx)	...
					);
				varargout = {LOG};
			case 'addlogpts'
				LOGidx = getappdata(S.fvast,'LOGidx');
				lLOGmarkers = findobj([S.fvast;S.fvar(:)],'Type','line','Tag','LOGmarker');
				if ~isempty(lLOGmarkers)
					delete(lLOGmarkers)
				else
					L = [S.lvast;S.lvar(:)];
					for i=1:length(L)
						line(ancestor(L(i),'axes'),L(i).XData(LOGidx),L(i).YData(LOGidx)	...
							,'Color',[0 1 0],'Marker','o','Linestyle','none'	...
							,'Tag','LOGmarker'	...
							)
					end
				end
			case 'matchzoom'	% match zoom of XY-plot with zoomed part in T-plots
				xl = S.lvar(1).Parent.XLim;
				B = S.lvar(1).XData>=xl(1) & S.lvar(1).XData<=xl(2);
				Xmin = min(S.lvast.XData(B));
				Xmax = max(S.lvast.XData(B));
				Ymin = min(S.lvast.YData(B));
				Ymax = max(S.lvast.YData(B));
				SetAxisLimits(S.VLa,[Xmin,Xmax],[Ymin,Ymax]);
			case 'showzoomed'	% plot part shown in T-plots
				l = findobj(S.VLa,'Tag','partPlot');
				if isempty(l)
					xl = S.lvar(1).Parent.XLim;
					B = S.lvar(1).XData>=xl(1) & S.lvar(1).XData<=xl(2);
					X = S.lvast.XData(B);
					Y = S.lvast.YData(B);
					line(S.VLa,X,Y,'Color',[0 1 0],'Tag','partPlot','LineWidth',2)
					for i=1:length(S.fvar)
						navfig(S.fvar(i),'AddUpdateAxes',@UpdateZoomedPart)
							% (!!!!) What if already added?!!!
					end
				else
					%set(l,'XData',X,'YData',Y)
					delete(l)
				end
			case 'getmarkeddata'
				i1 = getappdata(S.fvast,'marker1');
				i2 = getappdata(S.fvast,'marker2');
				if isempty(i1) || isempty(i2)
					error('Sorry, but this function only works if start&stop markers are created! (use ctrl-P and ctrl-P)')
				end
				ii = i1:i2;
				t = S.VLvx(ii)';
				X = S.lvast.XData(ii)';
				Y = S.lvast.YData(ii)';
				varargout = {var2struct(i1,i2,t,X,Y),S};
		end
	else
		if isempty(S)
			warning('VOLGLIJN:NotEnoughData','Gebruik van volglijn zonder de nodige data')
			return
		end
		p=get(VLa,'CurrentPoint');
		[~,i]=min(abs(VL1(:)-(p(1,1)+p(1,2)*1i*VLDy)));
		if isempty(i)
			i=1;	% breakpoint setting
		elseif i>length(VLvx)
			i=rem(i-1,size(VL1,1))+1;
			upd_lijn=true;
		else
			upd_lijn=true;
		end
	end
	if upd_lijn
		set(VLl,'XData',VLx+VLvx(i));
		set(VLcurl,'XData',real(VL1(i,:)),'YData',imag(VL1(i,:))/VLDy)
		setappdata(VLl(1),'VL_i',i)
		if bVolg
			a=get(VLl,'Parent');
			if iscell(a)
				aa=unique(cat(1,a{:}));
			else
				aa=unique(a);
			end
			if isempty(dxl)
				xl=get(aa(1),'xlim');
				dxl=diff(xl)/2;
			end
			xl=[-1 1]*dxl+VLvx(i);
			bLimAxes=true;
			if ~CheckPt(S,i)
				ShowPt(S,i)
			end
		end
		fUpdate=getappdata(f,'volglijn_fUpdate');
		if bCallUpdateFcn && ~isempty(fUpdate)
			if ~isa(fUpdate,'function_handle')
				error('Wrong use of the update-functionality!')
			end
			fUpdate(f,i,[real(VL1(i,:)),imag(VL1(i,:))/VLDy])
		end
	end
	if bLimAxes
		a=get(VLl,'Parent');	% ! is dubbel gedaan!!
		if iscell(a)
			aa=unique(cat(1,a{:}));
		else
			aa=unique(a);
		end
		lLink=getappdata(f,'VL_AXlink');
		if ~isempty(lLink)
			aa=[aa;lLink(:)];
		end
		set(aa,'XLim',xl);
		for i=1:length(aa)
			fUpdate = getappdata(aa(i),'updateAxes');
			if ~isempty(fUpdate)&&isa(fUpdate,'function_handle')
				fUpdate(aa(i))
			end
		end		% for i
	end		% if bLimAxes
	
catch err
	f=lastVLfvast;
	lastVLfvast=[];
	DispErr(err)
	if ~isempty(f)&&~isempty(S)
		warning('VOLGLIJN:Error','Volglijn gestopt omwille van errors (?sluiten van venster?)')
		volglijn clearall
	else
		if ~strcmp(get(gcf,'BeingDeleted'),'on')
			warning('VOLGLIJN:ErrorBijStoppen','!!error bij stoppen???!!')
		end
	end
end

function OK=CheckPt(S,i)
axC=get(S.VLcurl,'parent');
xlC=get(axC,'Xlim');
ylC=get(axC,'Ylim');
x=real(S.VL1(i));
y=imag(S.VL1(i))/S.VLDy;
OK=x>=xlC(1)&&x<=xlC(2)&&y>=ylC(1)&&y<=ylC(2);

function ShowPt(S,i)
if ~isnan(S.VL1(i))
	axC=get(S.VLcurl,'parent');
	xlC=get(axC,'Xlim');
	ylC=get(axC,'Ylim');
	set(axC,'Xlim',xlC-mean(xlC)+real(S.VL1(i))	...
		,'Ylim',ylC-mean(ylC)+imag(S.VL1(i))/S.VLDy	...
		)
	fUpdate = getappdata(axC,'updateAxes');
	if ~isempty(fUpdate)&&isa(fUpdate,'function_handle')
		fUpdate(axC)
	end
end

function PtSelectedT(h,~)
ax=ancestor(h,'axes');
pt=get(ax,'CurrentPoint');
fVar=ancestor(ax,'figure');
fVast=getappdata(fVar,'VL_fvar');
X=get(h,'XData');
[~,i]=min(abs(X-pt(1)));
figure(fVast);
volglijn('setPt',i)

function l=FindLines(ax,nMin,nExact)
l=[findobj(ax,'type','line');findobj(ax,'type','stair')];
if nargin>1
	N=zeros(1,length(l));
	for i=1:length(l)
		N(i)=length(get(l(i),'xdata'));
	end
	if ~isempty(nMin)
		B=N>=nMin;
		if ~all(B)
			l=l(B);
			N=N(B);
		end
	end
	if nargin>2&&~isempty(nExact)
		B=N==nExact;
		if ~all(B)
			l=l(B);
		end
	end
end		% minimum or exact size requested

function [xl,yl] = SetAxisLimits(ax,xl,yl)
xl0 = get(ax,'XLim');
yl0 = get(ax,'YLim');
if diff(xl)==0
	xl = xl0+mean(xl)-mean(xl0);
end
if diff(yl)==0
	yl = yl0+mean(yl)-mean(yl0);
end
yRatio0 = diff(yl0)/diff(xl0);
yRatio = diff(yl)/diff(xl);
if yRatio>yRatio0
	xl = (xl0-mean(xl0))*diff(yl)/diff(yl0)+mean(xl);
elseif yRatio<yRatio0
	yl = (yl0-mean(yl0))*diff(xl)/diff(xl0)+mean(yl);
end
axis(ax,[xl,yl])

function SetMarker(sTag,iMarker,S)
lMarker = findobj([S.fvast;S.fvar(:)],'Tag',sTag);
if ~isempty(lMarker)
	if lMarker(1).UserData.i==iMarker
		delete(lMarker)
		return
	end
end
t = S.VLvx(iMarker);
setappdata(S.fvast,sTag,iMarker)
if isempty(lMarker)
	if strcmp(sTag,'marker1')
		c = [0 1 0];
	elseif strcmp(sTag,'marker2')
		c = [1 0 1];
	else	% no use (yet)
		c = [0 1 1];
	end
	line(S.VLa,S.VLcurl.XData,S.VLcurl.YData	...
		,'Marker','x','Tag',sTag,'Color',c	...
		,'UserData',struct('i',iMarker,'type','XY'))
	St = struct('i',iMarker,'type','t');
	for i=1:length(S.VLl)
		l = S.VLl(i);
		if isnumeric(l)
			l = handle(l);
		end
		line(l.Parent,l.XData,l.YData,'Tag',sTag,'UserData',St,'Color',c)
	end
else
	for i=1:length(lMarker)
		switch lMarker(i).UserData.type
			case 'XY'
				lMarker(i).XData = S.lvast.XData(iMarker);
				lMarker(i).YData = S.lvast.YData(iMarker);
			case 't'
				lMarker(i).XData(:) = t;
		end
		lMarker(i).UserData.i = iMarker;
	end
end
if t>=720000 && t<=750000
	st = datestr(t);
else
	st = num2str(t);
end
fprintf('Set %s: #%4d - %s\n',sTag,iMarker,st)

function UpdateZoomedPart(ax)
fT = ancestor(ax,'figure');
f = getappdata(fT,'VL_fvar');
S = getappdata(f,'volglijn_fvast');
l = findobj(S.VLa,'Tag','partPlot');
if ~isempty(l)
	xl = S.lvar(1).Parent.XLim;
	B = S.lvar(1).XData>=xl(1) & S.lvar(1).XData<=xl(2);
	X = S.lvast.XData(B);
	Y = S.lvast.YData(B);
	set(l,'XData',X,'YData',Y)
end
