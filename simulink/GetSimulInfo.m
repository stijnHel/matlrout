function D=GetSimulInfo(model,varargin)
%GetSimulInfo - Retrieves some interesting info of a simulink model
%    D=GetSimulInfo(model[...])
%       one option is available:
%             bExtended: get additional info from blocks

bExtended=false;
if nargin>1
	setoptions({'bExtended'},varargin{:})
end

[pth,fnm,fext]=fileparts(model);
if ~isempty(pth)||~isempty(fext)
	model=fnm;
end
bModelOpened=false;
if ~any(strcmp(model,find_system))
	if exist(model,'file')~=4
		error('Can''t find the model')
	end
	open_system(model);
	bModelOpened=true;
end
modelName=get_param(model,'Name');
	% normally the same as <model>, but not when file is renamed
	%  is this true????
if ~strcmp(model,modelName)
	warning('GETSIMI:diffName','model-name different from file name!')
end
[s,x0,stateblocks,tSample]=feval(model,[],[],[],0);
%nx=get_param(stateblocks,'Name');
nx=stateblocks';
X0=Simulink.BlockDiagram.getInitialState(model);
if isstruct(X0)
	C={X0.signals.blockName};
	C=regexprep(C,'\n',' ');
	C=regexprep(C,[model '/'],'...');
	[X0.signals.blockName]=deal(C{:});
	C={X0.signals.stateName};
	C=regexprep(C,'\n',' ');
	C=regexprep(C,[model '.'],'...');
	[X0.signals.stateName]=deal(C{:});
	iSig=zeros(1,length(x0));
	iS=0;
	for i=1:length(X0.signals)
		n=X0.signals(i).dimensions;
		iSig(iS+1:iS+n)=i;
		iS=iS+n;
	end
	X0.iSig=iSig;
end
s=cell2struct(num2cell(s([1:4 6 7])),fieldnames(simsizes));

inPorts=find_system(model,'searchdepth',1,'blocktype','Inport');
outPorts=find_system(model,'searchdepth',1,'blocktype','Outport');

nx=removeModelName(nx,modelName);
inPorts=removeModelName(inPorts,modelName);
outPorts=removeModelName(outPorts,modelName);

D=struct('name',modelName,'simsizes',s	...
	,'startTime',get_param(model,'StartTime')	...
	,'stopTime',get_param(model,'StopTime')	...
	,'stateNames',{nx},'initStates',x0	...
	,'X0',X0	...
	,'sampleTimes',tSample	...
	,'inPorts',{inPorts'},'outPorts',{outPorts'}	...
	);
vars = {};
if strcmp(get_param(model,'LoadExternalInput'),'on')
	D.ExternalInput = get_param(model,'ExternalInput');
	[Df,Vf,Of] = InterpreteFormula(D.ExternalInput,'-bMatlabForm');
	if isempty(Vf)
		D.ExternalInput = InterpreteFormula(Df,Vf,Of);
	else
		vars = [vars(:);Vf(:)]';
	end
end
if strcmp(get_param(model,'LoadInitialState'),'on')
	D.InitialState = get_param(model,'InitialState');
end

if bExtended
	D.extra=GetExtraInfo(model); %#ok<UNRCH>
	vars = union(vars(:)',D.extra.vars(:)');
end
if ~isempty(vars)
	D.vars = vars;
end

if bModelOpened
	close_system(model);
end

function S=removeModelName(S,modelName)
sRef=[modelName '/'];
lRef=length(sRef);
for i=1:length(S)
	if strncmp(S{i},sRef,lRef)
		S{i}=S{i}(lRef+1:end);
	else
		warning('GETSIMI:noModelName'	...
			,'!expected model-name, but not found (%s)!',S{i})
	end
end

function E=GetExtraInfo(model)
formTypes={	...
	'Constant','Value';
	'Fcn','Expr';
	'Gain','Gain';
	'Integrator','InitialCondition';
	'ModelReference','ModelFile';
	'ToWorkspace','VariableName';
	};
% formula's in the model settings should be read too!
%      ExternalInput
%      InitialState
%      TimeSaveName  (if SaveTime is on)
%      StateSaveName  (if SaveState is on)
%      OutputSaveName  (if SaveOutput is on)
%      FinalStateName  (if SaveFinalState is on)
%      
%      
%      
knownTypes={'Inport','Mux','Outport','Product','SubSystem','Sum'	...
	,'Math','Sqrt','Terminator','Trigonometry'};
L=find_system(model);
	% rather work with Blocks (recursive)
L(1)=[];	% normally the model itself
nL = length(L);
bLform=false(1,nL);
Formulas=cell(1,nL);
BTypes=cell(1,nL);
iBTypesUsed=zeros(1,nL);
iBType=zeros(1,nL);
Vlist={};
nForm=0;
nBT=0;
SStypes = cell(0,2);
SSunknown = {};
for i=1:nL
	f = [];
	Spars = [];
	Sinits = [];
	Mpars = [];
	Minits = [];
	lT = get_param(L{i},'BlockType');
	if nBT==0
		nBT = 1;
		BTypes{1} = lT;
		iBT = 1;
	else
		iBT = find(strcmp(lT,BTypes(1:nBT)));
		if isempty(iBT)
			nBT = nBT+1;
			BTypes{nBT} = lT;
			iBT = nBT;
		end
	end
	iBType(i) = iBT;
	b = strcmp(lT,formTypes(:,1));
	if any(b)
		f = get_param(L{i},formTypes{b,2});
		iBTypesUsed(iBT) = 1;
	elseif any(strcmp(lT,knownTypes))
		iBTypesUsed(iBT) = -1;
	else
		iBTypesUsed(iBT) = 0;
	end
	if strcmp(lT,'SimscapeBlock')
		% (!!) mask-parameters can also be used for "normal masks"!!
		MT = get_param(L{i},'MaskType');
		if isempty(SStypes)
			SStypes = {MT,1};
		else
			B = strcmp(SStypes(:,1),MT);
			if any(B)
				SStypes{B,2} = SStypes{B,2}+1;
			else
				SStypes(end+1,:) = {MT,1}; %#ok<AGROW>
			end
		end
		b = false;
		switch MT
			... Electrical
			case 'Capacitor'
				Mpars = {'c';'r';'g'};
				Minits = {'i';'v';'vc'};
				b = true;
			case 'DC Voltage Source'
				Mpars = {'v0'};
				Minits = {};
				b = true;
			case 'Inductor'
				Mpars = {'l';'r';'g'};
				Minits = {'i';'v';'i_L'};
				b = true;
			case 'Resistor'
				Mpars = {'R'};
				Minits = {'i';'v'};
				b = true;
			case 'Switch'
				Mpars = {'R_closed';'G_open';'Threshold'};
				Minits = {'i';'v'};
				b = true;
			case 'Diode'
				Mpars = {'Vf';'Ron';'Goff'};
				Minits = {'i';'v'};
				b = true;
			case {'Current Sensor','Electrical Reference','Voltage Sensor'}
				% no parameters
			... Mechanical
			case 'Mass'
				Mpars = {'mass'};
				Minits = {'v';'f'};
				b = true;
			case 'Translational Spring'
				Mpars = {'spr_rate'};
				Minits = {'v';'f';'x'};
				b = true;
			case 'Mechanical?Translational?Reference'	% newlines are not OK!!!!
				b = true;
			case {'Ideal Force Source'}
				% no parameters
			otherwise
				SSunknown = union(SSunknown,MT);
		end
		if b && ~(isempty(Mpars) && isempty(Minits))
			Spars = GetValues(L{i},Mpars);
			Sinits = GetValues(L{i},Minits);
			f = Spars(:,2);
		elseif b
			MN = get_param(L{i},'MaskNames');
			MV = get_param(L{i},'MaskValues');
			fprintf('%s:\n',MT)
			printstr('%s',MN,'%s',MV)
		end
	end
	if ~isempty(f)
		bLform(i) = true;
		if ischar(f)
			f = {f};
		end
		for iForm = 1:length(f)
			nForm = nForm+1;
			if ~isempty(f{iForm})
				Formulas{nForm} = f{iForm};
				[~,Vout] = InterpreteFormula(f{iForm},'-bMatlabForm');
				if ~isempty(Vout)
					if isempty(Vlist)
						Vlist = Vout;
					else
						Vlist = union(Vlist,Vout);
					end
				end
			end		% ~empty f(iForm)
		end		% for iForm
	end		% ~isempty(f)
	OP = get_param(L{i},'ObjectParameters');
	OPvalues = OP;
	fn = fieldnames(OP);
	for j = 1:length(fn)
		OPvalues.(fn{j}) = get_param(L{i},fn{j});
	end
	L{i,2} = OPvalues;
	L{i,3} = OP;
	L{i,4} = Spars;
	L{i,5} = Sinits;
end
[BTypes,ii]=sort(BTypes(1:nBT));
iB=ones(1,nBT);
iB(ii)=1:length(iB);
iBType=iB(iBType);
BTypes=struct('type',BTypes,'used',num2cell(iBTypesUsed(ii)));

SInfo={'model',{'Path','Name','Description','InitFcn','StartFcn'	...
		,'PauseFcn','ContinueFcn','StopFcn'};
	'simulation',{'SolverName','SolverMode','StartTime','StopTime'	...
		,'MaxStep','MinStep','ExternalInput','LoadInitialState','InitialState'};
	};

E=struct('formulas',{Formulas(1:nForm)},'bLform',bLform		...
	,'blocks',{L}	...
	,'BTypes',BTypes,'iBType',iBType	...
	,'vars',{Vlist}	...
	,'SStypes',{SStypes},'SSunknown',{SSunknown}	...
	);
for i=1:size(SInfo,1)
	C=SInfo{i,2};
	B=false(1,length(C));
	for j=1:length(B)
		v=get_param(model,C{1,j});
		B(j)=~isempty(v);
		C{2,j}={v};
	end
	C=C(:,B);
	E.(SInfo{i})=struct(C{:});
end

function S = GetValues(B,M)
MN = get_param(B,'MaskNames');
MV = get_param(B,'MaskValues');

n = size(M,1);
S = cell(n,3);
for i=1:n
	Bv = strcmp(MN,M{i});
	if size(M,2)==1
		su = [];
	else
		su = M{i,2};
	end
	if isempty(su)
		su = [M{i},'_unit']; %#ok<AGROW>
	end
	Bu = strcmp(MN,su);
	if ~any(Bv) || ~any(Bu)
		printstr(MN)
		warning('Not enough info for block %s?! (%s - %s)',get_param(B,'MaskType'),M{i},su);
	else
		S{i,1} = M{i};
		S{i,2} = MV{Bv};
		S{i,3} = MV{Bu};
	end
end
