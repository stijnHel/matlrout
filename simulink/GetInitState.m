function [X0,iPt]=GetInitState(X,iPt,t,time)
%GetInitState - Get initial state from Simulink log
%      X0 = GetInitState(X,iPt)
%      [X0,iPt] = GetInitState(X,[],t)	% if X contains time
%         with iPt the index to the sample point
%      X0 = GetInitState(X,<i>,<t>,time) if logged with struct without time
%
%      X can be a Structure log or a (Simulink-)Dataset.

% remark:
%   * Some parts are written as if iPt or t can be vectors rather than
%     scalars.  But it's possible that this won't work (always)!!!

bExternalTime = true;
if isstruct(X)
	if nargin<4
		time = X.time;
	end
	X0 = X;
	X0.time = [];
	nSignals = length(X.signals);
else	% assuming a dataset
	bExternalTime = false;
	time = X{1}.Values.time;
	nSignals = X.numElements();
	X0 = struct('time',[], 'signals',struct('label',X.getElementNames()	...
		,'blockName',[],'values',[],'stateName',''));
end
bTimeBased = isempty(iPt);
if bTimeBased
	% find indices based on time.
	%    in case of Dataset (where separate signals have their own time)
	%    this is overwritten.
	iPt = t;
	for i = 1:length(t)
		iPt(i) = findclose(time,t(i));	% no interpolation!
	end
	X0.time = t;
end

if isempty(X0.time)
	if isempty(time)
		X0.time = 0;
	else
		X0.time = time(iPt);
	end
end
for iSignal = 1:nSignals
	if isstruct(X)
		X0.signals(iSignal).values = X0.signals(iSignal).values(iPt,:);
	else
		if bTimeBased
			if ~bExternalTime && ~isequal(time,X{iSignal}.Values.Time)
				time = X{iSignal}.Values.Time;
				for i = 1:length(t)
					%iPt(i) = findclose(time,t(i));	% no interpolation!
					iPt(i) = find(time<=t(i),1,'last');
				end
			end
		end
		%X0.signals(iSignal).blockName = X{iSignal}.BlockPath.getBlock(1);
		%        previous line doesn't work when <LF> are included in the
		%        name.  The following solves this problem(?!!)
		blockName = find_system(X{iSignal}.BlockPath.getBlock(1));
		if ~isscalar(blockName)
			error('Problem with blockName (?!) "%s"',X{iSignal}.BlockPath.getBlock(1))
		end
		X0.signals(iSignal).blockName = blockName{1};
		X0.signals(iSignal).values = X{iSignal}.Values.Data(iPt,:);
		label = X{iSignal}.Label;
		if ~isempty(label)
			if ~ischar(label)
				label = char(label);
			end
			if strcmp(label,'CSTATE')
				X0.signals(iSignal).label = label;
				X0.signals(iSignal).stateName = X{iSignal}.Name;
			end
		end
	end
end
