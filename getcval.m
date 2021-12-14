function [w,D]=getcval(c)
% GETCVAL - bepaalt de waarden van een contour.
%   [w,D]=getcval(c)
%  met c de uitgang van een contour
%      D contours:
%         D(1).w = value
%         D(1).C --> struct array with coordinates (x,y)

N=size(c,2);
% to avoid too much memory usage, first count number of sections
nw=0;
ic=1;
while ic<N
	nw=nw+1;
	ic=ic+c(2,ic)+1;
end
W=zeros(1,nw);
ic=1;
for iW=1:nw
	W(iW)=c(1,ic);
	ic=ic+c(2,ic)+1;
end
w=unique(W);
if nargout>1
	if isscalar(w)
		NW=length(W);
	else
		NW=hist(W,w);
	end
	D=struct('w',num2cell(w),'C',[]);
	NN=zeros(1,length(w));
	ic=1;
	for iW=1:nw
		j=findclose(W(iW),w);
		k=NN(j)+1;
		NN(j)=k;
		if k==1
			D(j).C=struct('x',cell(1,NW(k)),'y',[]);
		end
		n=c(2,ic);
		D(j).C(k).x=c(1,ic+1:ic+n);
		D(j).C(k).y=c(2,ic+1:ic+n);
		ic=ic+n+1;
	end
end
