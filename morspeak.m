function out=morspeak(str,dotlen,dashlen)
%MORSPEAK Convert text into Morse code audio.
%	MORSPEAK('text') converts 'text' into Morse
%	code and plays it.
%       
%       MORSPEAK('text',dotlen) produces Morse code with
%       dots dotlen seconds long. Dashes are twice as long as dots.
%
%	MORSPEAK('text',dotlen,dashlen) produces Morse code
%	where the length of dots is dotlen (in seconds) and
%	the length of dashes is dashlen.	
%
%	Y = MORSPEAK('text') produces a vector containing
%	the Morse-encoded signal.

% D. Thomas 3/24/95

%  a .-     b -...   c -.-.   d -..    e .      f ..-.   g --.
%  h ....   i ..     j .---   k -.-    l .-..   m --     n -.
%  o ---    p .--.   q --.-   r .-.    s ...    t -      u ..-
%  v ...-   w .--    x -..-   y -.--   z --..

str=lower(str);

mortab = [1 2 0 0
          2 1 1 1
	  2 1 2 1
	  2 1 1 0
          1 0 0 0
 	  1 1 2 1
	  2 2 1 0
	  1 1 1 1
          1 1 0 0
          1 2 2 2
          2 1 2 0
          1 2 1 1
          2 2 0 0
          2 1 0 0
          2 2 2 0
          1 2 2 1
          2 2 1 2
          1 2 1 0
          1 1 1 0
          2 0 0 0
          1 1 2 0
	  1 1 1 2
          1 2 2 0
          2 1 1 2
          2 1 2 2
          2 2 1 1
	  3 3 3 3];

if (nargin == 1),
  dashlen = .14;
  dotlen  = .05;
elseif (nargin == 2),
  dashlen = 2*dotlen;
end
	

str(find(str == ' ')) = 123*(ones(size(find(str == ' '))));
str = str(:)-96;
code = mortab(str,:);
code = [code 3*ones(length(str),1)]';
code(find(code == 0)) = [];
code = [code(:) 3*ones(length(code(:)),1)]';
ind = find(code(1,:) == 3);
code(2,ind) = zeros(size(ind));
code = code(:);
code(find(code == 0)) = [];
code(find(code == 3)) = zeros(size(find(code == 3)));


tdot  = 0:1/8192:dotlen;
tdash = 0:1/8192:dashlen;
dot = sin(tdot*4000);
dash = sin(tdash*4000);
ldot = length(dot);
ldash = length(dash);
dot(1:10)=(.1:.1:1).*dot(1:10);
dot(ldot-9:ldot)=(1:-.1:.1).*dot(ldot-9:ldot);
dash(1:10)=(.1:.1:1).*dash(1:10);
dash(ldash-9:ldash)=(1:-.1:.1).*dash(ldash-9:ldash);


audio = zeros(ldot*sum(code < 2)+ldash*sum(code == 2)+1,1);
curpt=2;
audio(1)=3;

for i=1:length(code),
  if (code(i) == 1),
    audio(curpt:curpt+ldot-1) = dot;
    curpt=curpt+ldot+1;
  elseif (code(i) == 2),
    audio(curpt:curpt+ldash-1) = dash;
    curpt=curpt+ldash+1;
  else,
    curpt=curpt+ldash/2+1;
  end
end

if (nargout == 0),
  sound(audio);
else,
  out=audio;
end



    

