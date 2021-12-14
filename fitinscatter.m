function Yfit=fitinscatter(X,Y,Xfit,dx,varargin)
%fitinscatter - Fit points through scattered data
%       Yfit=fitinscatter(X,Y,Xfit[,dx[,options]])
%   if dx is not given, it's extracted from Xfit
%                       (median(diff(Xfit))*2)
%  This function is replaced to be used in data where interp1 can't be used
%  because the data is not scrictly increasing/decreasing.  Datapoints are
%  searched around the points (width dx) and a fit is done.  If no points
%  are found, linear fitting is used, if possible.
%  Since each point is handled separately, this function is quite slow!
%
% options:
%     Xeps     - if equal point found, use this (set to 0 to disable)
%     bLinFit  - true: LR fit, otherwise mean of found points in range

bLinFit=false;
Xeps=[];
options=varargin;
if nargin>3&&ischar(dx)
	options=[{dx} options];
	dx=[];
end
if ~isempty(options)
	setoptions({'Xeps','bLinFit'},options{:})
end
if isempty(Xeps)
	Xeps=(max(X)-min(X))*1e-14;
end

if nargin<4||isempty(dx)
	dx=median(diff(Xfit(:)))*2;
end
Yfit=Xfit;
[X,ii]=sort(X);
Y=Y(ii);
j1=1;
j2=1;
N=length(X);
for i=1:numel(Xfit)
	x=Xfit(i);
	x1=x-dx;
	while j1<N&&X(j1)<x1
		j1=j1+1;
	end
	x1=x+dx;
	while j2<=N&&X(j2)<=x1
		j2=j2+1;
	end
	ii=j1:j2-1;
	X1=X(ii);
	Y1=Y(ii);
	nanyb=isempty(ii);	% comes from find, now not possible!
	if Xeps>0&&any(abs(X1-x)<Xeps)
		y=mean(Y(abs(X1-x)<Xeps));
	elseif nanyb||sum(X1<x)==0||sum(X1>x)==0
		i1=find((X(2:end)>=x&X(1:end-1)<=x)|(X(2:end)<=x&X(1:end-1)>=x));
		if isempty(i1)
			y=NaN;
		else
			y=Y(i1)+(Y(i1+1)-Y(i1))./(X(i1+1)-X(i1)).*(x-X(i1));
		end
	elseif bLinFit
		p=polyfit(X1,Y1,1);
		y=polyval(p,x);
	else
		y=mean(Y1);
	end
	Yfit(i)=y;
end
