function [Mn,iMin]=findlocalminima(x,varargin)
%FINDLOCALMINIMA - Find local minima in signal

%!!!!!opties als dxHist werken slecht!!!!

mOpties={'dImin','Nmax','xHist','maxMin','dxHist'};
if nargin>1
	if nargin==2
		opties=varargin{1};
	else
		opties=varargin;
	end
end
for i=1:length(mOpties)
	assignval(mOpties{i},[]);
end
if exist('opties','var')
	if ~iscell(opties)||rem(length(opties),2)
		error('Verkeerde opties')
	end
	UMO=upper(mOpties);
	for i=1:2:length(opties)
		j=strmatch(upper(opties{i}),UMO,'exact');
		if ~isempty(j)
			assignval(mOpties{j},opties{i+1});
		end
	end
end

if isempty(dImin)
	dImin=10;
elseif dImin<2
	error('dImin has to be minimum 2')
elseif dImin>length(x)
	error('dImin can not be higher than the length of the input vector')
end
if isempty(Nmax)
	Nmax=ceil(length(x)/dImin);
else
	Nmax=min(Nmax,ceil(length(x)/dImin));
end
if isempty(xHist)
	xHist=0;
end
if isempty(dxHist)
	dxHist=0;
end
if isempty(maxMin)
	maxMin=max(x);
end
nMin=0;
Mn=zeros(1,Nmax);
iMin=Mn;
i=2;
while i<length(x)&&x(i)>x(i-1)
	i=i+1;
end
curMin=x(1);
while i<length(x)-dImin
	[mn,j]=min(x(i:i+dImin+1));
	if j>1
		i=i+j-1;
		curMin=mn;
	elseif mn>maxMin
		i=i+dImin;
	else	% found
		nMin=nMin+1;
		Mn(nMin)=mn;
		iMin(nMin)=i;
		i=i+dImin;
		if xHist>0||dxHist>0
			mn=max(xHist,mn+dxHist);
		end
		while i<=length(x)&&(x(i)<mn||x(i)>x(i-1))
			i=i+1;
		end
	end
end
Mn=Mn(1:nMin);
iMin=iMin(1:nMin);
