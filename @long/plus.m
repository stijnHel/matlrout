function r = plus(p,q)
% LONG/PLUS  Implement p + q for LONG elements.

p=long(p);
q=long(q);
sp=size(p);
sq=size(q);
if ~all(sp==sq)&prod(sp)~=1&prod(sq)~=1
    error('Error using ==> + Matrix dimensions must agree.')
end

if prod(sp)==1
    r.potencia=zeros(sq);
    r.decimales=zeros(sq);
    for i=1:sq(1)
        for j=1:sq(2)
            A.subs={[i,j]} ;
            if (p==0)|(q.potencia(i,j)-p.potencia > 20)
                if q.decimales(i,j)~=0
                r.potencia(i,j)=q.potencia(i,j);
                r.decimales(i,j)=q.decimales(i,j);
                else
                r.potencia(i,j)=p.potencia;
                r.decimales(i,j)=p.decimales;
                end

            elseif (subsref(q,A)==0)|(q.potencia(i,j)-p.potencia < -20)
                if p.decimales~=0
                r.potencia(i,j)=p.potencia;
                r.decimales(i,j)=p.decimales;
                else
                r.potencia(i,j)=q.potencia(i,j);
                r.decimales(i,j)=q.decimales(i,j);
                end

            else
                r.potencia(i,j)=p.potencia;
                r.decimales(i,j)=p.decimales+q.decimales(i,j)*(10^(q.potencia(i,j)-p.potencia));
            end
        end
    end
    r=long(r.decimales,r.potencia);
elseif prod(sq)==1
    r=q+p;  
else
    r.potencia=zeros(sq);
    r.decimales=zeros(sq);
    for i=1:sp(1)
        for j=1:sp(2)
            A.subs={[i,j]} ;
            if (subsref(p,A)==0)|(q.potencia(i,j)-p.potencia(i,j) > 20)
                
                if q.decimales(i,j)~=0
                r.potencia(i,j)=q.potencia(i,j);
                r.decimales(i,j)=q.decimales(i,j);
                else
                r.potencia(i,j)=p.potencia(i,j);
                r.decimales(i,j)=p.decimales(i,j);
                end
                
            elseif (subsref(q,A)==0)|(q.potencia(i,j)-p.potencia(i,j) < -20)
                if p.decimales(i,j)~=0
                r.potencia(i,j)=p.potencia(i,j);
                r.decimales(i,j)=p.decimales(i,j);
                else
                r.potencia(i,j)=q.potencia(i,j);
                r.decimales(i,j)=q.decimales(i,j);
                end

            else
                r.potencia(i,j)=p.potencia(i,j);
                r.decimales(i,j)=p.decimales(i,j)+q.decimales(i,j)*(10^(q.potencia(i,j)-p.potencia(i,j)));
            end
        end
    end
    r=long(r.decimales,r.potencia);
end