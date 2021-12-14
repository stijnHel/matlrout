function [X,Y]=findkarak(x,y,dx)
% FINDKARAK - Zoekt karakteristiek (door een soort van filtering)
%  [X,Y]=findkarak(x,y,dx)

if ~exist('dx')|isempty(dx)
	if length(x)<100
		n=floor(length(x)/5);
	else
		n=20;
	end
	dx=(max(x)-min(x))/n;
end

[x,i]=sort(x);
y=y(i);
X=ceil(x(1)/dx)*dx:dx:x(end);
Y=zeros(size(X))+NaN;
for i=1:length(X)
	j=find(x>X(i)-dx&x<X(i)+dx);
	if length(j)>1
		p=polyfit(x(j),y(j),1);
		Y(i)=polyval(p,X(i));
	end
end
if isnan(Y(1))
	Y(1)=y(1);
end
if isnan(Y(end))
	Y(end)=y(end);
end
i=find(isnan(Y));
for j=1:length(i)
	k=find(~isnan(Y(i(j)+1:end)));
	Y(i(j))=interp1([X(i(j)-1) X(i(j+k(1)))],[Y(i(j)-1) Y(i(j+k(1)))],X(i(j)));
end
