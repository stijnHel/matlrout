function [X,I]=ReadNP(fName,bUsePython)
%ReadNP - Read NPY/NPZ-file (numpy)
%
%  X = ReadNP(fName,bUsePython)
%        Very basic functionality (e.g. no unpickling)

% see https://numpy.org/doc/stable/reference/generated/numpy.lib.format.html#module-numpy.lib.format

%... deze code was grotendeels al eens gemaakt...
%           EBTS --> ReadIRframe
%                toch nuttig daar nog eens te gaan kijken

if nargin<2||isempty(bUsePython)
	bUsePython = false;
end

fFull = fFullPath(fName,false,'.npy',false);
if isempty(fFull)	% then try npz
	fFull = fFullPath(fName,false,'.npz');
end
[~,~,fExt] = fileparts(fFull);
if bUsePython
	fP = fileparts(which(mfilename));
	if count(py.sys.path,fP) == 0
		insert(py.sys.path,int32(length(fP)),fP);
	end
	py.myPickleReader.load(fFull);
	X = uint8(py.myPickleReader.GetLastAflat());
	s = py.myPickleReader.GetSizeA();
	sizeX = [double(s{3}),double(s{2}),double(s{1})];
	T = py.myPickleReader.GetLastT();
	X = reshape(X,sizeX);
	I = double(T);
else
	if strcmpi(fExt,'.npz')
		Z=ReadZip(fFull);
		if length(Z)>1
			X = struct('name',{Z.fName},'V',[],'I',[]);
			for i=1:length(Z)
				[X(i).V,I1] = GetData(Z(i).fUncomp);
				X(i).I = I1;
			end
			return
		end
		Xraw = Z(1).fUncomp;
	else
		Z = [];
		fid = fopen(fFull);
		Xraw = fread(fid,[1 Inf],'*uint8');
		fclose(fid);
	end
	[X,I] = GetData(Xraw);
	if ~isempty(Z)
		I.name = Z.fName;
		I.name = Z.fName;
	end
end

function [X,I] = GetData(Xraw)
if Xraw(1)~=147 || ~strcmp(char(Xraw(2:6)),'NUMPY')
	error('Wrong start of the data?!')
end
v = Xraw(7:8);
lenHead = double(typecast(Xraw(9:10),'uint16'));
iEndHead = 10+lenHead;
sHead = deblank(char(Xraw(11:iEndHead)));

% Read header
CHword = false(1,255);
CHword('A':'Z') = true;
CHword('a':'z') = true;
CHword('0':'9') = true;
CHword(abs('_')) = true;
I = struct('version',v);
if sHead(1)~='{'
	error('Unexpected start of the header!')
end
i = 2;
while i<length(sHead)
	i = SkipSpace(sHead,i);
	if sHead(i)==''''
		[fld,i] = ReadString(sHead,i);
		if sHead(i)~=':'
			error('Expected ":" after the field name')
		end
		i = SkipSpace(sHead,i+1);
		if sHead(i)==''''
			[d,i] = ReadString(sHead,i);
		elseif sHead(i)=='('
			i = i+1;
			i1 = i;
			while sHead(i)~=')'
				i = i+1;
			end
			d = sscanf(sHead(i1:i-1),'%g,',[1 Inf]);
			i = i+1;
		else
			i1 = i;
			i = i+1;
			while CHword(abs(sHead(i)))
				i = i+1;
			end
			d = sHead(i1:i-1);
			i = i+1;
		end
		I.(fld) = d;
		i = SkipSpace(sHead,i);
		if sHead(i)==','
			i = i+1;
		end
	elseif sHead(i)=='}'	% the end of reading the header
		break
	else
		warning('Unexpected character in reading header - stopped reading')
		break
	end
end
if ~isfield(I,'descr')||~isfield(I,'shape')
	error('Not the required fields found! (descr and shape)')
end
s = I.descr;
if s(1)=='|'	% little guess
	bSwapBytes = false;
elseif any(s(1)=='<>')
	[~,~,E] = computer;
	bSwapBytes = (s(1)=='>' && E=='L') || (s(1)=='<' && E=='B');
else
	error('Unexpected type!')
end
nBytes = sscanf(s(3:end),'%d');
switch s(2)	% datatype
	case 'u'
		bSigned = false;
		dType = sprintf('uint%d',nBytes*8);
	case 's'	% guess!
		bSigned = true;
		dType = sprintf('int%d',nBytes*8);
	case 'f'
		if nBytes == 8
			dType = 'double';
		elseif nBytes==4
			dType = 'single';
		else
			error('Unknown type')
		end
	case 'O'	% object!
		nBytes = Inf;
		dType = 'object';
	otherwise
		error('Unknown datatype! (%s)',s)
end
X = Xraw(iEndHead+1:end);
if nBytes>1
	if strcmp(dType,'object')	% "pickled data"
		X = ReadPPickle(X);
		return
	end
	X=typecast(X,dType);
	if bSwapBytes
		X = swapbytes(X);
	end
elseif bSigned
	X = typecast(X,'int8');
end

if length(I.shape)>1
	X=reshape(X,I.shape(end:-1:1));
end

function [s,i] = ReadString(S,i)
if S(i)~=''''
	error('Call this function only at the start of a string!!!')
end
i = i+1;
i1 = i;
while S(i)~=''''
	i = i+1;
	if i>length(S)
		error('No end of string?!')
	end
end
s = S(i1:i-1);
i = SkipSpace(S,i+1);

function i = SkipSpace(s,i)
while s(i)==' '
	i = i+1;
end
