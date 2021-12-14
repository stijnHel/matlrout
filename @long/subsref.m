function r=subsref(a,A)
P=a.potencia;
D=a.decimales;
s=size(P);
entrada=A.subs;

if length(entrada)==1
    inds=entrada{1};
    if ischar(inds)
        r.potencia=a.potencia(:);
        r.decimales=a.decimales(:);  
    elseif max(inds)>prod(s)
        error('Error indexing long array. Index exceeds matrix dimensions')
    else
        r.potencia=a.potencia(inds);
        r.decimales=a.decimales(inds);  
    end
    
elseif length(entrada)==2
    inds1=entrada{1};
    inds2=entrada{2};
    if ischar(inds1)&ischar(inds2)
        r.potencia=a.potencia(:,:);
        r.decimales=a.decimales(:,:);   
    elseif ischar(inds1)&~ischar(inds2)
        r.potencia=a.potencia(:,inds2);
        r.decimales=a.decimales(:,inds2);  
    elseif ~ischar(inds1)&ischar(inds2)
        r.potencia=a.potencia(inds1,:);
        r.decimales=a.decimales(inds1,:);
    else
        r.potencia=a.potencia(inds1,inds2);
        r.decimales=a.decimales(inds1,inds2);   
    end
    
else
    error('Error indexing long array')
end
r=class(r,'long');