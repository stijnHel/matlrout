function sPath=MakePath(D,Sref,field,del)
%MakePath - Build a path from a subsref-struct - from FindHierField
%
%    sPath=MakePath(D,Sref,field,del)
%
% see also FindHierField

if nargin<4
	del='/';
end

Di=subsref(D,Sref(1));
sPath=Di.(field);
for i=3:2:length(Sref)
	Di=subsref(D,Sref(1:i));
	sPath=[sPath del Di.(field)]; %#ok<AGROW>
end
