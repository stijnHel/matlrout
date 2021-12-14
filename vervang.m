function l=vervang(e,x,fb)
% VERVANG - laat toe grafieken te vernieuwen door nieuwere metingen.
%   vervang clear    : clear alle veranderde opties
%   vervang ok              : zet het selecteren van de kanalen af
%   vervang toon     : toon/toon niet de geselecteerde kanalen
%   vervang undelete : undelete de verwijderde lijnen


%!!!! userdata van popup en "pd" kan bij elkaar gezet worden.
global VERVANGlijnen VERVANGoffsets
if ~exist('e');help vervang;return;end
if ~exist('fb');fb=[];end
if isempty(fb)
       lijnen=findobj('Type','line');
else
       lijnen=findobj(fb,'Type','line');
end
ff=findobj('Type','figure','Name','Selectie van te vervangen kanalen');
if ~isempty(ff)
       pPopup=findobj(ff,'Type','uicontrol','Style','popupmenu');
       VERVANGstring=get(pPopup,'String');
end
if nargout>0
       l=lijnen;
end
if isstr(e)
       if strcmp(e,'clear')
              set(lijnen,'UserData',[],'ButtonDownFcn','1;');
       elseif strcmp(e,'ok')
              set(lijnen,'ButtonDownFcn','1;');
              lijnen=findobj('Type','line','Visible','off');
              clear VERVANGlijnen
              if isempty(ff)
                     error('selectiefiguur is weggehaald')
              end
              pd=get(ff,'UserData');
              y=get(pd,'UserData');
              if y
                     c=get(pPopup,'UserData');
                     if length(c)>=4
                            set(y,'Color',c(1:3),'LineWidth',c(4));
                     end
              end
              close(ff);
       elseif strcmp(e,'undelete')
              p=findobj('Type','line','Visible','off');
              set(p,'Visible','on')
       elseif min(size(e))>1
              VERVANGlijnen=lijnen;
              for i=1:length(lijnen)
                     if length(get(lijnen(i),'XData'))>10
                            set(lijnen(i),'ButtonDownFcn',sprintf('vervang(''lijn'',%d);',i));
                     end
              end
              close(ff)
              ff=figure;
              set(ff,'Name','Selectie van te vervangen kanalen'       ...
                     ,'MenuBar','none'    ...
                     ,'NumberTitle','off');
              pPopup=uicontrol('Style','popupmenu'    ...
                     ,'String',e   ...
                     ,'Position',[20 40 200 30]  ...
                     ,'Value',0    ...
                     ,'CallBack','vervang(''lijn'');');
              uicontrol('Style','pushbutton'     ...
                     ,'String','Clear'    ...
                     ,'Position',[250 40 100 30] ...
                     ,'CallBack','vervang(''clear'');');
              uicontrol('Style','pushbutton'     ...
                     ,'String','Klaar'    ...
                     ,'Position',[250 80 100 30] ...
                     ,'CallBack','vervang(''ok'');');
              pd=uicontrol('Style','pushbutton'  ...
                     ,'String','Verwijder'       ...
                     ,'Position',[250 120 100 30]       ...
                     ,'CallBack','vervang(''lijn'',0);' ...
                     ,'Visible','off'     ...
                     ,'UserData',0);
              uicontrol('Style','pushbutton'  ...
                     ,'String','Undelete' ...
                     ,'Position',[250 160 100 30]       ...
                     ,'CallBack','vervang(''undelete'');'      ...
                     ,'Visible','off'     ...
                     ,'UserData',0);
              set(ff,'UserData',pd);
              nKan=size(e,1);
              VERVANGoffsets=zeros(nKan,1);
              if exist('x')
                     set(pPopup,'UserData',[]);
                     for i=1:length(lijnen)
                            mm=get(lijnen(i),'YData');
                            mm=mm(:);
                            if length(mm)==size(x,1)
                                   s=std(x-mm*ones(1,nKan));
                                   [mn,j]=min(s);
                                   if mn<0.001
                                          set(pd,'UserData',lijnen(i));
                                          set(pPopup,'Value',j);
                                          vervang('lijn');
                                   end
                                   fprintf('lijn van kanaal %d (%s) wordt klaargezet voor vervanging.\n',j,deblank(e(j,:)));
                                   VERVANGoffsets(j)=mean(mm-x(:,j));
                            end
                     end
              end
       elseif strcmp(e,'lijn')
              if isempty(ff)
                     error('selectiefiguur is weggehaald')
              end
              pd=get(ff,'UserData');
              y=get(pd,'UserData');
              if y
                     c=get(pPopup,'UserData');
                     if length(c)>=4
                            set(y,'Color',c(1:3),'LineWidth',c(4));
                            drawnow;
                     end
              else
                     error('Ik weet niet welk lijn vervangen moet worden !!');
              end
              if nargin>1
                     if x==0
                            set(y,'Visible','off');
                            p=findobj('Type','uicontrol','String','Undelete');
                            set(p,'Visible','on');
                            return
                     end
                     set(pd,'UserData',VERVANGlijnen(x));
                     c=get(VERVANGlijnen(x),'Color');
                     w=get(VERVANGlijnen(x),'LineWidth');
                     v=get(VERVANGlijnen(x),'UserData');
                     if isempty(v)
                            v=0;
                     else
                            v=str2num(v(2));
                     end
                     set(pPopup,'UserData',[c w],'Value',v);
                     set(VERVANGlijnen(x),'Color',[1 0 0],'LineWidth',2);
                     drawnow;
                     set(pd,'Visible','on')
                     figure(ff)
              else
                     set(y,'UserData',['E' num2str(get(pPopup,'Value'))]);
              end
       else
              help vervang
       end
       return
end
if length(e)==1
       e=leeseven(e);
       if isempty(e)
              error('Geen meting gevonden')
       end
end
x=0;
vervangen=[];
for i=1:length(lijnen)
       u=get(lijnen(i),'UserData');
       if ~isempty(u)
              vervangen=[vervangen i];
              j=str2num(u(2));
              set(lijnen(i),'YData',e(:,j)+VERVANGoffsets(j));
       end
end
if isempty(vervangen)
       disp('Er is niets vervangen')
       disp('Voor het selecteren van lijnen, gebruik vervang(ne).');
else
       drawnow
end
