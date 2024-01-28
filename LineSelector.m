function LineSelector(varargin)
%LineSelector - Configures the reaction to highlight lines when clicked

%issues
%   * double click on line doesn't work easily
%   * double click and alt click don't work on legend

%works in action
%     adding possibility to add
%          double-click (open) and alt-click actions
%          contextmenu
%     difficulty - find the right clicked items
%           (just using axes-children might not be reliable(?))
%
%   ideas:

options = varargin;
if nargin && ~isempty(varargin{1}) && isscalar(varargin{1}) && ishandle(varargin{1})
	f = varargin{1};
	options(1) = [];
else
	f = gcf;
end
fcnOpen = [];
fcnAlt = [];
mnContext = [];
[bAdd] = false;
[bWarnLinethickness] = true;

if ~isempty(options)
	setoptions({'fcnOpen','fcnAlt','mnContext','bAdd','bWarnLinethickness'},options{:})
end

if ~isempty(fcnOpen)
	setappdata(f,'LSC_Open',fcnOpen)
end
if ~isempty(fcnAlt)
	setappdata(f,'LSC_Alt',fcnAlt)
end
if bAdd
	return
end

l = findobj(f,'Type','line');
set(l,'ButtonDownFcn',@LineClicked)
if ~isempty(mnContext)
	set(l,'UIcontextMenu',mnContext)
end
W = get(l,'LineWidth');
if ~iscell(W)
	W = {W};
end
W = [W{:}];
if all(W==W(1))
	Wnormal = W(1);
	Wsel = max(1,Wnormal)*2;
else
	if bWarnLinethickness
		warning('Not all lines with the same width to start?!')
	end
	Wnormal = min(W);
	Wsel = max(W);
end
setappdata(f,'Wnormal',Wnormal)
setappdata(f,'Wsel',Wsel)

% Add responses of clicking on legend items
ax = findobj(f,'Type','axes');
for i=1:length(ax)
	axL = getappdata(ax(i),'LayoutPeers');
	if ~isempty(axL) && isa(axL,'matlab.graphics.illustration.Legend')
		set(axL,'ItemHitFcn',@LegendItemClicked)
	end
end

function LineClicked(h,ev)
ax = ancestor(h,'axes');
f = ancestor(ax,'figure');
if isfield(ev,'SelectionType')
	sType = ev.SelectionType;
else
	sType = get(f,'SelectionType');
end
lSel = getappdata(ax,'LineSelected');
if any(lSel==h)&&any(strcmp(sType,{'extend','normal'}))	% deselect
	Unselect(h)
	lSel = setdiff(lSel,h);
	setappdata(ax,'LineSelected',lSel)
else
	fcnCall = [];
	if strcmp(sType,'extend')
		if isempty(lSel)
			lSel = h;
		else
			lSel(end+1) = h;
		end
		Select(h)
	elseif strcmp(sType,'alt')
		fcnCall = getappdata(f,'LSC_Alt');
	elseif strcmp(sType,'open')
		fcnCall = getappdata(f,'LSC_Open');
		if ~any(lSel==h)	% first click of dbl-click probably deselected h
			Select(h)
			lSel(end+1) = h;
		end
	else
		if ~isempty(lSel)
			Unselect(lSel)
		end
		lSel = h;
		Select(h)
	end
	setappdata(ax,'LineSelected',lSel)
	if ~isempty(fcnCall)
		if ischar(fcnCall)
			eval(fcnCall);
		else
			fcnCall(h)
		end
	end
end

function Select(l)
ax = ancestor(l,'axes');
f = ancestor(ax,'figure');
Wsel = getappdata(f,'Wsel');
dName = l.DisplayName;
if ~isempty(dName) && ~startsWith(dName,'\bf{')
	l.DisplayName = ['\bf{',dName,'}'];	%!!!!!!!this doesn't work anymore?!!!
end
set(l,'LineWidth',Wsel)

function Unselect(l)
% In case of "over plotting", it happens that l can refer to non-existing
% objects!
i = 1;
while i<=length(l)
	if ishandle(l(i))
		i = i+1;
	else
		l(i) = [];
	end
end
if isempty(l)
	return
end
ax = ancestor(l(1),'axes');
f = ancestor(ax,'figure');
Wnormal = getappdata(f,'Wnormal');
for i=1:length(l)
	dName = l(i).DisplayName;
	if startsWith(dName,'\bf{')
		l(i).DisplayName = dName(5:end-1);
	end
end
set(l,'LineWidth',Wnormal)

function LegendItemClicked(~,ev)
LineClicked(ev.Peer,ev)
