function X=rmelnaamend(X,send)
% RMELNAAMEND - Verwijdert elementen met bepaald einde

i=1;
n=length(send);
k=0;
while i<=length(X)
	if strcmp(X(i).naam(max(1,end-n+1):end),send)
		X(i)=[];
		k=k+1;
	else
		i=i+1;
	end
end
fprintf('%d elementen verwijderd\n',k);
