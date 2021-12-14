function varargout=loadvars(fName)
%loadvars - load data from a file - not forcing the same variable names
%    [v1,v2...]=loadvars(<filename>);
%  Except the difference that the variables are given as output arguemnts
%  (compared to load), "fFullPath" is used.

X=load(fFullPath(fName,false,'.mat'));
fFields=fieldnames(X);
if length(fFields)<nargout
	warning('Too many output arguments! (only %d variables available)',length(fFields))
elseif length(fFields)>nargout
	printstr(fFields)
	warning('More variables available than available - are the right variable returned?(')
end
varargout=cell(1,nargout);
for i=1:min(length(fFields),max(1,nargout))
	varargout{i}=X.(fFields{i});
end
