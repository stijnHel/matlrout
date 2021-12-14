function SaveStructFields(varargin)
%SaveStructFields - Save the fields of a struct as var-names
%   SaveStructFields(fName,S)

%(not names input parameters used, to avoid confusion of names)

fieldNames914328975531=fieldnames(varargin{2})';
for fnS10923464=fieldNames914328975531
	assignval(fnS10923464{1},varargin{2}.(fnS10923464{1}));
end
save(varargin{1},fieldNames914328975531{:})
