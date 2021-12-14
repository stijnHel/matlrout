function s=plusWrap(a,b)
%uint32/plusWrap - wrapping plus (overload to zero rather than truncate)
%     s=plusWrap(a,b) --> s = a (+) b
%           with a and b uint32
%     s=plusWrap(A)  --> s = (sum) (A)
%           with A uint32 matrix

if nargin==1
	s=sum(double(a));
else
	s=double(a)+double(b);
end
s=bitand(s,4294967295);
s=uint32(s);
