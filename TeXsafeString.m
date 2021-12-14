function s=TeXsafeString(s,bBackslash)
%TeXsafeString - Make a string safe to use in TeX-strings
%         s=TeXsafeString(s[,bBackslash])
%                 bBackslash - replaces also backslashes (so all
%                         TeX-formatation is lost
%                         default true

if nargin==1
	bBackslash=true;
end
if bBackslash
	s=strrep(s,'\','\\');	
end

cRep='^_';	% others?
	% first start with backslash-replacement if needed
for i=1:length(cRep)
	s=strrep(s,cRep(i),['\' cRep(i)]);	
end
