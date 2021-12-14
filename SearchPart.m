function ii=SearchPart(X,y)
%SearchPart - Search block of data in a vector
%   ii=SearchPart(X,y)
%        X : long data
%        y : block to be searched in X
%        ii: starting index(/indices) in X equal to y

ii=find(X==y(1))-1;
ii(ii>=length(X)-length(y)+1)=[];
i=1;
while i<length(y)&&~isempty(ii)
	i=i+1;
	ii=ii(X(ii+i)==y(i));
end
if ~isempty(ii)
	ii=ii+1;
end
