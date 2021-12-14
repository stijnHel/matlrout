function s=dec2hex(d,n)
%int32/dec2hex - integer version of dec2hex
%     s=dec2hex(d)

if length(d)>1
	d=typecast(d,'uint32');
	s=dec2hex(max(d));
	if nargin<2||isempty(n)
		n=length(s);
	end
	s(length(d),1)='0';
	for i=1:length(d)
		s(i,:)=dec2hex(d(i),n);
	end
elseif d<0
	%d=double(d)+2^32;
	s=sprintf('%8x',typecast(d,'uint32'));
else
	s=sprintf('%x',d);
	if nargin>1&&~isempty(n)&&n>length(s)
		o='0';
		s=[o(1,n-length(s)),s];
	end
end
