function [SYS,J1,U0]=MultiLinMod(model,T,X0,U0,para,varargin)
%MultiLinMod - Multiple calls to linmod in different conditions
%    This is currently only trial code
%   This function is a lot faster than calling linmod multiple times by
%   compiling this model only once.
%        [SYS,J]=MultiLinMod(model,T,X0,U0,para)
%               SYS is a struct-vector with all linearized models
%                    fields sys,dx,dy - where sys contains a,b,c,d (lower
%                      case because of linmod-sys output(!...!)
%               J is one jacobian struct (with mass matrix, ...), last state
%
%  Based on dlinmod

%???????????!!!!!!!!!!!!!!
%    vergelijk J.StateName en sys.StateName (bij --bABCDout)!!!!
%            lijkt OK te zijn

[bABCDout] = true;	% if false ==> use "sys" for linmod, otherwise [A,B,C,D]
options = varargin;
if ~exist('para','var')
	para = [];
	if ~exist('U0','var')
		U0 = [];
	end
end
if ~isnumeric(U0) && ~isempty(U0)
	if nargin>4
		options = [{U0,para},options];
		para = [];
	else
		options = {U0};
	end
	U0 = [];
elseif ~isnumeric(para) && ~isempty(para)
	options = [{para},options];
	para = [];
end
if ~isempty(options)
	setoptions({'bABCDout'},options{:})
end

% Find the normal mode model references
[~,normalrefs] = getLinNormalModeBlocks(model);
models = [model;normalrefs];

% Make sure the model is loaded
preloaded = false(numel(models,1));
for ct = 1:numel(models)
	if isempty(find_system('SearchDepth',0,'CaseSensitive','off','Name',models{ct}))
		load_system(models{ct});
	else
		preloaded(ct) = true;
	end
end

% Parameter settings we need to set/cache before linearizing
want = struct('AnalyticLinearization','on',...
	'BufferReuse', 'off',...
	'SimulationMode', 'normal',...
	'RTWInlineParameters','on', ...
	'InitInArrayFormatMsg', 'None');

% Determine the simulation status
simstat = strcmp(get_param(model,'SimulationStatus'),'stopped');

% Old argument parsing
x=X0;	% initialize (used in case of struct)

if isempty(para), para = [0;0;0]; end
if para(1) == 0, para(1) = 1e-5; end          % unused
if length(para)>1, t = para(2); else t = 0; end
if length(para)<3, para(3) = 0; end

% Turn on load initial state if the user has specified initial states.  This will
% allow externally specified initial states to be overwritten using the ic ports.
% If x,u specified set the output option to refine
if simstat
	if ~isempty(x)
		want.InitialState = '[]';
		want.LoadInitialState = 'on';
	end
	want.OutputOption = 'RefineOutputTimes';
	% If the user has specified an input then be sure that the load
	% initial state flag is turned off.  If it is left on then the model
	% api will not set these values.
	if ~isempty(U0)		%???!!!!! changes values for each input???
		tu = [t reshape(U0(1,:),1,size(U0,2))];
		want.ExternalInput = mat2str(tu);
		want.LoadExternalInput = 'on';
	end
	want.BlockJacobianDiagnostics = 'off';
end

SYS=struct('sys',cell(1,length(T)),'dx',[],'y0',[]);

% Load model, save old settings, install new ones suitable for linearization
have = local_push_context(models, want);

% Check to be sure that a single tasking solver is being used in all the models.
if ~checkSingleTaskingSolver({model}) && simstat
	DAStudio.error('Simulink:tools:dlinmodMultiTaskingSolver');
end


% Don't let sparse math re-order columns
autommd_orig = spparms('autommd');
spparms('autommd', 0);

try
	% Compile the model to set the state values
	if simstat
		feval(model, [], [], [], 'lincompile');
	end
	
	sizes = feval(model,[],[],[],'sizes');
	
	% If [x,u] are given we need some info from the model
	if isempty(x) && simstat
		x = sl('getInitialState',model);
	end

	% Time in the first column, u in the remaining columns
	if isempty(U0)
		if sizes(4)>0
			warning('Zeros for input assumed!')
			U0 = zeros(1,sizes(4));
		end
	elseif isvector(U0)
		if length(U0)~=sizes(4)
			error('Wrong number of model-inputs!')
		end
	elseif sizes(4)==size(U0,2)-1
		U0=interp1(U0(:,1),U0(:,2:end),T);
	elseif (size(U0,2) ~= sizes(4)) && ~isempty(U0)
		DAStudio.error('Simulink:tools:dlinmodWrongInputVectorSize',sizes(4));
	end

	nxz = sizes(1)+sizes(2);
	if ~isstruct(x) && length(x) < nxz
		DAStudio.warning('Simulink:tools:dlinmodExtraStatesZero');
		x = [x(:); zeros(nxz-length(x),1)];
	end
	
	% Force all rates in the model to have a sample hit and then evaluate the
	% outputs to ensure initial conditions are set for externally specified
	% integrators.
	feval(model, [], [], [], 'all');
	cStat = cStatus('Linearizing models',0);
	for iT=1:length(T)
		t=T(iT);
		if isnumeric(X0)
			x=X0(iT,:);
		else
			for iS=1:length(x.signals)
				x.signals(iS).values=X0.signals(iS).values(iT,:);
			end
		end
		if size(U0,1)<=1
			u = U0;
		else
			u=U0(iT,:);
		end
		for iLoop=1:3	% make sure the state are updated correctly
			SYS(iT).y0 = feval(model, t, x, u, 'outputs');
		end
	
		% Compute the linearization
		SYS(iT).dx = feval(model,t,x,u,'derivs');
		J1 = feval(model,[],[],[], 'jacobian');
		if iT==1
			J=J1(1,ones(length(T),1));
		else
			J(iT)=J1;
		end
		cStat.status(iT/length(T))
	end
	cStat.close()
	% Terminate the compilation
	if simstat
		feval(model, [], [], [], 'term');
	end
	
	NestedCleanUp;
catch e
	% Terminate the compilation
	if simstat && strcmp(get_param(model,'SimulationStatus'),'paused')
		feval(model, [], [], [], 'term');
	end
	
	% Restore sparse math and block diagram settings
	spparms('autommd', autommd_orig);
	local_pop_context(models, have);
	
	NestedCleanUp;
	rethrow(e);
end

[~,iOrderDX,Bknown]=StateStr2Vec(SYS(1).dx,J1);	% use second output of previous call!
dx_offset = zeros(length(Bknown),1);
%dx_offset(Bknown) = dxVec-sys_linmod.a(Bknown,:)*x0n ;

for iT=1:length(T)
	t=T(iT);
	if isnumeric(X0)
		x=X0(iT,:);
	else
		x.time=X0.time(iT);
		for iS=1:length(x.signals)
			x.signals(iS).values=X0.signals(iS).values(iT,:);
		end
	end
	dx_offset(Bknown) = [SYS(iT).dx.signals(iOrderDX).values];	% derivatives in linearized operating point
	SYS(iT).dx = dx_offset;
	if size(U0,1)<=1
		u = U0;
	else
		u=U0(iT,:);
	end
	if bABCDout
		[a,b,c,d] = sl('dlinmod_post',J(iT),model,t,0,x,u,0,0,para);
		SYS(iT).sys = var2struct(a,b,c,d);
	else
		SYS(iT).sys	= sl('dlinmod_post',J(iT),model,t,0,x,u,0,0,para);
	end
end
J1.iOrderX = iOrderDX;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested clean up function
	function NestedCleanUp
		% Restore sparse math and block diagram settings
		spparms('autommd', autommd_orig);
		local_pop_context(models, have);
		
		for ct_clean = 1:numel(models)
			if ~preloaded(ct_clean)
				close_system(models{ct_clean},0);
			end
		end
	end
%
end


function old_values = local_push_context(models, new)
% Save model parameters before setting up new ones

for ct = numel(models):-1:1
	% Save this before calling set_param() ..
	old = struct('Dirty', get_param(models{ct},'Dirty'));
	
	f = fieldnames(new);
	for k = 1:length(f)
		prop = f{k};
		have_val = get_param(models{ct}, prop);
		want_val = new.(prop);
		set_param(models{ct}, prop, want_val);
		old.(prop) = have_val;
	end
	old_values(ct) = old;
end
end
%---

function local_pop_context(models, old)
% Restore model parameters from previous context

for ct = numel(models):-1:1
	f = fieldnames(old(ct));
	for k = 1:length(f)
		prop = f{k};
		if ~isequal(prop,'Dirty')
			set_param(models{ct}, prop, old(ct).(prop));
		end
	end
	
	set_param(models{ct}, 'Dirty', old(ct).Dirty);
end
end
