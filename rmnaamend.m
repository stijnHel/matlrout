function X=rmnaamend(X,n)
% RMNAAMEND - Verwijdert einde van de namen in X
%   X=rmnaamend(X,n)
%       X : struct met minstens veld naam
%       n : aantal karakters weg te halen

if ischar(n)
	n=length(n);
end
for i=1:length(X)
	if strcmp(lower(n),X(i).naam(max(1,end-n+1):end))
		X(i).naam=X(i).naam(1:end-n);
	else
		warning(sprintf('naam had niet het juiste einde (%s)',X(i).naam))
	end
end
