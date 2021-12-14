function y=middlepoints(x)
%middlepoints - Gives the points in the middle between successive points
%     y=middlepoints(x)
%
%       y=[(x(1)+x(2))/2,(x(2)+x(3))/2,....];
%   this is done for each row of column, the direction taken is that with
%   the maximum number of points

if size(x,1)<size(x,2)
	y=(x(:,1:end-1)+x(:,2:end))/2;
else
	y=(x(1:end-1,:)+x(2:end,:))/2;
end
