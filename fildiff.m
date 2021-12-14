function f=fildiff(e)
% FILDIFF - filter aan de hand van vierde differenties

f=e(:);
l=length(f);
df1=diff(f);
df2=diff(df1);
df3=diff(df2);
df4=diff(df3);
f(3:l-2)=f(3:l-2)-3/35*df4;
f(1)=f(1)+df3(1)/5+3/35*df4(1);
f(2)=f(2)-0.4*df3(1)-df4(1)/7;
f(l-1)=f(l-1)+0.4*df3(l-3)-df4(l-4);
f(l)=f(l)-df3(l-3)/5+3/35*df4(l-4);
if size(e,1)==1
 f=f';
end