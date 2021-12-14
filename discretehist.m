function [N,X,NN]=discretehist(x,dx,Nmin,varargin)
%discretehist - histogram of discrete data with noise
%    [N,X]=discretehist(x,-dx,Nmin)
%    [N,X]=discretehist(x,N,Nmin) (with N>1)
%    [N,X]=discretehist(x,N,xList)
%    ......discretehist(...<options>)
%          options: bPlot

% could be improved to set a minimal distance between points

bPlot=nargout==0;
xList=[];
options=varargin;
if ~exist('dx','var')
	dx=[];
elseif ischar(dx)
	options=[{dx,Nmin},options];
	dx=[];
	Nmin=[];
elseif length(dx)>1
	xList=dx;
end
if ~exist('Nmin','var')
	Nmin=[];
elseif ischar(Nmin)
	options=[{Nmin},options];
	Nmin=[];
end
if isempty(dx)
	dx=1000;
end
if ~isempty(options)
	setoptions({'bPlot'},options{:})
end
if isempty(xList)
	mx=max(x);
	mn=min(x);
	if dx>1
		dx=(mx-mn)/(dx-1);
	end
	xList=mn:dx:mx;
end

[nn,xx]=hist(x,xList);
if isempty(Nmin)
	Nmin=max(max(nn)/100,1);
end
ii=find(nn>Nmin);
N=nn(ii);
X=xx(ii);
i=1;
NN=ones(size(N));
while i<length(N);
	j=i+1;
	while j<=length(ii)&&ii(j)==ii(j-1)+1
		j=j+1;
	end
	if j>i+1
		n1=sum(N(i:j-1));
		x1=sum(X(i:j-1).*N(i:j-1))/n1;
		N(i)=n1;
		X(i)=x1;
		N(i+1:j-1)=0;
		NN(i)=j-i;
	end
	i=j;
end
B=N>0;
X=X(B);
N=N(B);
NN=NN(B);

if bPlot
	getmakefig DISCRETEHIST
	fN=max(nn)/max(N)*1.1;
	l=plot(xx,nn,'-',X,N*fN,'o',[min(x) max(x)],[0 0]+Nmin,'-');grid
	hM=uicontextmenu;
	uimenu(hM,'label',sprintf('plot-factor=%5.2f',1/fN))
	set(l,'uicontextmenu',hM)
end

if nargout==0
	clear X N NN
end
