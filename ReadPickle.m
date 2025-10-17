function D=ReadPickle(fName,bUsePython,varargin)
%ReadPickle - Read Python pickle-file
%      D=ReadPickle(fName[,bUsePython]);
%
%   two versions are implemented here: pure Matlab version and Python based
%        by default, Python based version is used if a python environment
%        is available.
%        The Python version seems to work, including some conversions from
%        Python-data to Matlab data, but that conversion is only limited.
%        The Matlab version doesn't work (but is a start to see the structure
%        of a pickle file.
%
% see also ReadPPickle(!!)

if nargin<2 || isempty(bUsePython)
	p = pyenv();
	bUsePython = ~isempty(p) && isprop(p,'Version') && ~isempty(p.Version);
end

if isa(fName,'uint8')	% already pickled data
	x = fName;
	if bUsePython
		D = PtUnpickle(x);
		return
	end
else	% file
	if bUsePython
		D = ReadPtPickle(fFullPath(fName,varargin{:}));
		return
	else
		fid = fopen(fFullPath(fName,varargin{:}));
		if fid<3
			error('Can''t open the file!')
		end
		x=fread(fid,[1 Inf],'*uint8');
		fclose(fid);
	end
end

if bUsePython
	D = ReadPtPickle(fFullPath(fName,varargin{:}));
	return
end
warning('This is just started!!!')

expectedStart = sscanf('80 3 7d 71 0 28','%x',[1 6]);
if ~all(x(1:6)==expectedStart)
	printhex(x(1:16))
	warning('Different start!')
end
ix = 7;
D = struct('name',cell(1,1000),'value',[]);
nD = 0;
while ix<length(x)
	if x(ix)~=88	% 0x58
		warning('Sorry different start compared to expected (0x%02x)',x(ix))
		break
	end
	lName = typecast(x(ix+1:ix+4),'uint32');
	if lName==0||lName>256
		warning('Something is going wrong!')
		break
	end
	ixNext = ix+4+lName;
	name = char(x(ix+5:ixNext));
	ix = ixNext;
	switch x(ix+1)
		case 113	% 0x71
			switch x(ix+2)
				case 1
					ix = ix+3;
					switch x(ix)
						case 71		% 0x47 - double precision float
							v = typecast(x(ix+8:-1:ix+1),'double');
							ix = ix+8;
						otherwise
							warning('Unknown subsubtype (0x71_01_%02x)',x(ix+3))
							break
					end
				otherwise
					warning('Unknown subtype (0x71_%02x)',x(ix+2))
					break
			end
		otherwise
			warning('unknown type (0x%02x)',x(ix+1))
			break
	end
	nD = nD+1;
	D(nD).name = name;
	D(nD).value = v;
	ix = ix+1;
end
D = D(1:nD);

function D = ReadPtPickle(fName)
fN = replace(fFullPath(fName),'\','\\');
pyrun('import pickle')
pyrun(['f=open("',fN,'","rb")']);
D = pyrun('D=pickle.load(f)','D');
pyrun('f.close()')
try
	D = UnPythonize(D);
catch err
	DispErr(err)
	warning('"Unpythonize didn''t work!')
end

function D = PtUnpickle(x)
pyrun('import pickle')
D = pyrun('D=pickle.loads(s)','D', s=x);
try
	D = UnPythonize(D);
	if isstruct(D) && isfield(D,'char')
		D.char = [D.char{:}];
	end
catch err
	DispErr(err)
	warning('"Unpythonize didn''t work!')
end
