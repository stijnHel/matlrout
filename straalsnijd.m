function [x,a]=straalsnijd(X,h)
% STRAALSNIJD - Bepaalt snijding van stralen
%    x=straalsnijd(X,h)
%         X en h uitgangen van straaluit
%    [x,a]=.... (enkel wanneer meer dan twee lijnen)
%         a is lijst van punten

n=size(h,1);
if n<2
	error('Minimaal twee lijnen!!!')
elseif n>2
	x=zeros(2,n,n);
	for i=1:n-1
		for j=i+1:n
			x1=straalsnijd(X(:,:,[i j]),h([i j],:))';
			x(:,i,j)=x1;
			x(:,j,i)=x1;
		end
	end
	if nargout>1
		a=reshape(x,2,n*n)';
		a(1:n+1:n*n,:)=[];
	end
	return
end
a1=tan(h(1,end));
x1=X(end,1,1);
y1=X(end,2,1);
a2=tan(h(2,end));
x2=X(end,1,2);
y2=X(end,2,2);
x=(y2-a2*x2-y1+a1*x1)/(a1-a2);
x(1,2)=y1+a1*(x-x1);
