function [ZI,PI]=interp3d(X,Y,Z,XI,YI)
% INTERP3D - Interpolation routine for 3d-tables

if nargin==3
	[sr,sc]=size(X);
%	ZI=interp2(X(1,2:sc),X(2:sr,1),X(2:sr,2:sc),Y,Z);
%	return
	YI=Z;
	XI=Y;
	Z=X(2:sr,2:sc);
	Y=X(2:sr,1);
	X=X(1,2:sc);
elseif nargin~=5
	error('3 or 5 inputs expected')
end

if min(size(X))==0
	error('X must not be empty')
elseif min(size(Y))==0
	error('Y must not be empty')
elseif min(size(X))>1
	error('X has to be a vector');
elseif min(size(Y))>1
	error('Y has to be a vector');
end
if any(XI<min(X))
	fprintf('Voor X-waarden lager dan minimum wordt minimum genomen\n');;
	XI=max(XI,min(X));
end
if any(XI>max(X))
	fprintf('Voor X-waarden hoger dan maximum wordt maximum genomen\n');;
	XI=min(XI,max(X));
end
if any(YI<min(Y))
	fprintf('Voor Y-waarden lager dan minimum wordt minimum genomen\n');;
	YI=max(YI,min(Y));
end
if any(YI>max(Y))
	fprintf('Voor Y-waarden hoger dan maximum wordt maximum genomen\n');;
	YI=min(YI,max(Y));
end

nX=length(X);
nY=length(Y);
if any(size(Z)~=[nY nX])
	Z=Z';
end
if any(size(Z)~=[nY nX])
	error('Sizes of X, Y and Z doesn''t correspond')
end
if isempty(XI) |isempty(YI)
	error('XI en YI mogen niet leeg zijn.')
end

if (length(XI)==1) & (length(YI)>1)
	XI=XI*ones(size(YI));
elseif (length(YI)==1) & (length(XI)>1)
	YI=YI*ones(size(XI));
elseif any(size(XI)~=size(YI))
	error('XI and YI must have the same sizes')
end
ZI=zeros(size(XI));
if prod(size(XI))>100
	status(sprintf('3d-interpolatie in %d punten',prod(size(XI))),0);
	dstat=prod(size(XI));
else
	dstat=0;
end
l=prod(size(XI));
i=1:l;
while ~isempty(i)
	if dstat
		status((l-length(i))/l);
	end
	k=find(YI(i)==YI(i(1)));
	ki=i(k);
	i(k)=[];
	
	yi=YI(ki(1));
	
	k=find(Y>yi)-1;
	if max(Y)==yi
		k=-1;
	elseif isempty(k)
		k=0;
	end
	if k(1)==0
		ZI(ki)=NaN*ones(size(ki));
	elseif k(1)==-1
		ZI(ki)=interp1(X,Z(size(Z,1),:),XI(ki));
	else
		k=k(1);
		fy=(yi-Y(k))/(Y(k+1)-Y(k));
		zx=(1-fy)*Z(k,:)+fy*Z(k+1,:);
		ZI(ki)=interp1(X,zx,XI(ki));
	end
end
if dstat
	status;
end
