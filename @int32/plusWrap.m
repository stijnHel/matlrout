function s=plusWrap(a,b)
%int32/plusWrap - wrapping plus (overload to zero rather than truncate)
%     s=plusWrap(a,b) --> s = a (+) b
%           with a and b int32
%     s=plusWrap(A)  --> s = (sum) (A)
%           with A int32 matrix

if nargin==1
	s=sum(double(a));
else
	s=double(a)+double(b);
end
s=bitand(s,4294967295);
if s>2147483647
	s=s-4294967296;
end
s=int32(s);
