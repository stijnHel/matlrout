function [L,Lprog,Lwin] = GetLibsLoaded()
%GetLibsLoaded - trial to get loaded modules (non-Matlab related)
%      [L,Lprog,Lwin] = GetLibsLoaded()

S = evalc('version(''-modules'');');
L = regexp(S,newline,'split');
L = strtrim(L);
L(cellfun(@isempty,L)) = [];
L(startsWith(L,'ans ')) = [];
B = startsWith(L,'C:\Program');
if nargout>1
	Lprog = sort(L(B));
end
L(B) = [];
B = startsWith(L,'C:\Windows');
if nargout>1
	Lwin = sort(L(B));
end
L(B) = [];
L = sort(L);
