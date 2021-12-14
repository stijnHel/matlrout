function [D,varargout]=GetAllSLLogs(Ddat,varargin)
%GetAllSLLogs - Get all Simulink-logs from a Simulink datalog object
%     D=GetAllSLLogs(Ddat)
%     [e,ne,de,e2,gegs]=GetAllSLLogs(Ddat)
%  Extra possibilities
%     ...=GetAllSLLogs(Ddat,<oper>,<oper-data>,...)
%            <oper>:
%                'add': add signal
%                'change' : change signal (mainly for offset/gains)
%                'setDim' : set dimension

nArgUsed=1;
if isa(Ddat,'Simulink.SimulationData.Dataset')
	n=numElements(Ddat);
	D=cell(1,n);
	for i=1:n
		Di=get(Ddat,i);
		name=Di.Values.Name;
		pth=getBlock(Di.BlockPath,1);
		if isempty(name)
			name=Di.Name;
			if isempty(name)
				name=pth;
			end
		end
		Di=Di.Values;
		if isempty(Di.Name)
			Di.Name=name;
		end
		%Di=struct(Di);
		D{i}=Di;
	end
	D=[D{:}];
elseif isa(Ddat,'simscape.logging.Node')
	id=Ddat.id;
	if nargin==1||~isstruct(varargin{1})
		hier=struct('path',id,'pathList',{{id}});
	else
		hier=varargin{1};
		hier.path=[hier.path '.' id];
		hier.pathList{1,end+1}=id;
		nArgUsed=2;
	end
	C=childIds(Ddat);
	n=length(C);
	D=cell(1,n);
	for i=1:n
		Di=GetAllSLLogs(Ddat.(C{i}),hier);
		D{i}=Di;
	end
	if n
		D=[D{:}];
	end
	if Ddat.series.points>0
		if n
			warning('!!!unexpected combination of series and children!')
		end
		D=struct('Name',id		...
			,'hier',hier	...
			,'Time',Ddat.series.time	...
			,'Data',Ddat.series.values	...
			,'unit',Ddat.series.unit		...
			,'dimension',Ddat.series.dimension);
	end
elseif isa(Ddat,'Simulink.ModelDataLogs')
	D=GetLogs(Ddat);
	if isempty(D)
	else
		for i=1:length(D)
			D{i}=struct(D{i});
		end
		D=[D{:}];
	end
else
	error('Unknown input to this function (%s)',mfilename)
end
dimChanges=struct('channels',{},'unit','');
while nArgUsed<nargin
	sigNames={D.Name};
	switch lower(varargin{nArgUsed})
		case 'add'
			vName=varargin{nArgUsed+1};
			if iscell(vName)
				vDim=vName{2};
				vName=vName{1};
				bSetDim=true;
			else
				vDim='-';
				bSetDim=false;
			end
			nArgUsed=nArgUsed+3;
			newSigEqn=varargin{nArgUsed-1};
			iVar=0;
			while any(newSigEqn=='"')
				iQ=find(newSigEqn=='"');
				if isscalar(iQ)||iQ(1)+1==iQ(2)
					error('Problem with interpreting equation! (%s)',newSigEqn)
				end
				sVar=newSigEqn(iQ(1)+1:iQ(2)-1);
				iVar=FindSignal(sigNames,sVar);
				if ~isscalar(iVar)
					error('Error signal ("%s") not found in equation (%s)'	...
						,sVar,newSigEqn)
				end
				newSigEqn=[newSigEqn(1:iQ(1)-1) 'D(' num2str(iVar) ').Data' newSigEqn(iQ(2)+1:end)];
			end
			if iVar>0
				Time=D(iVar).Time;
			else
				Time=[];	% at least one signal reference is expected!
			end
			try
				newSigD=eval(newSigEqn);
			catch err
				DispErr(err)
				error('Can''t evaluate new signal (%s)',sVar)
			end
			D(end+1).Name=vName; %#ok<AGROW>
			if isfield(D,'unit')
				D(end).unit=vDim;
			elseif bSetDim	% prepare for later (after ConvertLog2Meas)
				dimChanges(1,end+1).channels=length(D); %#ok<AGROW>
				dimChanges(end).unit=vDim;
			end
			D(end).Data=newSigD;
			D(end).Time=Time;
		case 'change'
			nArgUsed=nArgUsed+2;
			sVar=varargin{nArgUsed-1};
			iVars=FindSignal(sigNames,sVar);
			for iVar=iVars
				if ischar(varargin{nArgUsed})
					try
						D(iVar).Data=eval(['D(iVar).Data' varargin{nArgUsed}]);
					catch err
						DispErr(err)
						error('Error in changing a signal (''%s'' -> "%s")'	...
							,sigNames{iVar},varargin{nArgUsed})
					end
				elseif isa(varargin{nArgUsed},'function_handle')
					try
						fcn=varargin{nArgUsed};
						D(iVar).Data=fcn(D(iVar).Data);
					catch err
						DispErr(err)
						error('Error in changing a signal (''%s'')',sigNames{iVar})
					end
				else
					error('Wrong input for "change"')
				end
			end
			nArgUsed=nArgUsed+1;
		case 'setdim'
			nArgUsed=nArgUsed+1;
			sVar=varargin{nArgUsed};
			iVars=FindSignal(sigNames,sVar);
			if ~isempty(iVars)
				if isfield(D,'unit')
					[D(iVars).unit]=deal(varargin{nArgUsed+1});
				else	% prepare for later (after ConvertLog2Meas)
					dimChanges(1,end+1).channels=iVars; %#ok<AGROW>
					dimChanges(end).unit=varargin{nArgUsed+1};
				end
			end
			nArgUsed=nArgUsed+2;
		otherwise
			error('Unknown option')
	end
end
if nargout>1
	varargout=cell(1,nargout-1);
	[D,varargout{:}]=ConvertLog2Meas(D);
	for i=1:length(dimChanges)
		varargout{2}(dimChanges(i).channels)={dimChanges(i).unit};
	end
end

function DL=GetLogs(Ddat)
% to do (maybe): add hierachy information
%      not really needed since the path is included
%      ?in a separate vector?

persistent UNKNOWNtype

X=get(Ddat);
fn=fieldnames(X);
DL=cell(1,length(fn)-2);	% Name and BlockPath expected
nDL=0;
for i=1:length(fn)
	Xi=X.(fn{i});
	if isa(Xi,'Simulink.SubsysDataLogs')
		nDL=nDL+1;
		DL{nDL}=GetLogs(Xi);
	elseif isa(Xi,'Simulink.Timeseries')
		nDL=nDL+1;
		DL{nDL}={Xi};
	elseif isa(Xi,'Simulink.TsArray')
		nDL=nDL+1;
		DL{nDL}=GetLogs(Xi);
	elseif ischar(Xi)
		% do nothing
	elseif isnumeric(Xi)
		% do something?
	else
		tp=class(Xi);
		if isempty(UNKNOWNtype)
			UNKNOWNtype={tp};
			b=true;
		elseif any(strcmp(tp,UNKNOWNtype))
			b=false;
		else
			UNKNOWNtype{1,end+1}=tp; %#ok<AGROW>
			b=true;
		end
		if b
			warning('Unknown log type: %s: %s',fn{i},tp)
		end
	end
end
DL=[DL{1:nDL}];	% combine timeseries

function iVar=FindSignal(sigNames,sVar)
if sVar(end)=='*'
	if isscalar(sVar)
		iVar=1:length(sigNames);	% all
	else
		iVar=find(strncmp(sVar(1:end-1),sigNames,length(sVar)-1));
		if isempty(iVar)	% try case insensitive if none found
			iVar=find(strncmpi(sVar(1:end-1),sigNames,length(sVar)-1));
		end
	end
else
	iVar=find(strcmp(sVar,sigNames));
	if isempty(iVar)	% try case insensitive if none found
		iVar=find(strcmpi(sVar,sigNames));
	end
end
