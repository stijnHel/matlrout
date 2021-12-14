function r=rdivide(p,q)
% LONG/RDIVIDE  Implement p ./ q for LONG elements.
p=long(p);
q=long(q);

r=long(p.decimales./q.decimales,p.potencia-q.potencia);



