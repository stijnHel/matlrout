function [d,l]=CalcDistPtLine(Xp,X0,X1,lMin,lMax)
%CalcDistPtLine - Calculate distance between point Xp and line (X0..X1)
%     [d,l]=CalcDistPtLine(Xp,X0,X1,lMin,lMax)
%     [d,l]=CalcDistPtLine(Xp,[X Y])
%     d=CalcDistPtLine(Xp,[a,b])	with y = a.x+b
%     d=CalcDistPtLine(Xp,[a,b,c]) with a.x + b.y + c = 0
%  Xp, X0 and X1 are coordinates in 2D or 3D (all the same dimension)!
%     columns and rows are allowed, but all must be the same
%    d: distance
%    l: indication for closest point on line (X0+l*(X1-X0))
% If second format is used, the minimum distance is given, and l is the
%    fractional index within [X Y].

if nargin==2 && isvector(X0)
	if length(X0)==2
		m = X0(1);
		k = X0(2);
		d = abs(k+m*Xp(:,1)-Xp(:,2))/sqrt(1+m^2);
	elseif length(X0)==3
		a = X0(1);
		b = X0(2);
		c = X0(3);
		d = abs(a*Xp(:,1)+b*Xp(:,2)+c)/sqrt(a^2+b^2);
	else
		error('Wrong input!')
	end
	return
end

if nargin<5
	lMax=[];
	if nargin<4
		lMin=[];
	end
end

if min(size(X0))>1
	lMax=lMin;
	if nargin<3
		lMin=[];
	else
		lMin=X1;
	end
	if size(X0,1)==2
		X1=X0(2,:);
		X0=X0(1,:);
	else	% multiple line segments given
		d=Inf;
		for i=1:size(X0,1)-1
			[d1,l1]=CalcDistPtLine(Xp,X0(i,:),X0(i+1,:));
			if d1<d
				d=d1;
				l=l1+i;
				if l1==0
					break	% it won't become smaller!
				end
			end
		end		% for i
		return
	end		% multiple line segments given
end		% if nargin==2

dX01=X1-X0;
if all(dX01==0)	% point!
	d=sum((Xp-X0).^2);
	l=0.5;
else
	dXp0=Xp-X0;
	l=sum(dX01.*dXp0)./sum(dX01.^2);
		% is l supposed to be possibly vector ==> change the following to a loop?
	if ~isempty(lMin)&&l<lMin
		l=lMin;
	end
	if ~isempty(lMax)&&l>lMax
		l=lMax;
	end
	d=sqrt(sum((dXp0-l*dX01).^2));
end
