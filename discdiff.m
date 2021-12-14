function [dx,Bdx]=discdiff(x)
%discdiff - diff of discrete data
%    continuously changing discretized values are differentiated
%           dx=discdiff(x)
%    The diffence between two successively changing values are used to
%    differentiate.  That means that fast changing signals are
%    differentiated with low step, slowly changing signals use longer
%    steps.  dx changes stepwise between slowly changing values.
%    A column vector as input gives a column vector, and similar for row
%    vectors.
%
%    example:
%        x = [ 0     0     0    12    12    12    12    24    24    24    36]
%      gives
%              [  0     6     6     3     3     3     3     4     4     4]
%
%      [dx,Bdx]=...
%        Bdx is a boolean vector giving positions of updated values of dx
%      if 'x' is a matrix, discdiff is calculated for each column.

if min(size(x))>1
	[dx,Bdx]=discdiff(x(:,1));
	dx(1,size(x,2))=0;
	Bdx(1,size(x,2))=0;
	for i=2:size(x,2)
		[dx(:,i),Bdx(:,i)]=discdiff(x(:,i));
	end
	return
end

tol=1e-20;	% !!!

dx=diff(x);
Bdx=false(size(dx));
Bdx(1)=abs(dx(1))<tol;
i=2;
while i<=length(dx)
	if abs(dx(i))<tol
		i0=i;
		i=i+1;
		while i<length(dx)&&abs(dx(i))<tol
			i=i+1;
		end
		dx(i0:i)=(x(i+1)-x(i0))/(i+1-i0);
		Bdx(i)=true;
	else
		Bdx(i)=true;
	end
	i=i+1;
end
