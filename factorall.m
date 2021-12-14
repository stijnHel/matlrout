function [F,uFprime,Fpowers,ii]=factorall(N,bSort)
%factorall - returns all factors of N (not only prime factors)
%    F=factorall(N[,bSort])
%
% see also factor

if nargin<2||isempty(bSort)
	bSort=true;
end

Fprime=factor(N);
uFprime=unique(Fprime);
if isscalar(uFprime)
	nFprime=length(Fprime);
else
	nFprime=hist(Fprime,uFprime);
end
nF=prod(nFprime+1);
Fpowers=zeros(length(uFprime),nF);
iF=nFprime(1)+1;
Fpowers(1,2:nFprime(1)+1)=1:nFprime(1);
for i=2:length(uFprime)
	if nFprime(i)==1
		Fpowers(1:i-1,iF+1:iF*(nFprime(i)+1))=Fpowers(1:i-1,1:iF);
	else
		Fpowers(1:i-1,iF+1:iF*(nFprime(i)+1))=repmat(Fpowers(1:i-1,1:iF),1,nFprime(i));
	end
	iF1=iF;
	for j=1:nFprime(i)
		Fpowers(i,iF+1:iF+iF1)=j;
		iF=iF+iF1;
	end
end
F=prod(uFprime'.^Fpowers,1);
if bSort
	[F,ii]=sort(F);
	if nargout>2
		Fpowers=Fpowers(:,ii);
	end
end
