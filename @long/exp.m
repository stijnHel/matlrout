function r=exp(c)
cP=c.potencia;
cD=c.decimales;

y0=double(c.*log10(exp(1)));
rP=floor(y0);
rD=exp(double(c-rP*log(10)));
r=long(rD,rP);
