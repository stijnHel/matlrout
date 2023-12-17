function [code,i,j,nbits]=getjpghufcode(x,i,j,H)
% GETJPGHUFCODE - Neemt 1 element uit huffman-gecodeerde data in JPEG-formaat

nbits=1;
m=bitshift(1,7-j);
a=double(bitand(double(x(i)),m)>0);
if j<7
	j=j+1;
	m=bitshift(m,-1);
else
	j=0;
	m=128;
	if x(i)==255
		if x(i+1)~=0
			%warning('?fout met stuffed byte?')
		else
			i=i+1;
		end
	end
	i=i+1;
end
while a>H.maxCodes(nbits)
	if bitand(double(x(i)),m)
		a=bitor(bitshift(a,1),1);
	else
		a=bitshift(a,1);
	end
	nbits=nbits+1;
	if j<7
		j=j+1;
		m=bitshift(m,-1);
	else
		j=0;
		m=128;
		if x(i)==255
			if x(i+1)~=0
				%warning('?fout met stuffed byte?')
			else
				i=i+1;
			end
		end
		i=i+1;
	end
end
code=H.x(H.valPtr(nbits)+double(a)-H.minCodes(nbits));
