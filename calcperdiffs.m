function y=calcperdiffs(x)
%CALCMINDIFFS - Calculates mean periodical differences - to search for periodicals

iDiffs=1:length(x)-1;
y=x(iDiffs);	% just to make the output variable with the right size

for j=1:length(iDiffs)
	y(j)=mean((x(1:end-iDiffs(j))-x(iDiffs(j)+1:end)).^2);
end
