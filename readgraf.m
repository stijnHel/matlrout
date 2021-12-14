function P=readgraf(X,col,varargin)
%readgraf - Reads a graph
%     D=readgraf(X,col,varargin)
%!!!simpel!!!!

bScale=false;
scale=[];
col=double(col);
X=double(X);	% "make it easy" (avoid problems like uint8(4)-uint8(10)==0
tol=max(X(:))/100;

if ~isempty(varargin)
	setoptions({'tol','scale','bScale'}	...
		,varargin{:})
	if ~isempty(scale)
		bScale=true;
	end
end

[m,n,ndcol]=size(X);
P=zeros(n,3);
for i=1:n
	L=squeeze(X(:,i,:));
	d=abs(L-repmat(col,m,1));
	if ndcol>1
		d=sqrt(sum(d.^2,2));
	end
	k=find(d<tol);
	if ~isempty(k)
		if length(k)>1&&any(diff(k))>1
			P(i,3)=-1;
		else
			P(i,1)=i;
			P(i,2)=mean(k);
			P(i,3)=length(k);
		end
	end
end
P(P(:,3)==0,:)=[];

if bScale
	if ~isempty(scale)
		P(:,1:2)=plotui(scale,P(:,1:2));
	else
		P(:,1:2)=plotui('convert',P(:,1:2));
	end
end
