function [C,I,TS]=PrintSimdataContents(X,varargout)
%PrintSimdataContents - Print (summary) contents data of simulink log
%   PrintSimdataContents(X)
%   [C,I]=PrintSimdataContents(X);
%        Channel names

bPrint=nargout==0;
if nargin>1
	setoptions({'bPrint'},varargout{:})
end

if ~isa(X,'Simulink.SimulationData.Dataset')
	warning('Other type than expected?!')
end

if nargout
	C=X.getElementNames();
	I=cell(length(C),1);
	TS=cell(1,length(C));
end

for i=1:X.numElements
	if nargout
		I{i,1}=X{i}.BlockPath.getBlock(1);
		TS{i}=X{i}.Values;
	end
	if bPrint
		fprintf('%2d: %s (%s - "%s")\n',i,X{i}.Name,X{i}.Label,X{i}.BlockPath.getBlock(1))
		D=X{i}.Values.Data;
		sz=size(D);
		fprintf('          (%s %d',class(D),sz(1));
		fprintf('x%d',sz(2:end))
		fprintf(')\n')
	end
end
TS=[TS{:}];
