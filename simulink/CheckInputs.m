function [bOK,iOK,C]=CheckInputs(model,INPUTS)
%CheckInputs - compare inputs of a Simulink model with given inputs
%    CheckInputs(model,INPUTS)
%          model : name of Simulink model
%                  struct: result of GetSimulInfo
%          INPUTS: inputs given to CreateInputMatrix
%
% see also CreateInputMatrix, GetSimulInfo

if isstruct(INPUTS)
	inNames=fieldnames(INPUTS);
elseif ~iscell(INPUTS)
	error('INPUTS must be a struct or a cell-array/vector')
elseif isvector(INPUTS)
	inNames=INPUTS;
else
	inNames=INPUTS(:,1);
end
if ~all(cellfun(@ischar,inNames))
	error('Given inputs must be all names!')
end

if ischar(model)
	S=GetSimulInfo(model);
elseif ~isstruct(model)
	error('Wrong model input (#1)')
elseif ~isscalar(model)||~isfield(model,'inPorts')
	error('Wrong structure as model input (#1)')
else
	S=model;
end
if length(inNames)~=length(S.inPorts)
	error('Number of inputs to the model doesn''t match the number of given inputs (%d<->%d)'	...
		,length(S.inPorts),length(inNames))
end
N_s=cellfun('length',S.inPorts);
N_i=cellfun('length',inNames);
sForm_s=sprintf('%%-%ds',max(N_s));
sForm_i=sprintf('%%-%ds',max(N_i));
Cok={'different','OK','probably OK'};
iOK=strcmpi(inNames(:)',S.inPorts)+1;
for i=find(iOK==1)	% for all not-OK's, try "simplified names"
	s1=inNames{i};
	s2=S.inPorts{i};
	s1(s1=='_'|s1==' ')=[];
	s2(s2=='_'|s2==' ')=[];
	if strncmpi(s1,s2,min(length(s1),length(s2)))
		iOK(i)=3;
	end
end
C=[inNames(:)';S.inPorts;Cok(iOK)];
fprintf([sForm_i ' --> ' sForm_s ' - %s\n'],C{:})
if nargout
	bOK=all(iOK>1);
end

