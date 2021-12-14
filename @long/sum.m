function r=sum(v)
D=v.decimales;
P=v.potencia;

%r=long(sum(D.*(10.^(max(P)-P))),max(P));
r=0;

for i=1:prod(size(v))
    A.subs={[i]};
    r=r+subsref(v,A);
end
    