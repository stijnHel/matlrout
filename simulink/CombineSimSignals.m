function [X,nX,T]=CombineSimSignals(Xin,dt,varargin)
%CombineSimSignals - Combine simulink signals
%
% Set all signals in one array, assuming that all signals are sampled at
% the same rate(!).
%
%       [X,nX,T]=CombineSimSignals(Xin) - extract data from Xin
%            X: matrix with all signals in columns
%            nX: channel names - if signal has more than one dimension,
%               the same name is used multiple times
%       [X,nX]=CombineSimSignals(Xin,T) - interpolates in T
%       [X,nX,T]=CombineSimSignals(Xin,dt) - resamples with timestep dt
%       ..=CombineSimSignals(...,options)
%           options: pairs of name and value,
%                    or -xxx or --xxx for xxx is true or false
%                  bCombStateBlockNames: combine block and statenames
%                        if -1, automatic selection is used
%                  bOnlyStateNames: only extract state names (and don't
%                                   create T-matrix)

options=[];
if nargin>1
	if isnumeric(dt)
		options=varargin;
	else
		options=[{dt},varargin];
		dt=[];
	end
else
	dt=[];
end
bCombStateBlockNames=false;
bOnlyStateNames=false;
bBlockNames=false;
bReplaceLF=false;
iOrder=[];

if ~isempty(options)
	setoptions({'bCombStateBlockNames','bOnlyStateNames','bBlockNames'	...
		,'bReplaceLF','iOrder'}	...
		,options{:})
end
if isempty(iOrder)
	signals=Xin.signals;
else
	signals=Xin.signals(iOrder);
end

T=Xin.time;
N=[signals.dimensions];
nSignals=length(N);
nChannels=sum(N);
if ~isempty(dt)
	if isscalar(dt)
		Tn=(T(1):dt:T(end))';
	else
		Tn=dt(:);
	end
	X=zeros(length(Tn),nChannels);
	iX=0;
	I=[];
	for i=1:nSignals
		n1=N(i);
		iXn=iX+n1;
		if ~isfloat(signals(i).values)
			if isempty(I)
				i1=1;
				I=zeros(1,length(Tn));
				for j=1:length(Tn)
					while i1<length(T)&&T(i1)+1>=Tn(j)
						i1=i1+1;
					end
					I(j)=i1;
				end
			end
			for j=1:n1
				X(:,iX+j)=signals(i).values(I);
			end
		else
			X(:,iX+1:iX+n1)=interp1(T,signals(i).values,Tn);
		end
		iX=iXn;
	end
	T=Tn;
elseif ~bOnlyStateNames
	if nargout>2&&isempty(T)
		warning('No time was included!')
	end
	X=[signals.values];
	nChannels=size(X,2);
end
if isfield(signals,'stateName')
	if bBlockNames
		nX={signals.blockName};
	else
		nX={signals.stateName};
	end
else
	nX=cell(1,nSignals);
end
lName=cellfun('length',nX);
if bCombStateBlockNames||any(lName==0)
	if bCombStateBlockNames<0
		lSysName=find(signals(1).blockName=='/',1)-1;
		if isempty(lSysName)
			warning('Can''t extract the system name?!')
			lSysName=0;
		end
		sysName=signals(1).blockName(1:lSysName); %#ok<NASGU>
	else
		b=true; %#ok<NASGU>
	end
	for i=1:length(lName)
		if lName(i)==0
			nX{i}=signals(i).blockName;
		elseif bCombStateBlockNames
			if bCombStateBlockNames<0 %#ok<UNRCH>
				b=~strncmp(sysName,nX{i},lSysName);
			end
			if b
				nX{i}=[nX{i} ' - ' signals(i).blockName];
			end
		end
	end
end
if bReplaceLF
	for i=1:length(nX) %#ok<UNRCH>
		nX{i}(nX{i}==10)=' ';
	end
end
if any(N~=1)
	IDX = cell(1,length(nX));
	for i=1:length(nX)
		IDX{i} = i+zeros(1,N(i));
	end
	nX = nX([IDX{:}]);
end
if bOnlyStateNames&&nargout<2
	X=nX;
end
