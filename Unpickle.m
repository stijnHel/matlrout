function out = Unpickle(in,varargin)
%UnpickleComp - Unpickle data (Python.pickle)
%      x = Unpickle(pickle)
%
% other use
%     fcn = Unpickle('function',opcode) -- returns a function to interpret a pickle-opcode

% Zeker nog te doen!!!
%    - BUILD
%    - sommige getallen in "network byte order"!!!
%    - uint64 <-> double vergissing?

global PICKLEINFO
	% this should be a persistent variable - but during development this is
	% a global
	% !!!!!!!!!!!!!! use in subfunction !!!!!!!!!!

if isempty(PICKLEINFO)
	if exist('PICKLEINFO.mat','file')
		PICKLEINFO = load('PICKLEINFO');
		PICKLEINFO = PICKLEINFO.PICKLEINFO;
			% ? OK with function handles?
	else
		PICKLEINFO = GetPickleData(false);
	end
end

if ischar(in)
	switch in
		case 'function'
			BINNUMs = ['JKM' char([138 139])];
			BINFLOATs = 'G';
			TXTNUMs = 'ILF';
			TXTs = 'STUVX';
			BINBYTEs = ['BC',char([142])];
			opcode = varargin{1};
			if any(BINNUMs==opcode)
				B = [PICKLEINFO.code]==opcode;
				arg = PICKLEINFO(B).arg;
				nBytes = arg.n;
				bSigned = any('J'==opcode);
				out = @(x,ix,S,nS) UnpickleNUM(x,ix,nBytes,bSigned,S,nS);
			elseif any(BINFLOATs==opcode)
				B = [PICKLEINFO.code]==opcode;
				arg = PICKLEINFO(B).arg;
				nBytes = arg.n;
				out = @(x,ix,S,nS) UnpickleFLOAT(x,ix,nBytes,S,nS);
			elseif any(TXTNUMs==opcode)
				out = @(x,ix,S,nS) UnpickleTXTNUM(x,ix,S,nS);
			elseif any(TXTs==opcode)
				nLen = 0;
				bEmbEsc = false;
				if opcode=='S'
					bEmbEsc = true;
				elseif opcode=='T'
					nLen = 4;
				elseif opcode=='U'
					nLen = 1;
				elseif opcode=='V'
					% unicode
				elseif opcode=='X'
					nLen = 4;	% unicode
				end
				out = @(x,ix,S,nS) UnpickleString(x,ix,nLen,bEmbEsc,S,nS);
			elseif any(BINBYTEs==opcode)
				if opcode=='B'
					nLen = 4;
				elseif opcode=='C'
					nLen = 1;
				elseif opcode==142
					nLen = 8;
				end
				out = @(x,ix,S,nS) UnpickleBytes(x,ix,nLen,S,nS);
			else
				out = @(x,ix,S,nS) UnpickleComp(opcode,x,ix,S,nS);	% currently simple...
			end
		otherwise
			error('Not implemented functionality - or wrong use of this function')
	end
	return
end
x = in;
ix = 0;
S = struct('typ',cell(1,1000),'data',[]);
S(1).typ = 'global';
nS = 1;
while ix<=length(x)
	ix = ix+1;
	opcode = char(x(ix));
	if opcode == '.'
		if nS>1
			warning('Not OK!')
			break
		end
	end
	B = [PICKLEINFO.code]==opcode;
	OC = PICKLEINFO(B);
	if isempty(OC)
		error('Something went wrong!!!!')
	end
	fcn = OC.fcn;
	if isempty(fcn)
		fcn = Unpickle('function',OC.code);
		PICKLEINFO(B).fcn = fcn;
	end
	[x1,ix,S,nS] = fcn(x,ix,S,nS);
end
if nS>1
	out = S(1:nS);
else
	out = S(1).data;
end

function [X,ix,S,nS] = UnpickleComp(opcode,x,ix,S,nS)
global PICKLEINFO
B = [PICKLEINFO.code]==opcode;
OC = PICKLEINFO(B);
if isempty(OC)
	error('Unknown opcode')
end
X = [];
typPush = OC.name;
if opcode=='a'	% APPEND
	S(nS-1).data{1,end+1} = S(nS).data;
	nS = nS-1;
	typPush = [];
elseif opcode=='e'	% APPENDS
	[L,nS] = PullList(S,nS);
	S(nS).data = [S(nS).data,L];
	typPush = [];
elseif opcode=='c'	% GLOBAL
	[moduleName,ix] = UnpickleString(x,ix,0,false);
	[className,ix] = UnpickleString(x,ix,0,false);
	typPush = 'module.attr';
	X = {moduleName,className};
elseif opcode=='t'	% TUPLE
	[X,nS] = PullList(S,nS);
elseif opcode==133	% TUPLE1
	[el1,nS] = Pull(S,nS);
	X = {el1};
	typPush = 'TUPLE';
elseif opcode==134	% TUPLE2
	[el1,nS] = Pull(S,nS);
	[el2,nS] = Pull(S,nS);
	X = {el2,el1};
	typPush = 'TUPLE';
elseif opcode==135	% TUPLE3
	[el1,nS] = Pull(S,nS);
	[el2,nS] = Pull(S,nS);
	[el3,nS] = Pull(S,nS);
	X = {el3,el2,el1};
	typPush = 'TUPLE';
elseif opcode=='R'	% REDUCE
	[fcnArgs,nS] = Pull(S,nS);
	[fcnCall,nS] = Pull(S,nS);
	X = {fcnCall,fcnArgs};
elseif opcode == 'q'	% BINPUT
	ix = ix+1;
	idx = x(ix);
	Memo(true,idx,S(nS).data);
	typPush = '';	% don't push
elseif opcode == 'r'	% LONGBINPUT
	idx = double(typecast(x(ix+1:ix+4),'uint32'));
	ix = ix+4;
	Memo(true,idx,S(nS).data);
	typPush = '';	% don't push
elseif opcode == ']'	% empty list
	X = {};
elseif opcode == '1'	% LIST
	% (same as TUPLE!)
	[X,nS] = PullList(S,nS);
elseif ~isempty(OC.arg)
	if OC.arg.n<0
		error('Sorry, but free length arguments (opcode %d - %s) are not handled!'	...
			,opcode,OC.name)
	end
	if OC.arg.n>0
		ixNext = ix+OC.arg.n;
		X = x(ix+1:ixNext);
		ix = ixNext;
	end
end
if nargin>3 && ~isempty(typPush)
	[S,nS] = Push(S,nS,typPush,X);
end

function [X,ix,S,nS] = UnpickleNUM(x,ix,nBytes,bSigned,S,nS)
if nBytes>1 || ~bSigned
	typ = sprintf('int%d',nBytes*8);
	if ~bSigned
		typ = ['u' typ];
	end
	X = typecast(x(ix+1:ix+nBytes),typ);
else
	X = x(ix+1:ix+nBytes);
end
ix = ix+nBytes;
if nargin>4
	[S,nS] = Push(S,nS,'NUM',X);
end

function [X,ix,S,nS] = UnpickleFLOAT(x,ix,nBytes,S,nS)
if nBytes==8
	typ = 'double';
elseif nBytes==4	% not existing?!!
	typ = 'single';
else
	error('What type?!');
end
X = typecast(x(ix+nBytes:-1:ix+1),typ);	% bigendian
ix = ix+nBytes;
if nargin>3
	[S,nS] = Push(S,nS,'NUM',X);
end

function [X,ix,S,nS] = UnpickleTXTNUM(x,ix,S,nS)
ix = ix+1;
ix1 = ix;
while x(ix)~=10
	ix = ix+1;
end
X = sscanf(char(x(ix1:ix-1)),'%g');
if nargin>2
	[S,nS] = Push(S,nS,'TXT',X);
end

function [s,ix,S,nS] = UnpickleString(x,ix,nLen,bEmbEsc,S,nS)
if nLen==0
	ix = ix+1;
	ix1 = ix;
	while x(ix)~=10
		ix = ix+1;
	end
	s = char(x(ix1:ix-1));
else
	typ = sprintf('uint%d',nLen*8);
	lString = double(typecast(x(ix+1:ix+nLen),typ));
	ix = ix+nLen;
	s = char(x(ix+1:ix+lString));
	ix = ix+lString;
end
if bEmbEsc
	%!!!!!!!!!!!!!!nothing done here!!!!!!!!!!!!
end
if nargin>4
	[S,nS] = Push(S,nS,'STRING',s);
end

function [s,ix,S,nS] = UnpickleBytes(x,ix,nLen,S,nS)
typ = sprintf('uint%d',nLen*8);
lString = double(typecast(x(ix+1:ix+nLen),typ));
ix = ix+nLen;
s = x(ix+1:ix+lString);
ix = ix+lString;
if nargin>3
	[S,nS] = Push(S,nS,'BYTES',s);
end

function [S,nS] = Push(S,nS,typ,x)
nS = nS+1;
S(nS).typ = typ;
S(nS).data = x;

function [x,nS,typ] = Pull(S,nS)
x = S(nS).data;
typ = S(nS).typ;
nS = nS-1;

function [L,nS] = PullList(S,nS)
nS1 = nS;
while ~strcmp(S(nS).typ,'MARK')
	nS = nS-1;
end
L = {S(nS+1:nS1).data};
nS = nS-1;

function out = Memo(bStore, idx, data)
persistent MEMO MEMOidx
if isempty(MEMO)
	MEMO = cell(1,256);
	MEMOidx = 0:255;
end
if bStore
	if idx<256
		MEMO{idx+1} = data;
	else
		i = find(MEMOidx==idx);
		if isempty(i)
			i = length(MEMO)+1;
			MEMOidx(i) = idx;
		end
		MEMO{i} = data;
	end
elseif idx<256
	out = MEMO{idx+1};
else
	i = find(MEMOidx==idx);
	if isempty(i)
		error('Memo (%d) not found!',idx)
	end
	out = MEMO{i};
end
