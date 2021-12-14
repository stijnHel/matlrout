function r=eq(a,b)
a=long(a);
b=long(b);
aP=a.potencia;
aD=a.decimales;
bP=b.potencia;
bD=b.decimales;

if ~prod(double(size(a)==size(b)))&prod(size(a))~=1&prod(size(b))~=1
    error('Error using ==> == Matrix dimensions must agree')
end

if prod(size(a))==1
s=size(b);
r=zeros(s);
for i=1:s(1)
    for j=1:s(2)
        if (aD==bD(i,j))&(aP==bP(i,j))
            r(i,j)=1;    
        end
    end
end
   
    
elseif prod(size(b))==1
s=size(a);
r=zeros(s);
for i=1:s(1)
    for j=1:s(2)
        if (aD(i,j)==bD)&(aP(i,j)==bP)
            r(i,j)=1;    
        end
    end
end

else
s=size(a);
r=zeros(s);
for i=1:s(1)
    for j=1:s(2)
        if (aD(i,j)==bD(i,j))&(aP(i,j)==bP(i,j))
            r(i,j)=1;    
        end
    end
end
end


    