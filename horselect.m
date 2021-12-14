function [out,axLim,selTyp]=horselect(varargin)
% horselect - Horizontal selection routine
%    Lets a user select a part in a graph.  The indices of the longest line
%    in that axes the are between the given selection is replied.
%
%    horselect         : switches on and off this functionality
%    horselect var <varname> : puts the indices in a variable (in base
%                              workspace)
%    i=horselect       : waits for user input, and gives the indices as output

% Stijn Helsen - FMTC - 2007

f=gcf;
BD=get(f,'WindowButtonDownFcn');
if nargout
	set(f,'WindowButtonDownFcn',@ZoomStart)
	setappdata(f,'horSelectWait',1)
	bSelTyp=nargout>2;
	if bSelTyp
		setappdata(f,'horSelectUseSelTyp',true)
	end
	uiwait(f)
	if bSelTyp
		rmappdata(f,'horSelectUseSelTyp')
	end
	set(f,'WindowButtonDownFcn',BD);
	out=getappdata(f,'horSelectLastI');
	setappdata(f,'horSelectWait','')
	if nargout>1
		axLim=getappdata(f,'horSelectXsel');
		if bSelTyp
			selTyp=getappdata(f,'horSelectSelTyp');
		end
	end
	return
elseif isequal(BD,@ZoomStart)&&nargin==0
	BD=getappdata(f,'horSelectBDF');
	set(f,'WindowButtonDownFcn',BD);
	setappdata(f,'horSelectVar','')
	setappdata(f,'horSelectWait','')
else
	setappdata(f,'horSelectBDF',BD);
	set(f,'WindowButtonDownFcn',@ZoomStart)
end

if nargin
	for i=1:2:length(varargin)
		switch varargin{i}
			case 'var'
				setappdata(f,'horSelectVar',varargin{i+1})
		end
	end
end

function ZoomStart(h,ev)
ax=gca;
f=get(ax,'Parent');
tp=get(f,'SelectionType');
setappdata(f,'horSelectSelTyp',tp);
p=get(ax,'CurrentPoint');
Xl=get(ax,'Xlim');
Yl=get(ax,'Ylim');
if p(1)<Xl(1)||p(1)>Xl(2)||p(1,2)<Yl(1)||p(1,2)>Yl(2)
	return
end
if ~strcmp(tp,'normal')
	bSelTyp=getappdata(f,'horSelectUseSelTyp');
	if strcmp(tp,'open')
		l=findobj(ax,'-property','XData');
		if isempty(l)
			return
		end
		x=[+inf -inf];
		for i=1:length(l)
			x1=get(l(i),'XData');
			x(1)=min(x(1),min(x1(:)));
			x(2)=max(x(2),max(x1(:)));
		end
		EndZoom(f,x,false)
	elseif bSelTyp
		x=get(gca,'XLim');
		EndZoom(f,x,true)
	end
	return
end
l=line(p(ones(1,6)),mean(Yl)+[-1 1 0 0 -1 1]*0.5*diff(Yl)    ...
	,'EraseMode','xor'  ...
	,'LineStyle','--'   ...
	,'Color',[0 0 0]    ...
	);
D=struct('l',l  ...
	,'motionFcn',get(f,'WindowButtonMotionFcn') ...
	,'upFcn',get(f,'WindowButtonUpFcn') ...
	);
setappdata(f,'HorZoom',D)
set(f,'WindowButtonMotionFcn',@MovePt   ...
	,'WindowButtonUpFcn',@StopZoom  ...
	);

function MovePt(h,ev)
f=gcf;
D=getappdata(f,'HorZoom');
x=get(D.l,'XData');
pt=get(gca,'CurrentPoint');
x(4:6)=pt(1);
set(D.l,'XData',x)

function StopZoom(h,ev)
f=gcf;
D=getappdata(f,'HorZoom');
x=get(D.l,'XData');
set(f,'WindowButtonMotionFcn',D.motionFcn   ...
	,'WindowButtonUpFcn',D.upFcn    ...
	);
delete(D.l)
EndZoom(f,x([2 5]),false)

function EndZoom(f,xlim,bForceStop)
xlim=sort(xlim);
l=findobj(gca,'type','line');
if isempty(l)
	error('geen lijn gevonden in huidige as')
end
i=[];
for i=1:length(l)
	X=get(l(i),'xdata');
	i1=find(X>=xlim(1)&X<=xlim(2));
	if length(i1)>length(i)
		i=i1;
		if length(i)>2
			break;
		end
	end
end
setappdata(f,'horSelectXsel',xlim)
if length(i)>1||bForceStop
	setappdata(f,'horSelectLastI',i)
	w=getappdata(f,'horSelectWait');
	if ~isempty(w)
		uiresume(gcf)
	else
		var=getappdata(f,'horSelectVar');
		if isempty(var)
			fprintf('%d:%d\n',i([1 end]))
		else
			fprintf('%d:%d (set in %s)\n',i([1 end]),var)
			assignin('base',var,i)
		end
	end
end
