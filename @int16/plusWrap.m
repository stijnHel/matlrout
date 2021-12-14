function s=plusWrap(a,b)
%int16/plusWrap - wrapping plus (overload to zero rather than truncate)
%     s=plusWrap(a,b) --> s = a (+) b
%           with a and b int16
%     s=plusWrap(A)  --> s = (sum) (A)
%           with A int16 matrix

if nargin==1
	s=sum(double(a));
else
	s=double(a)+double(b);
end
s=bitand(s,65535);
if s>32767
	s=s-65536;
end
s=int16(s);
