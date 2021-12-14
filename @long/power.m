function r=power(c,n)
if abs(double(c).^double(n))~=0&abs(double(c).^double(n))~=Inf
    r=long(double(c).^double(n));
    
elseif ~(prod(size(c))==1|prod(size(n))==1|prod(double(size(c)==size(n))))
 error('Error using ==> .^ for LONG objects.\n Matrix dimensions must agree.')   
elseif abs(double(n))~=Inf

c=long(c);
n=double(n);
cP=c.potencia;
cD=c.decimales;
r=long(cD.^n,n.*cP);
else
error('Error using ==> .^ for LONG objects. Out of range')   
end
