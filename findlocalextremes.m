function [Ext,iExt,y]=findlocalextremes(x,varargin)
%FINDLOCALEXTREMES - Searches for local extremes
%    [Ext,iExt,y]=findlocalextremes(x[,options])
%        possible options
%            DXmin,rDXmin : minimum change between successive extremes
%             (rDXmin gives the relative difference)

bQuadCalc=false;
Xrange=max(x)-min(x);
if Xrange==0
	Ext=[];
	if nargout>1
		iExt=[];
	end
	y=zeros(size(x));
	return
end
DXmin=Xrange/1000;

if nargin>1
	mOpties={'DXmin','rDXmin','bQuadCalc'};
	rDXmin=[];
	setoptions(mOpties,varargin{:})
	if ~isempty(rDXmin)
		DXmin=Xrange*rDXmin;
	end
end

y=zeros(size(x));	% (very) local extremes (+1 / -1)
y(2:end-1)=(x(3:end)<x(2:end-1)&x(2:end-1)>x(1:end-2))	...
	-(x(3:end)>x(2:end-1)&x(2:end-1)<x(1:end-2));
iMxLast=0;
iMnLast=0;
i=2;

while i<=length(x)
	if y(i)>0
		if iMxLast
			if iMnLast<iMxLast
				if x(i)>x(iMxLast)
					y(iMxLast)=0;
					iMxLast=i;
				else
					y(i)=0;
				end
			elseif x(i)-x(iMnLast)<DXmin
				if x(i)>x(iMxLast)
					y(iMxLast)=0;
					iMxLast=i;
				else
					y(i)=0;
				end
			else
				iMxLast=i;
			end
		elseif iMnLast
			if x(i)-x(iMnLast)<DXmin
				y(i)=0;
			else
				iMxLast=i;
			end
		else
			iMxLast=i;
		end
	elseif y(i)<0
		if iMnLast
			if iMxLast<iMnLast
				if x(i)<x(iMnLast)
					y(iMnLast)=0;
					iMnLast=i;
				else
					y(i)=0;
				end
			elseif x(iMxLast)-x(i)<DXmin
				if x(i)<x(iMnLast)
					y(iMnLast)=0;
					iMnLast=i;
				else
					y(i)=0;
				end
			else
				iMnLast=i;
			end
		elseif iMxLast
			if x(iMxLast)-x(i)<DXmin
				y(i)=0;
			else
				iMnLast=i;
			end
		else
			iMnLast=i;
		end
	end
	i=i+1;
end
if iMxLast>iMnLast
	if any(x(iMxLast+1:end)>x(iMxLast))
		y(iMxLast)=0;
	end
elseif iMxLast<iMnLast
	if any(x(iMnLast+1:end)<x(iMnLast))
		y(iMnLast)=0;
	end
end
iExt=find(y~=0);
Ext=x(iExt);
if bQuadCalc
	n=length(x);
	xx=-1:1;
	if size(x,2)==1
		xx=xx';
	end
	for j=1:length(iExt)
		i=iExt(j);
		if i>1&&i<n
			p=polyfit(xx,x(i-1:i+1),2);
			di=-p(2)/2/p(1);
			iExt(j)=iExt(j)+di;
			Ext(j)=polyval(p,di);
		end
	end
end
