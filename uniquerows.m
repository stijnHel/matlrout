function [P iOut]=uniquerows(P)
% UNIQUEROWS - Geeft unieke rijen
%        [P iOut]=uniquerows(P)

n=size(P,1);
lUn=true(1,n);
for i=2:n
	lUn(i)=~any(all(P(1:i-1,:)==P(i+zeros(1,i-1),:),2));
end
P=P(lUn,:);
if nargout>1
	iOut=lUn;
end
