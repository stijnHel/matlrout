function [ssRed,Dreduction,CRedAll]=RedModel(sys,varargin)
%RedModel - Tests with model reduction
%      [ssRed,Dreduction,CRedAll]=RedModel(sys,options)
%               sys: struct with A,B,C,D matrices
%                    ss-object
%      [ssRed,Dreduction,ssRedAll]=RedModel(A,B,C,D,options)
%
%           ssRed      - Reduced model
%           Dreduction - extra info about model reduction
%           CRedAll    - Different methods of model reduction
%                      {'method1',ss1;....}

bRemoveNULLstates = true;
bDispCmp = [];
bOffsetInput = false;	% an offset-input is used - not to be used to determine NULL-states
bOffsetState = false;	% an offset-state is used - not to be used to determine NULL-states
gLimit = 1e-8;	% limit used for gramian for balreal+modred method
method = [];	% method used in modred-function

if isstruct(sys)
	if isfield(sys,'A')
		sys_ss = ss(sys.A,sys.B,sys.C,sys.D);
	else
		sys_ss = ss(sys.a,sys.b,sys.c,sys.d);
	end
	options = varargin;
elseif isnumeric(sys)
	sys_ss = ss(sys,varargin{1:3});
	options = varargin(4:end);
else
	sys_ss = sys;
	options = varargin;
end

if ~isempty(options)
	setoptions({'gLimit','method','bRemoveNULLstates','bDispCmp'	...
		,'bOffsetInput','bOffsetState'},options{:})
end

if bRemoveNULLstates
	extraInputs={};
	if bOffsetInput
		extraInputs{1,end+1}='Binputs'; %#ok<UNRCH>
		extraInputs{1,end+1}=[true(1,size(sys_ss.B,2)-1) false];
	end
	if bOffsetState
		extraInputs{1,end+1}='Bstates'; %#ok<UNRCH>
		extraInputs{1,end+1}=[true(1,size(sys_ss.A,2)-1) false];
	end
	[sys_ss,BnullX,BnullU,BnullY] = RemoveNULLstates(sys_ss,extraInputs{:});
end

[sysBalanced,g,T,Ti]=balreal(sys_ss);
	% input/output balancing, with transformation matrices so that state
	% data can be converted between reduced and original model

elim = g<gLimit;
ssRed = modred(sysBalanced,elim,method);

Dreduction=var2struct(sysBalanced,g,elim,T,Ti	...
	,BnullX,BnullU,BnullY);

if nargout>2||(isscalar(bDispCmp)&&bDispCmp) %#ok<BDSCI,BDLGI>
	if isempty(bDispCmp)
		bDispCmp = true;
	end
	
	ssBalRed = balred(sys_ss,order(ssRed));	% to compare
	ssMinReal = minreal(sys_ss);
	ssSMinReal = sminreal(sys_ss);

	%?split high / low frequency?
		% freqsep

	CRedAll = {'balreal+Modred',ssRed;
		'balred',ssBalRed;
		'minreal',ssMinReal;
		'sminreal',ssSMinReal};

	if bDispCmp
		fprintf('balreal+modred: ');size(ssRed)
		fprintf('balred        : ');size(ssBalRed)
		fprintf('minreal       : ');size(ssMinReal)
		fprintf('sminreal      : ');size(ssSMinReal)
	end
end
