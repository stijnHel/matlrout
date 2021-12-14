function s=plusWrap(a,b)
%uint16/plusWrap - wrapping plus (overload to zero rather than truncate)
%     s=plusWrap(a,b) --> s = a (+) b
%           with a and b uint16
%     s=plusWrap(A)  --> s = (sum) (A)
%           with A uint16 matrix

if nargin==1
	s=sum(double(a));
else
	s=double(a)+double(b);
end
s=bitand(s,65535);
s=uint16(s);
