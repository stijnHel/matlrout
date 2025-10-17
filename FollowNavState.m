function FollowNavState(figFollow,lFollow,t_lF,Z)
%FollowNavState - Follow the navigation state and limit points
%     FollowNavState(figFollow,lFollow,t_lF[,Z])
%                 if Z is supplied, this is used for data of lFollow
%                    otherwise, data is taken from lFollow

if ~isscalar(lFollow)
	error('Sorry, although thought to be an extension, currently only one line can follow!')
end
if nargin<4 || isempty(Z)
	Z = [lFollow.XData(:),lFollow.YData(:),lFollow.ZData(:)];
end
if size(Z,1)~=length(t_lF)
	error('Sorry, but length of time and XY(Z) data must be the same!')
end

if isappdata(figFollow,'followNavData')
	Fdata = getappdata(figFollow,'followNavData');
else
	Fdata = [];
end

ax = GetNormalAxes(figFollow);
ax = ax(1);	% just take the first axis
Fdata1 = struct('lFollow',lFollow,'axFollow',ax,'t',t_lF,'Z',Z);
if isempty(Fdata)
	Fdata = Fdata1;
	navfig(figFollow,'addUpdateAxes',@UpdateLine)
else
	Fdata(1,end+1) = Fdata1;
end
setappdata(figFollow,'followNavData',Fdata)
UpdateLine(ax)

function UpdateLine(ax)
xl = xlim(ax);
Fdata = getappdata(ancestor(ax,'figure'),'followNavData');
Brem = false(size(Fdata));
for i=1:length(Fdata)
	if Fdata(i).axFollow~=ax	% don't do anything for other axes
		continue
	end
	if ishandle(Fdata(i).lFollow)
		B = Fdata(i).t>=xl(1) & Fdata(i).t<=xl(2);
		set(Fdata(i).lFollow,'XData',Fdata(i).Z(B,1),'YData',Fdata(i).Z(B,2))
		if size(Fdata(i).Z,2)>2
			Fdata(i).lFollow.ZData = Fdata(i).Z(B,3);
		end
	else
		warning('follow-line does not exist anymore!')
		Brem(i) = true;
	end
end
if any(Brem)
	Fdata(Brem) = [];
	if isempty(Fdata)
		navfig(ancestor(ax,'figure'),'updateAxes',@UpdateLine,'stop')
		rmappdata(ancestor(ax,'figure'),'followNavData')
	else
		setappdata(ancestor(ax,'figure'),'followNavData',Fdata)
	end
end
