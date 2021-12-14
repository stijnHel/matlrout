function [Dres,MODELs]=CmpLinSims(varargin)
%CmpSimulations - Simulate multiple linear models and compare results
%      Dres=CmpLinSims(<models>,T,U[,X0])
%          models: (ss-class or struct with A,B,C,D matrices
%               list of models (one argument per model)
%               if different inputs are required, a cell-vector {model,U}
%                      can be given, where U is an input matrix or a
%                      selection of columns of "the main U"
%                      a third element gives an initial state vector
%                      a fourth element can give the model name

% state initial value input is not tested

MODELs = cell(20,4);	% {model,input,initial X,name}
nModels = 0;
T=[];
U=[];
x0=[];
nNumInputs = 0;
iOptions = 0;
bStoreX = true;
for i=1:nargin
	newModels = {};
	if isa(varargin{i},'ss') ||	...
			(isstruct(varargin{i})&&any(strcmpi('a',fieldnames(varargin{i}))))
		newModels = varargin(i);
	elseif iscell(varargin{i})
		newModels = varargin{i};
	elseif isnumeric(varargin{i})
		nNumInputs = nNumInputs+1;
		switch nNumInputs
			case 1
				T = varargin{i};
			case 2
				U = varargin{i};
			case 3
				x0 = varargin{i};
			otherwise
				error('Too many numerical inputs!')
		end
	elseif ischar(varargin{i})
		iOptions = i;
		break;
	else
		error('Unknown input (#%d)',i)
	end
	for iNew = 1:size(newModels,1)
		ss1 = newModels{iNew};
		if isstruct(ss1)
			if isfield(ss1,'a')
				ss1 = ss(ss1.a,ss1.b,ss1.c,ss1.d);
			else
				ss1 = ss(ss1.A,ss1.B,ss1.C,ss1.D);
			end
		end		% if isstruct
		nOut1 = size(ss1,1);	% assuming all equal outputs
		if nModels
			if nOut~=nOut1
				error('All models must have the same number of outputs!')
			end
		else
			nOut = nOut1;
		end
		MODELs{nModels+iNew,1} = ss1;
	end
	nModelsNew = nModels+size(newModels,1);
	if size(newModels,2)>1
		MODELs(nModels+1:nModelsNew,2:size(newModels,2)) = newModels(:,2:end);
	end
	nModels = nModelsNew;
end		% for i (input "receival")
if iOptions
	setoptions({'bStoreX'},varargin{iOptions:end})
end
if nNumInputs<2
	error('T and U must be supplied!')
end

if nModels==0
	error('No models found in the input arguments!')
elseif nModels<size(MODELs,1)
	MODELs=MODELs(1:nModels,:);
end
Dres=struct('Y',cell(1,nModels));
nCol = 1+(nOut>3)+(nOut>8);
nRow = ceil(nOut/nCol);
getmakefig('SimulationResults');
for iModel=1:nModels
	ss1=MODELs{iModel};
	[U1,x01]=deal(MODELs{iModel,2:3});
	if isempty(U1)
		U1=U;
	elseif size(U1,1)==1
		U1=U(:,U1);
	end
	if isempty(x01)
		x01=x0;
	end
	[Y1,~,X1]=lsim(ss1,U1,T,x01);
	Dres(iModel).Y = Y1;
	if bStoreX
		Dres(iModel).X = X1;
	end
	for jOut=1:nOut
		subplot(nRow,nCol,jOut)
		if iModel==2
			hold on
		end
		plot(T,Y1(:,jOut));
		if iModel==nModels
			hold off
			grid
		end
	end
end		% for iModel (run over models)
N=cellfun('length',MODELs(:,4));
if any(N)
	for i=1:nModels
		if N(i)==0
			MODELs{i,4}=sprintf('model#%d',i);
		end
	end
	hL = legend(MODELs(:,4));
	set(hL,'Interpreter','none')
end
