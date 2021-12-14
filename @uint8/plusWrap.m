function s=plusWrap(a,b)
%uint8/plusWrap - wrapping plus (overload to zero rather than truncate)
%     s=plusWrap(a,b) --> s = a (+) b
%           with a and b uint8
%     s=plusWrap(A)  --> s = (sum) (A)
%           with A uint8 matrix

if nargin==1
	s=sum(double(a));
else
	s=double(a)+double(b);
end
s=uint8(bitand(s,255));
