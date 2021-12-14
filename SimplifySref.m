function R = SimplifySref(R,X)
%SimplifySref - Simplify sref-struct-vector
%    removes indexing (1) from scalar data
%         R = SimplifySref(R,X)

Bremove = false(1,length(R));
for i=1:length(R)
	if strcmp(R(i).type,'()')&&isequal(R(i).subs,{1})&&isscalar(X)
		Bremove(i) = true;
	else
		X = subsref(X,R(i));
	end
end
R(Bremove) = [];
