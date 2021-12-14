function DispErr(err,sError)
%DispErr  - Display of error message
%         DispErr(err,sError)
%             err: error structure (e.g. from catch)
%             sError: error message
if nargin<2
	sError='error';
end
fprintf('%s! (%s - %s)\n   Stack:\n'	...
	,sError,err.identifier,err.message)
for i=1:length(err.stack)
	fprintf('         %2d: %-20s#%3d (%s)\n',i,err.stack(i).name	...
		,err.stack(i).line,err.stack(i).file)
end
