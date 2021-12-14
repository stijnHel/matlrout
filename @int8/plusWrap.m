function s=plusWrap(a,b)
%int8/plusWrap - wrapping plus (overload to zero rather than truncate)
%     s=plusWrap(a,b) --> s = a (+) b
%           with a and b int8
%     s=plusWrap(A)  --> s = (sum) (A)
%           with A int8 matrix

if nargin==1
	s=sum(double(a));
else
	s=double(a)+double(b);
end
s=bitand(s,255);
if s>127
	s=s-256;
end
s=int8(s);
