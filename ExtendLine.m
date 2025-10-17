function ExtendLine(l,nPts,side)
%ExtendLine - Extend (extrapolate linearly) line in X-direction to end of axis (create new line)
%       ExtendLine([hLine,nPts,side])

if nargin && isstringlike(l)
	if startsWith(l,'del')	% delete extending lines
		l = findobj(gcf,'Tag','ExtendingLine');
		delete(l)
	end
	return
end
if nargin<1 || isempty(l)
	l = findobj(gcf,'Type','line');
	B = false(size(l));
	for i=1:length(l)
		B(i) = strcmp(l(i).Tag,'ExtendingLine');
	end
	l(B) = [];
end
if nargin<2 || isempty(nPts)
	nPts = 4;
end
if nargin<3
	side = [];
end

if isempty(l)
	warning('No line to extend?!')
	return
elseif ~isscalar(l)
	for i=1:length(l)
		ExtendLine(l(i),nPts,side)
	end
	return
end

if isempty(side)
	ax = l.Parent;
	if min(l.XData)>ax.XLim(1)
		ExtendLine(l,nPts,0)
	end
	if max(l.XData)<ax.XLim(2)
		ExtendLine(l,nPts,1)
	end
	return
end

xl = l.Parent.XLim;
if side<=0
	[mnX,i] = min(l.XData);
	%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	if mnX<=xl(1) || mnX>xl(2) || length(l.XData)<nPts
		return	% no extension required
	end
	if i>1
		error('Sorry, it''s not implemented yet for lines like this...')
	end
	ii = find(l.XData<xl(2),nPts);
	x = [xl(1),mnX];
else
	[mxX,i] = max(l.XData);
	if mxX>=xl(2) || mxX<xl(1) || length(l.XData)<nPts
		return	% no extension required
	end
	if i~=length(l.XData)
		error('Sorry, it''s not implemented yet for lines like this...')
	end
	ii = find(l.XData>xl(1),nPts,'last');
	x = [mxX,xl(2)];
end
if length(ii)<2
	warning('At least 2 visible points are expected!')
end
X = l.XData(ii);
if min(X)>=max(X)
	return	% just do nothing silently(?)
end
Y = l.YData(ii);
bXnum = isnumeric(X);
if ~bXnum
	RX = l.Parent.XAxis;
	X = ruler2num(X,RX);
end
bYnum = isnumeric(Y);
if ~bYnum
	RY = l.Parent.YAxis;
	Y = ruler2num(Y,RY);
end
p = polyfit(X,Y,1);
y = polyval(p,x);
if ~bXnum
	x = num2ruler(x,RX);
end
if ~bYnum
	y = num2ruler(y,RY);
end
line(x,y,'Color',l.Color,'LineStyle',':','Tag','ExtendingLine')
