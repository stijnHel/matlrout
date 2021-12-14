function [e,I]=extrQuietPts(e,varargin)
%extrQuietPts - Extract "quiet points" from list
%  Remove points until all points are "normal".
%       e=extrQuietPts(e[,options])
%             bMean1: use mean and not median as first step
%             nMax : maximum number of iterations
%             fStd : factor to standard deviation for removal
%             fStd1: (if given) first factor to std
%             bSetNaN: don't remove but set removed points to NaN
%             bSetInf: don't remove but set removed points to +/- Inf

bMean1=false;
nMax=Inf;
fStd=4;
fStd1=[];
bSetNaN=false;
bSetInf=false;

if nargin>1
	setoptions({'bMean1','nMax','fStd','fStd1','bSetNaN','bSetInf'}	...
		,varargin{:})
end
if isempty(fStd1)
	fStd1=fStd;
end

[m,n]=size(e);
bTranspose=m<n;
if bTranspose
	e=e';
	[m,n]=size(e);
end

if bMean1
	e_mn=mean(e);
else
	e_mn=median(e);
end
e_std=std(e);
if bSetInf
	bH=e>repmat(e_mn+e_std*fStd1,m,1); %#ok<UNRCH>
	bL=e<repmat(e_mn-e_std*fStd1,m,1);
	b=bH|bL;
else
	b=e>repmat(e_mn+e_std*fStd1,m,1)|e<repmat(e_mn-e_std*fStd1,m,1);
end

n0=sum(b(:));
n0l=0;
nL=0;
nNOK=n0;
while n0>n0l&&nL<nMax
	nL=nL+1;
	n0l=n0;
	for i=1:n
		nb1=~b(:,i);
		e_mn(i)=mean(e(nb1,i));
		e_std(i)=std(e(nb1,i));
		if bSetInf
			bH(nb1)=e(nb1,i)>e_mn(i)+e_std(i)*fStd; %#ok<UNRCH>
			bL(nb1)=e(nb1,i)<e_mn(i)-e_std(i)*fStd;
			b=bH|bL;
		else
			b(nb1,i)=e(nb1,i)>e_mn(i)+e_std(i)*fStd		...
				|e(nb1,i)<e_mn(i)-e_std(i)*fStd;
		end
	end
	n0=sum(b(:));
	nNOK(1,end+1)=n0;
end

if bSetNaN
	e(b)=NaN;
elseif bSetInf
	e(bH)=Inf;
	e(bL)=-Inf;
else
	e(any(b,2),:)=[];
end

if bTranspose
	e=e';
end
if nargout>1
	I=struct('nLoop',nL,'bNOK',b,'nNOK',nNOK,'e_mean',e_mn,'e_std',e_std);
end
