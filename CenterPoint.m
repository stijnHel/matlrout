function C=CenterPoint(X,Y)
%CenterPoint - Calculates center point
%       C=CenterPoint; (takes data from current figure - see getsigs)
%       C=CenterPoint(X,Y);
%       C=CenterPoint(XY);
%           XY=[X Y] or XY=[X Y bX bY] (see getsigs)
%       C=CenterPoint({XY1,XY2,...}) (or nested)
%
%  Center point is calculated by:
%       sum(X.*Y)/sum(Y)

if nargin==0
	C=CenterPoint(getsigs);
elseif nargin==2
	C=sum(X.*Y)/sum(Y);
elseif isnumeric(X)
	if size(X,2)==2
		C=CenterPoint(X(:,1),X(:,2));
	elseif size(X,2)==4
		b=X(:,3)&X(:,4);
		C=CenterPoint(X(b,1),X(b,2));
	else
		error('Wrong use')
	end
elseif iscell(X)
	C=X;
	for i=1:numel(X)
		C{i}=CenterPoint(X{i});
	end
else
	error('Wrong use of function')
end