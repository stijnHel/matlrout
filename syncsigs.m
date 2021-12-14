function Y=syncsigs(X)
%syncsigs - Synchronize signals
%     Y=syncsigs(X)
%     syncsigs         - retrieves data from graph

%%%!!only for single-axes figures !!!!

bPolyfit=true;

bUI=nargin==0;
if bUI
	[X,Xi]=getsigs;
	X0=X;
	for i=1:length(X)
		X{i}=X{i}(X{i}(:,3)>0&X{i}(:,4)>0,1:2);
	end
	bUI=true;
end

MN=-Inf;
MX=Inf;
nX=numel(X);
DX=zeros(0,nX);
for i=1:nX
	mn=min(X{i}(:,2));
	mx=max(X{i}(:,2));
	MN=max(MN,mn);
	MX=min(MX,mx);
	DX=sign(X{i}(end,2)-X{i}(1,2));
end
if MX<=MN
	error('Overlap in y-direction is needed!')
end
if ~all(DX==DX(1))
	error('All signals should decrease or increase')
end
DX=DX(1);

YMN=(MX+MN)/2;
dY=(MX-MN)/10;

T0=zeros(size(X));
for i=1:nX
	x=X{i}(:,1);
	y=X{i}(:,2);
	if DX>0
		ii=find(y(2:end)>=YMN&y(1:end-1)<YMN);
	else
		ii=find(y(2:end)<=YMN&y(1:end-1)>YMN);
	end
	ii=round(mean(ii));
	t0=x(ii);
	if bPolyfit
		ii=find(y>=YMN-dY&y<=YMN+dY);
		p=polyfit(x(ii)-t0,y(ii)-YMN,1);
		t0=t0-p(2)/p(1);
	end
	T0(i)=t0;
end

if bUI
	mT0=mean(T0);
	for i=1:nX
		set(Xi.lines(i),'XData',X0{i}(:,1)+(mT0-T0(i)));
	end
end
