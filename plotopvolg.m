function plotopvolg(x,A,X)
% PLOTOPVOLG - Plot een lijn uit een matrix met navigatie-mogelijkheden.
%   plotopvolg(x,A[,X])
%      rijen van A worden geplot (plot(x,A(<i>,:)))
%      X geeft waarde, string-lijst of string-array die als extra in xlabel
%        getoond wordt
%   plotopvolg(<i>)
%      geeft i-de lijn
%
% plotopvolg plot aanvankelijk een lijn waarvan de X-data uit de x-input
%     komt, en de Y-data is de eerste rij uit A.  Met navigatie toetsen kan
%     er dan een andere rij uit A geplot worden.
%   Met behulp van X kan er extra informatie gegeven worden (in xlabel)
%     waar

% Keys :
%    Up,Right,' ','n' : next
%    Down,Left,'p'    : previous
%    s,b              : start
%    e                : end
%    c,m              : center
%    d                : copy(/add) to figure (and set navfig) (Duplicate)
%    D                : stop copying to current copy-figure


if nargin>=2
	if ~exist('X','var')
		X=[];
	end
	if length(x)~=size(A,2)
		if length(x)==size(A,1)
			A=A';
		else
			error('Verkeerde combinatie van x en A')
		end
	end
	f=nfigure;
	i=1;
	l=plot(x,A(i,:));grid
	ud=struct('A',A,'i',i,'l',l,'X',[]);
	ud.X=X;	% (voor wanneer X cell-array is)
	setxlabel(ud);
	set(f,'UserData',ud	...
		,'Name',sprintf('PlotOpvolg (%dx%d)',size(A))	...
		,'KeyPressFcn',sprintf('plotopvolg(get(%d,''CurrentCharacter''));',f))
elseif isempty(x)
	i=1;	% breakpoint-setting
else
	f=gcf;
	ud=get(f,'UserData');
	i=ud.i;
	if ischar(x)
		%fprintf('%d ',abs(x));fprintf('\n')
		switch x
			case {29,30,' ','n'}	% right, up
				i=i+1;
			case {28,31,'p'} % left, down
				i=i-1;
			case {'b','s'}
				i=1;
			case 'e'
				i=size(ud.A,1);
			case {'c','m'}
				i=ceil(size(ud.A,1)/2);
			case 'd'
				[fCopy,bN]=getmakefig('POcopy');
				if bN
					set(fCopy,'Name','Copy of PLOTOPVOLG')
					delete(plot(0,0))
					grid
					navfig
				end
				ccc=get(gca,'ColorOrder');
				nLine=length(findobj(gca,'Type','line','Tag','CopyPO'));
				line(get(ud.l,'XData'),get(ud.l,'YData')	...
					,'Color',ccc(rem(nLine,size(ccc,1))+1,:)	...
					,'Tag','CopyPO'	...
					,'UserData',i	...
					);
				figure(f);
			case 'D'
				fCopy=findobj('Type','figure','Tag','POcopy');
				if ~isempty(fCopy)
					set(fCopy,'Tag','','Name','')
				end
			otherwise
		end
	else
		i=x;
	end
	i=max(1,min(size(ud.A,1),i));
	if i~=ud.i
		ud.i=i;
		set(ud.l,'Ydata',ud.A(i,:));
		set(f,'UserData',ud);
		setxlabel(ud);
	end
end

function setxlabel(ud)
if isempty(ud.X)
	xlabel(sprintf('%d/%d',ud.i,size(ud.A,1)))
elseif iscell(ud.X)
	xlabel(sprintf('%d/%d - %s',ud.i,size(ud.A,1),ud.X{ud.i}))
elseif ischar(ud.X)
	xlabel(sprintf('%d/%d - %s',ud.i,size(ud.A,1),ud.X(ud.i,:)))
else
	xlabel(sprintf('%d/%d - %g',ud.i,size(ud.A,1),ud.X(ud.i)))
end
