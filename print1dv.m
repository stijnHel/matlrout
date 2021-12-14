function print1(f,n)
% PRINT1 - print 1 figuur
%    print(f,n)
%  f : figuur handle
%  

if ~exist('f');f=[];end
if ~exist('n');n=[];end
if isempty(f)
       f=gcf;
elseif length(f)>1
       disp('Er mag slechts een figuur in printn ingegeven worden.')
       disp('Gebruik printn in de plaats')
       f=f(1);
end
reedsGesaved=0;
if isempty(n)
       n=1;
elseif n==0
       return
elseif n==-1
       figure
       set(gcf       ...
              , 'MenuBar', 'none'  ...
              , 'NumberTitle', 'off'      ...
              , 'Name', 'Printscherm'     ...
              , 'Position', [232,288,450,100]    ...
              , 'Resize', 'off'    ...
              );
       uicontrol('Style','pushbutton'     ...
              , 'String','Print'   ...
              , 'Callback',sprintf('print1(%d,-2)',f)   ...
              , 'Position', [340 20 80 20]       ...
              );
       uicontrol('Style','text'    ...
              , 'String','Hoeveel exemplaren ?'  ...
              , 'Position', [10 20 140 20]       ...
              , 'HorizontalAlignment', 'right'   ...
              );
       uicH=uicontrol('Style','edit'      ...
              , 'String','1'       ...
              , 'UserData',1       ...
              , 'Position', [160 20 100 20]      ...
              , 'HorizontalAlignment', 'left'    ...
              );
       set(gcf       ...
              , 'UserData', uicH   ...
              );
       if isunix
              eval(sprintf('print -f%d -dcdjcolor ttt.jet', f));
       end
       return
elseif n==-2
       if strcmp(get(gcf,'Name'),'Printscherm')
              uicH=get(gcf,'UserData');
              n=str2num(get(uicH,'String'));
              close(gcf);
       else
              errordlg('Er loopt iets fout met het printen.');
              return;
       end
       reedsGesaved=1;
end
if n<1
       return
end
if isunix
       if ~reedsGesaved
              eval(sprintf('print -f%d -dcdjcolor ttt.jet', f));
       end
       for i=1:n
              !lp -ddjcolor ttt.jet
       end
elseif strcmp(computer, 'PCWIN')
       if n>1
%             eval(sprintf('print -f%d -dwinc -v', f));
              for i=1:n
%                    dos('copy tttttt.ps lpt1|');
                     eval(sprintf('print -f%d -dwin', f));
              end
       else
              eval(sprintf('print -f%d -dwin', f));
       end
end