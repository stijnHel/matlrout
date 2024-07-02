function x=uint8(c)
%lvtime/uint8 - conversion to bytes (to save data)

x0=rem(c.t,256);
x3=floor(c.t/256);
x1=rem(x3,256);
x3=floor(x3/256);
x2=rem(x3,256);
x3=floor(x3/256);
x=uint8(reshape([x3;x2;x1;x0],1,16));
