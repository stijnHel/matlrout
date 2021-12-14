function D = GetPickleData(bMakeFcn)
%GetPickleData - retrieve data (from Python) to read pickle data in Matlab
%     D = GetPickleData()
%            uses python
%        The result is "python-less" data.
%  Uses Unpickle (to get "interpretation function")

if nargin==0||isempty(bMakeFcn)
	bMakeFcn = true;
end

pmPT = py.importlib.import_module('pickletools');
opcodes = pmPT.opcodes;

D = struct('name',[]	...
	,'code',cell(1,length(opcodes))	...
	,'arg',[]	...
	,'doc',[]	...
	,'proto',[]	...
	,'stack_before',[]	... from pickletools but will this be used?
	,'stack_after',[]	... from pickletools but will this be used?
	,'fcn',[]	...
	);

for i=1:length(opcodes)
	OC = opcodes{i};
	D(i).name = char(OC.name);
	D(i).code = char(OC.code);
	if isa(OC.arg,'py.pickletools.ArgumentDescriptor')
		D(i).arg = struct('name',char(OC.arg.name)	...
			,'n',double(OC.arg.n)	...
			,'doc',char(OC.arg.doc)	...
			);
	end
	D(i).proto = double(OC.proto);
	D(i).doc = char(OC.doc);
	if bMakeFcn
		D(i).fcn = Unpickle('function',D(i).code);
	end
end
