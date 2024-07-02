function [x,y,z] = GetCurrentPt(ax)
%GetCurrentPt - Get coordinates of current point (in axis dimensions)
%     [x,y,z] = GetCurrentPt(ax)
%          if ax not given ==> gca
%
% The reason to have this function is that get(ax,'CurrentPoint' only gives
% the right values with "normal data", not with "scaled data", like when
% using datetime as timestamps.

if nargin==0 || isempty(ax)
	ax = gca;
end

pt = get(ax,'CurrentPoint');
R = get(gca,'XAxis');
x = num2ruler(pt(1,1),R);
if nargout>1
	R = get(gca,'YAxis');
	y = num2ruler(pt(1,2),R);
	if nargout>2
		R = get(gca,'ZAxis');
		z = num2ruler(pt(1,3),R);
	end
end
