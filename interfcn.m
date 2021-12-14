function [y,Dx]=interfcn(X,Y,x,n)
% INTERFCN - interpoleert in een functie (ongesorteerde punten)
%

[Xs,i]=sort(X);
Ys=Y(i);
minx=Xs(1);
maxx=Xs(length(X));
if ~exist('n');n=[];end
if isempty(n)
	n=max(5,min(20,length(X)/10));
end
dx=(maxx-minx)/n;
dx2=dx/2;
nklein=1;
binnengrenzen=1;
tweekanten=1;
y=zeros(size(x));
for i=1:prod(size(x))
	x1=x(i);
	if (x1<minx) | (x1>maxx)
		y(i)=NaN;
		if binnengrenzen
			binnengrenzen=0;
			fprintf('Er zijn punten buiten de tabel\n');
		end
	else
		j=find((Xs>=x1-dx2)&(Xs<=x1+dx2));
		if length(j)<2
			if nklein
				nklein=0;
				fprintf('Er zijn punten zonder corresponderende punten in X, dx wordt uitgebreid\n');
			end
			j=find(Xs<x1);
			y(i)=Ys(j)+(x1-Xs(j))/diff(Xs(j:j+1))*diff(Ys(j:j+1));
		elseif (Xs(j(1))>x1)|(Xs(j(length(j)))<x1)
			if tweekanten
				tweekanten=0;
				fprintf('Alle punten liggen langs 1 kant\n');
			end
			% ?? andere berekening ?
			p=polyfit(Xs(j),Ys(j),1);
			y(i)=polyval(p,x(i));
		else
			p=polyfit(Xs(j),Ys(j),1);
			y(i)=polyval(p,x(i));
		end
	end
end


if nargout>1
	Dx=dx;
end
