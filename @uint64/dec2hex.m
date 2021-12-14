function s=dec2hex(x,n)
%uint64/dec2hex - Convert decimal integer to hexadecimal string.
%   s=dec2hex(x,n)

s='0';
bShort=nargin<2||isempty(n);
if bShort
	s=s(ones(1,16));
else
	s=s(ones(1,n));
end

i=length(s)+1;
while x
	d=bitand(x,uint64(15));
	x=bitshift(x,-4);
	i=i-1;
	if d<10
		s(i)='0'+d;
	else
		s(i)='A'+(d-10);
	end
end
if bShort
	s=s(min(16,i):16);
end
