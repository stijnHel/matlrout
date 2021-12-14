function fUpdate = AddHistLines(lFollow,nHistory,varargin)
%AddHistLines - Add functionality of "history lines" in graph
%     [fUpdate = ]AddHistLines(lFollow,nHistory)
%         Adds the functionality
%             if no output arguments: cnavmsrs functionality is assumed
%             otherwise, fUpdate can be called to update the history lines

if nargin==0 || isempty(lFollow)
	lFollow = findobj(gca,'Type','line');
elseif ischar(lFollow)
	switch lower(lFollow)
		case 'delete'
			l = findobj(gcf,'Tag','historyLine');
			if isempty(l)
				warning('No lines found?!')
			else
				delete(l)
				c = get(gcf,'UserData');
				if ~isempty(c) && isa(c,'cnavmsrs')
					c.SetPostNavFcn([])
				end
			end
		case 'update'
			l = findobj(gcf,'Type','line');
			for i=1:length(l)
				if ~strcmp(l(i).Tag,'historyLine')
					f = getappdata(l(i),'fcnUpdate');
					if ~isempty(f) && isa(f,'function_handle')
						f()
					end
				end
			end
		otherwise
			warning('Command not understood!')
	end
	return
end
if nargin<2 || isempty(nHistory)
	nHistory = 1;
end

if isempty(lFollow)
	error('No lines is given/found?!')
elseif length(lFollow)>1	% this functionality is not tested!!!!!
	fUpdate = cell(1,length(lFollow));
	for i=1:length(lFollow)
		AddHistLines(lFollow(i),nHistory)
	end
	return
end

ax = ancestor(lFollow,'axes');
colors = get(ax,'ColorOrder');
if nargin>2
	setoptions({'colors'},varargin{:})
end
if all(colors(1,:)==get(lFollow,'Color'))
	colors(1,:) = [];
end

Slast = struct('x',lFollow.XData,'y',lFollow.YData);
setappdata(lFollow,'LastData',Slast)

lHistory = lFollow(1,ones(1,nHistory));
for i = 1:nHistory
	lHistory(i) = line(Slast.x,Slast.y,'Color',colors(rem(i-1,size(colors,1))+1,:)	...
		,'Tag','historyLine','Parent',ax);
end
setappdata(lFollow,'lHistory',lHistory)

if nargout>0
	fUpdate = @() Update(lFollow);
	setappdata(lFollow,'fcnUpdate',fUpdate)	% to be used in forced update
else
	c = get(ancestor(lFollow,'figure'),'UserData');
	if isempty(c) || ~isa(c,'cnavmsrs')
		error('This is not a cnavmsrs-figure?!')
	end
	f = @(fig,nr) Update(lFollow);
	c.SetPostNavFcn(f)
	setappdata(lFollow,'fcnUpdate',f)	% to be used in forced update
end

function Update(l)
lFollow = getappdata(l,'lHistory');
SlastNew = struct('x',l.XData,'y',l.YData);
Slast = getappdata(l,'LastData');
for i=length(lFollow):-1:2
	set(lFollow(i),'XData',get(lFollow(i-1),'XData'),'YData',get(lFollow(i-1),'YData'))
end
set(lFollow(1),'XData',Slast.x,'YData',Slast.y)
setappdata(l,'LastData',SlastNew)
