function t=mtimes(p,q)
% LONG/PLUS  Implement p + q for LONG elements.
p=long(p);
q=long(q);
sp=size(p);
sq=size(q);
if prod(sp)==1|prod(sq)==1
    t=p.*q;
else
tP=zeros(sp(1),sq(2));
tD=tP;
pP=p.potencia;
pD=p.decimales;
qP=q.potencia;
qD=q.decimales;
for i=1:sp(1)
    for k=1:sq(2)
       S=long(0);
       for j=1:sp(2)
              S=S+long(pD(i,j),pP(i,j)).*long(qD(j,k),qP(j,k));
       end
       tD(i,k)=decimales(S);
       tP(i,k)=potencia(S);
    end
end
t.potencia=tP;
t.decimales=tD;
t=class(t,'long');
end

