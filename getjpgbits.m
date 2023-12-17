function [a,i,j]=getjpgbits(x,i,j,n)
% GETJPGBITS - Neemt bits uit lijst (waarbij 0xFF..) 'verwerkt' worden.

if 8-j>=n
	a=double(bitand(2^n-1,bitshift(x(i),j+n-8)));
	j=j+n;
	if j>7
		j=0;
		i=nextbyte(x,i);
	end
else
	a=double(bitand(2^(8-j)-1,x(i)));
	n=n-8+j;
	i=nextbyte(x,i);
	while n>8
		a=bitshift(a,8)+double(x(i));
		n=n-8;
		i=nextbyte(x,i);
	end
	j=n;
	if n
		a=bitshift(a,n)+double(bitshift(x(i),n-8));
		if j>7
			j=0;
			i=nextbyte(x,i);
		end
	end
end


function i=nextbyte(x,i)
if x(i)==255
	if x(i+1)~=0
		%warning('?fout met stuffed byte?')
	else
		i=i+1;
	end
end
i=i+1;
