function D = UnPythonize(D)
%        D = UnPythonize(Dpython)
% Convert Python-data to Matlab data for some datatypes
%    this code is called recursively
% other, less obvious cases, this is currently not done(!!)

typD = class(D);
switch typD
	case 'py.dict'
		D = struct(D);
		fn = fieldnames(D);
		for i=1:length(fn)
			D.(fn{i}) = UnPythonize(D.(fn{i}));
		end
	case 'py.int'
		if D<0
			if D>-2^31
				D = int32(D);
			else
				D = int64(D);
			end
		elseif D>2^31-1
			D = uint64(D);
		else
			D = uint32(D);
		end
	case {'py.list','py.tuple'}	% handle list and tuple the same
		D = cell(D);
		bNumeric = true;
		bInt = true;	% not (yet) used
		for i=1:length(D)
			D{i} = UnPythonize(D{i});
			bNumeric = bNumeric && isnumeric(D{i});
			bInt = bInt && isinteger(D{i});
		end
		if bNumeric
			if isempty(D)
				D = [];
			else
				Nd = cellfun(@ndims,D);
				S1 = cellfun('size',D,1);
				S2 = cellfun('size',D,2);
				if all(Nd==Nd(1)) && all(S1==S1(1)) && all(S2==S2(1))
					%D = [D{:}];	% be careful for "stupid Matlab numeric datatype combining"!!!!
					if Nd(1)>2
						warning('Numerical arrays with dimension larger than 2 are not combined into numerical arrays')
					else
						if S1(1)==1
							% combining vectors result in combining vectors as column vectors
							D = cat(1,D{:})';
						else
							% combining matrices
							D = cat(3,D{:});
						end
					end
				end
			end
		end
	case 'py.set'
		DD = cell(1,py.len(D));
		bNumeric = true;
		for i=1:length(DD)
			DD{i} = UnPythonize(D.pop());
			bNumeric = bNumeric && isnumeric(DD{i});
		end
		D = DD;
		if bNumeric
			D = [D{:}];	% be careful for "stupid Matlab numeric datatype combining"!!!!
		end
	case 'py.numpy.ndarray'
		% is e.g. >u2 also possible?
		switch char(D.dtype.str)
			case '<f4'
				D = single(D);
			case '<f8'
				D = double(D);
			case '|u1'
				D = uint8(D);
			case '<u2'
				D = uint16(D);
			case '<u4'
				D = uint32(D);
			case '<i1'	% (guessed(!))
				D = int8(D);
			case '<i2'	% (guessed(!))
				D = int16(D);
			case '<i4'	% (guessed(!))
				D = int32(D);
		end
	case 'py.numpy.int8'
		D = int8(D);
	case 'py.numpy.uint8'
		D = uint8(D);
	case 'py.numpy.int16'
		D = int16(int32(D));	% int16 from py.numpy.int16 gives an error?!
	case 'py.numpy.uint16'
		D = uint16(D);
	case 'py.numpy.int32'
		D = int64(D);	% (!!!) int32 results in an error, Matlab indicates: "Use int64 function to convert to a MATLAB array."!!!!
	case 'py.numpy.uint32'
		D = uint64(D);
	case 'py.numpy.int64'
		D = int64(D);
	case 'py.numpy.uint64'
		D = uint64(D);
	case 'py.str'
		D = char(D);
end
