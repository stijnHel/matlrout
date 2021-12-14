function s = EncodeBASE64(x)
%EncodeBASE64 - Encode data as base64 (MIME's Base64 is used)
%       s = DecodeBASE64(x)
%   x is treated as uint8 data

Cmime = char(zeros(1,64));
Cmime( 1:26) = 'A':'Z';
Cmime(27:52) = 'a':'z';
Cmime(53:62) = '0':'9';
Cmime(63) = '+';
Cmime(64) = '/';

if any(x<0 | x>255)
	error('Sorry - data out of range! (0-255)')
end

lString = length(x)*4/3;
if rem(length(x),3)
	lString = ceil(lString);
	n = ceil(length(x)/3)*3;
	x(end+1:n) = 0;
end
X = [65536 256 1]*reshape(x,3,[]);
Y = [floor(X/262144);bitand(floor(X/4096),63);bitand(floor(X/64),63);bitand(X,63)];
s = Cmime(Y(:)'+1);
if length(s)>lString
	s = s(1:lString);
end
s = [s,'='];
