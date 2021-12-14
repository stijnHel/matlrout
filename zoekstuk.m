function n=zoekstuk(a,l,dn)
% ZOEKSTUK - Zoekt een dubbel stuk in een array.
la=length(a);
if ~exist('dn');dn=1;end
if dn*2>=la
	n=0;
	return;
end
ixx=1:dn:la-l*2+1;
xx=ixx(find(a(ixx)==a(l+ixx)));
nxx=length(xx);
i=0;
ngevonden=1;
while i<nxx & ngevonden
	i=i+1;
	n=xx(i);
	ngevonden=~all(a(n:n+l-1)==a(n+l:n+l*2-1));
end
if ngevonden
	n=0;
end
