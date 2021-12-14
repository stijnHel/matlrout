function display(r)
% LONG/DISPLAY Command window display of a LONG

if isequal(get(0,'FormatSpacing'),'compact')
   disp([inputname(1) ' =']);
else
   disp(' ')
   disp([inputname(1) ' =']);
   disp(' ');
end

s=size(r);
A=cell(s);
for j=1:s(2)
    for i=1:s(1)
     A(i,j)={[num2str(r.decimales(i,j),10) 'e(' num2str(r.potencia(i,j),10),')']};   
    end
end
disp(A);

