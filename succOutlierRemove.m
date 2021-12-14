function [Out,i]=succOutlierRemove(X,facS)
%succOutlierRemove - successive outlier removement
%    Out=succOutlierRemove(X[,facS])
%
%  The mean value and standard deviation(std) of X
%    is calculated.
%  From this, the outliers (mean-facS*std<X<mean+facS*std)
%    are removed.
%  This is done until there are no outliers found.
%  Default value for facS = 3.
%  The output is a list of number elemts, mean and std in
%    the successive steps.

if nargin<2
	facS=3;	% 3 sigma
end

Out=zeros(0,3);
if nargout>1
	i=1:length(X);
end
while ~isempty(X)
	Out(end+1,:)=[length(X) mean(X) std(X)];
	b=X>Out(end,2)-facS*Out(end,3)&X<Out(end,2)+facS*Out(end,3);
	if all(b)
		return
	end
	i=i(b);
	X=X(b);
end
if isempty(X)
	Out(end+1,1)=0;
end
