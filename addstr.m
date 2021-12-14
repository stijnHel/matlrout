function s=addstr(s,s1)
% ADDSTR - add string to an array string
%     s=addstr(s,s1)
%
% Deze routine kan vervangen worden door de matlab-routine
%    strvcat

if size(s1,2)>size(s,2)
	s=[s zeros(size(s,1),size(s1,2)-size(s,2))];
end
s=[s;s1 zeros(size(s1,1),size(s,2)-size(s1,2))];
