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

ax = GetNormalAxes(figFollow);
ax = ax(1);
setappdata(figFollow,'followNavData'	...
	,struct('lFollow',lFollow,'axFollow',ax,'t',t_lF,'Z',Z))
navfig(figFollow,'addUpdateAxes',@UpdateLine)

UpdateLine(ax)

function UpdateLine(ax)
xl = xlim(ax);
D = getappdata(ancestor(ax,'figure'),'followNavData');
if D.axFollow~=ax	% don't do anything for other axes
	return
end
if ~ishandle(D.lFollow)
	warning('follow-line does not exist anymore!')
	navfig(ancestor(ax,'figure'),'updateAxesT')
	return
end
B = D.t>=xl(1) & D.t<=xl(2);
set(D.lFollow,'XData',D.Z(B,1),'YData',D.Z(B,2))
if size(D.Z,2)>2
	D.lFollow.ZData = D.Z(B,3);
end
