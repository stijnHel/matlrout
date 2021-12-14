function r = char(p)
% LONG/CHAR   
% CHAR(p) is the string representation of p
s=size(p);
A=cell(s);
for j=1:s(2)
    for i=1:s(1)
     A(i,j)={[num2str(p.decimales(i,j),10) 'e' num2str(p.potencia(i,j),10)]};   
    end
end
r=char(A);

