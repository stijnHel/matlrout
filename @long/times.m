function r = times(p,q)
% LONG/TIMES  Implement p .* q for LONG elements.
p=long(p);
q=long(q);

r=long(p.decimales.*q.decimales,p.potencia+q.potencia);
