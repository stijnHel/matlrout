function [Xm,Xrest]=runMeanDec(X,n)
%runMeanDec - function to calculate a running mean and decimate (no overlap)
%    Xm=runMeanDec(X,n);
%           (a second output argument gives the "resting data")

persistent XREST

if nargin==0||isempty(X)
	XREST=[];
	return
end

if size(XREST,2)==size(X,2)
	X=[XREST;X];
end

nX=floor(size(X,1)/n);
Xm=zeros(nX,size(X,2));
for i=1:nX
	Xm(i,:)=mean(X((i-1)*n+1:i*n,:));
end
XREST=X(nX*n+1:end,:);
if nargout>1
	Xrest=XREST;
end
