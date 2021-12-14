function [sysR,BnullX,BnullU,BnullY] = RemoveNULLstates(sys,varargin)
%RemoveNULLstates - Remove "NULL-states" from a ss-system
%         [sysR,BnullX,BnullU,BnullY] = RemoveNULLstates(sys,options)
%    With NULL-states, states with nothing but zeros in A,B,C matrices
%   options:
%       bRemoveInputs : remove inputs from the system
%          independent of this, BnullU is determined
%       bRemoveOutputs: remove outputs from the system
%          independent of this, BnullY is determined
%       Binputs       : selection of inputs to regard
%       Bstates       : selection of states to regard
%       Boutputs      : selection of outputs to regard
%          The last three options are added regarding the offset-problem
%              solution

bRemoveInputs = false;
bRemoveOutputs = false; % this has implications to the simulations!
Binputs = [];
Bstates = [];
Boutputs = [];

if nargin>1
	setoptions({'bRemoveInputs','bRemoveOutputs','Binputs','Bstates','Boutputs'}	...
		,varargin{:})
end

if isa(sys,'ss')||(isstruct(sys)&&isfield(sys,'a'))
	A = sys.a;
	B = sys.b;
	C = sys.c;
	D = sys.d;
else
	A = sys.A;
	B = sys.B;
	C = sys.C;
	D = sys.D;
end
if isempty(Binputs)
	Binputs = true(1,size(B,2));
elseif length(Binputs)~=size(B,2)
	error('Wrong input length for Binputs')
end
if isempty(Bstates)
	Bstates = true(1,size(A,2));
elseif length(Bstate)~=size(A,2)
	error('Wrong input length for Bstates')
end
if isempty(Boutputs)
	Boutputs = true(1,size(C,1));
elseif length(Binputs)~=size(B,2)
	error('Wrong input length for Binputs')
end
if isa(sys,'ss')||(isstruct(sys)&&isfield(sys,'StateName'))
	sStates = sys.StateName;
	sInputs = sys.InputName;
	sOutputs = sys.OutputName;
else
	sStates = cell(1,size(A,1));
	sInputs = cell(1,size(B,2));
	sOutputs = cell(1,size(C,1));
end

% Find state with:
%    all zeros in A-rows (no dX/dt as a function of X)
%    all zeros in A-columns (no dependency of state to other states)
%    all zeros in B-rows (no dX/dt as a function of U)
%    all zeros in C-columns (no dependency of state to output)

% Comments:
%   some inputs and outputs could be removed too
%   dependency of states towards output could be removed too, with care
%          (care about constant offsets!)
A1 = A;
B1 = B;
C1 = C;
D1 = D;
if ~all(Binputs)
	B1=B1(:,Binputs);
	D1=D1(:,Binputs);
end
if ~all(Bstates)
	A1=A1(Binputs,Binputs);
	B1=B1(Binputs,:);
	C1=C1(:,Binputs);
end
if ~all(Boutputs)
	C1=D1(Binputs,:);
	D1=D1(Binputs,:);
end

BnullX = all(A1==0,1)&all(A1==0,2)'&all(B1==0,2)'&all(C1==0,1);
if any(BnullX)
	Bkeep = ~BnullX;
	%sysR = modred(sysR,BnullX,'truncate');
	A = A(Bkeep,Bkeep);
	B = B(Bkeep,:);
	C = C(:,Bkeep);
	sStates(BnullX)=[];
	%!!!! sysR.OperPoint!!!!!!!
		% not updated here due to different orders in ss and x0
end

% Find unrelated inputs
BnullU = all(B1==0,1)&all(D1==0,1);
if bRemoveInputs
	if any(BnullU)
		B(:,BnullU) = [];
		D(:,BnullU) = [];
		sInputs(BnullU) = [];
	end
end

% Find unrelated outputs
BnullY = (all(C1==0,2)&all(D1==0,2))';
if bRemoveOutputs
	if any(BnullY)
		B(Bnully,:) = [];
		D(BnullY,:) = [];
		sOutputs(BnullY) = [];
	end
end

if isa(sys,'ss')
	sysR = ss(A,B,C,D);
	set(sysR,'StateName', sStates);
	set(sysR,'InputName', sInputs);
	set(sysR,'OutputName', sOutputs);
else
	sysR = sys;
	if isfield(sys,'A')
		sysR.A = A;
		sysR.B = B;
		sysR.C = C;
		sysR.D = D;
	else
		sysR.a = A;
		sysR.b = B;
		sysR.c = C;
		sysR.d = D;
	end
	sysR.StateName = sStates;
	sysR.InputName = sInputs;
	sysR.OutputName = sOutputs;
end
