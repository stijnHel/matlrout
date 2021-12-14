function A=subsasgn(A,S,B)
% SUBSASGN Define index assignment for LONG objects
B=long(B);
inds=S.subs;
if length(inds)==1
    inds=inds{1};
    if ischar(inds)
       A.potencia(:)=B.potencia;
       A.decimales(:)=B.decimales;
    else
       A.potencia(inds)=B.potencia;
       A.decimales(inds)=B.decimales;
    end
elseif length(inds)==2
   inds1=inds{1};
   inds2=inds{2};
   
    if ischar(inds1)&ischar(inds2)
       A.potencia(:,:)=B.potencia;
       A.decimales(:,:)=B.decimales;
   elseif ischar(inds1)&~ischar(inds2)
       A.potencia(:,inds2)=B.potencia;
       A.decimales(:,inds2)=B.decimales;
   elseif ~ischar(inds1)&ischar(inds2)
       A.potencia(inds1,:)=B.potencia;
       A.decimales(inds1,:)=B.decimales;
   else    
       A.potencia(inds1,inds2)=B.potencia;
       A.decimales(inds1,inds2)=B.decimales;
   end

else
    error('Too much indexes')
end


