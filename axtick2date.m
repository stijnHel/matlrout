function [varargout]=axtick2date(ax,axType,varargin)
%axtick2date - Set X-ticks to dates (or Y/Z-ticks)
%    axtick2date - axes on current figure
%    axtick2date(hAxes)
%    axtick2date(hFigure)
%    axtick2date(hAxes/hFigure,'X'/'Y'/'Z')
%            Z added, but only really practical for normal (XY)2Dplots
%    axtick2date([<figure/ax>,]'timeformat',<timeformat>) forces a specific timeformat
%            possible values: see Tim2MLtime
%    axtick2date([<figure/ax>,]'stop') removes "time-ticks"
%    axtick2date([<figure/ax>,]'changeTformat',<timeformat>)
%           changes axes (including X)
%
% see also Tim2MLtime

% in fact hAx and axType can be given in any order.

% voorstel:
%     maak het mogelijk om "dxDefault" in te stellen
%         bijv. om per week te tonen, en misschien met een offset (om ticks
%            op een bepaalde dag te hebben)
%         dit kan dan niet zo moeilijk uitgebreid worden naar
%              ticks in begin maand / jaar

opts=varargin;
if nargin==0
	ax=gcf;
	axType='X';
else
	if ischar(ax)
		if nargin==1
			axType=ax;
			ax=gcf;
		elseif isnumeric(axType)	% switch ax and axType
			t=ax;
			ax=axType;
			axType=t;
		else
			opts=[{axType} opts];
			axType=ax;
			ax=gcf;
		end
	elseif nargin==1
		axType='X';
	end
end
ax=GetNormalAxes(ax);
nStringTest=max(length(axType),2);
if strcmpi(axType,'stop')
	for i=1:length(ax)
		if isappdata(ax(i),'TIMEFORMAT')
			rmappdata(ax(i),'TIMEFORMAT')
		end
	end
	set(ax,'XTickMode','auto','XTickLabelMode','auto'	...
		,'YTickMode','auto','YTickLabelMode','auto')
	return
elseif strncmpi(axType,'timeformat',nStringTest)
	% axType could be stored too...
	if isempty(opts)
		fprintf('Possible values for timeformat: excel,winSeconds,julianday,base...\n')
	else
		tForm=opts{1};
		if strcmpi(tForm,'auto')
			tForm=[];
		elseif strcmpi(tForm,'base')||strcmpi(tForm,'sec')
			if length(opts)<2
				error('With base or sec a time value must be given!')
			end
			t0=opts{2};
			tVec=datevec(t0);
			tForm=sprintf('%s%04d%02d%02d%02d%02d%02.0f',tForm,tVec);
			if tVec(6)>floor(tVec(6))
				sT=sprintf('%8.6f',tVec(6)-floor(tVec(6)));
				tForm=[tForm sT(2:end)];
			end
		end
		for i=1:length(ax)
			setappdata(ax(i),'TIMEFORMAT',tForm)
		end
	end
	return
elseif strncmpi(axType,'changeTformat',nStringTest)
	% (!)Works only for X-axis
	if isempty(opts)||(ischar(opts{1})&&strcmpi(opts{1},'auto'))
		xl=get(ax(1),'Xlim');
		[tScale,tOffset]=Tim2MLtime(getappdata(ax(1),'TIMEFORMAT'),xl(1));
		if tScale==1
			newTform='base';
		else
			newTform='sec';
		end
		tOffset=tOffset+xl(1);
		d=datevec(tOffset/tScale);
		newTform=[newTform sprintf('%04d%02d%02d%02d%02d%02.0f',d)];
	else
		newTform=opts{1};
	end
	for i=1:length(ax)
		tForm=getappdata(ax(i),'TIMEFORMAT');
		if ~isequal(tForm,newTform)
			xl=get(ax(i),'xlim');
			[tScaleNew,tOffsetNew]=Tim2MLtime(newTform,xl(1));
				% in loop because xl can change(!)
			[tScale,tOffset]=Tim2MLtime(tForm,xl(1));
			l=get(ax(i),'Children');
			for j=1:length(l)
				if any(strcmp(get(l(j),'Type'),{'line','patch','text'}))
					X=get(l(j),'XData');
					X=(X/tScale+(tOffset-tOffsetNew))*tScaleNew;
					set(l(j),'XData',X)
				end
			end
			setappdata(ax(i),'TIMEFORMAT',newTform)
			xl=(xl/tScale+(tOffset-tOffsetNew))*tScaleNew;
			xlim(ax(i),xl)
		end
	end
	axtick2date(ax)
	return
elseif strncmpi(axType,'convert',nStringTest)
	t=varargin{1};
	[tScale,tOffset]=GetTimeScale(ax,t);
	t=t/tScale+tOffset;
	if nargout
		varargout={t};
	else
		disp(datestr(t));
	end
	return
elseif strncmpi(axType,'getXLim',nStringTest)
	% Was this started and stopped - and forgotten what the goal was?
	xl=get(ax(1),'XLim');
	return
end	
axUnits=get(ax(1),'Units');
set(ax(1),'Units','pixels')
axP=get(ax(1),'Position');	%!!!optimize only for one axes!!!!
switch upper(axType)
	case 'X'
		sXLim='XLim';
		sXtickMode='XTickMode';
		sXtickLMode='XTickLabelMode';
		sXtick='XTick';
		sXtickL='XTickLabel';
		W=axP(3);
	case 'Y'
		sXLim='YLim';
		sXtickMode='YTickMode';
		sXtickLMode='YTickLabelMode';
		sXtick='yTick';
		sXtickL='YTickLabel';
		W=axP(4);
		W1=30;
	case 'Z'
		sXLim='ZLim';
		sXtickMode='ZTickMode';
		sXtickLMode='ZTickLabelMode';
		sXtick='ZTick';
		sXtickL='ZTicklabel';
		W=500;	% !!fixed
		W1=60;
	otherwise
		error('Type must be ''X'' or ''Y'' or ''Z''!')
end
xl=get(ax(1),sXLim);
set(ax(1),'Units',axUnits);

[tScale,tOffset]=GetTimeScale(ax,xl);
xl=xl/tScale;
bTime=diff(xl)<3;
if bTime
	t0=floor(xl(1)+tOffset);
	posSteps=[[100 50 25 20 10 5 2 1]*24	... (!no time!) added for
		12 8 6 4 3 2 1 0.5 0.25 [5 2 1]/60,	... small axes (low number of ticks)
		[30 10 5 2 1 0.5 0.2 0.1 0.05 0.02 0.01]/3600]/24;
else
	t0=xl(1)+tOffset;
	dd0=datevec(t0);
	dd0(2:end)=0;
	t0=datenum(dd0);
	posSteps=[[100 50 20 10 5 2 1]*36525, ... for plots over many years
		29220 14610 7305 3652.5 2922 1826.25 1461 730.5,	...
		365.25 100 50 25 20 10 5 2 1];
end
if upper(axType)=='X'
	if diff(xl)>366
		W1=100;	% with year
	else
		W1=60;
	end
end
nMax=max(2,W/W1);
nSteps=diff(xl)./posSteps;
i=find(nSteps<=nMax,1,'last');
if isempty(i)
	set(ax,sXtickMode,'auto',sXtickLMode,'auto')
	return
end
tStep=posSteps(i);
if bTime
	% prevent too large td-vector
	if tStep<1/24
		fT0=round(1/tStep);
		t0=floor((xl(1)+tOffset)*fT0)/fT0;
	end
end
xd=t0:tStep:xl(end)+tOffset;
xd(xd<xl(1)+tOffset)=[];
if isempty(xd)	% possible with very small limits
	xd=xl+tOffset;
end
xtl=cell(1,length(xd));
dd=datevec(xd(1));
yr=dd(1);
f=1/tStep;
if diff(xl)>370
	yr=yr-1;	% force start with year
end
for i=1:length(xd)
	dd=datevec(xd(i));
	if dd(1)<0||dd(1)>2600
		warning('AXTICK2DATE:BadDate'	...
			,'Onverwachte datum (%04d-%02d-%02d) - geen aanpassing van axtick'	...
			,dd(1),dd(2),dd(3))
		if isappdata(ax,'TIMEFORMAT')
			rmappdata(ax,'TIMEFORMAT')
		end
		break;
	end
	if bTime
		if abs(xd(i)-round(xd(i)))<1e-7
			xtl{i}=sprintf('%d/%d',dd([3 2]));
		elseif f<=1440
			xtl{i}=sprintf('%d:%02d',dd([4 5]));
		elseif f<=86401
			xtl{i}=sprintf('%d:%02d:%02d',dd([4 5 6]));
		else
			xtl{i}=sprintf('%02d:%05.2f',dd([5 6]));
		end
	elseif dd(1)>yr
		xtl{i}=sprintf('%d/%d/%d',dd([3 2 1]));
		yr=dd(1);
	else
		xtl{i}=sprintf('%d/%d',dd([3 2]));
	end
end

set(ax,sXtick,(xd-tOffset)*tScale,sXtickL,xtl)

function [tScale,tOffset]=GetTimeScale(ax,xl)
timeFormat=getappdata(ax(1),'TIMEFORMAT');
if isempty(timeFormat)
	[~,timeFormat]=Tim2MLtime(xl(1));
	for i=1:length(ax)
		setappdata(ax(i),'TIMEFORMAT',timeFormat)
	end
elseif ~ischar(timeFormat)
	error('Unknown fixed time-format!')
end
[tScale,tOffset]=Tim2MLtime(timeFormat,xl(1));
