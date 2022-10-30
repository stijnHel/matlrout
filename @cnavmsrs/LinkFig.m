function LinkFig(c,figToLink)
%cnavmsrs/LinkFig - Link cnavmsrs-figure
%    c.LinkFig(figToLink)

if ~isempty(c.opties.postNavFcn)% && c.opties.postNavFcn~=@AdaptLinked
	warning('Overwriting postNav!')
end
c.opties.postNavFcn = @AdaptLinked;
if ~isfield(c.opties,'linked') || isempty(c.opties.linked)
	c.opties.linked = figToLink;
else
	c.opties.linked(end+1) = figToLink;
end

function AdaptLinked(fig,nr)
c = get(fig,'UserData');
i = 1;
while i<=length(c.opties.linked)
	if ishandle(c.opties.linked(i))
		c1 = get(c.opties.linked(i),'UserData');
		c1.navmsrs(nr)
		i = i+1;
	else
		c.opties.linked(i) = [];
	end
end
