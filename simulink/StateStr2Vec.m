function [S,iOrderDX,Bknown] = StateStr2Vec(dx,J)
%StateStr2Vec - trial to remake (lost) function
%   NOT    [S,iOrderDX,Bknown] = StateStr2Vec(dx,J)
%       [S,iOrderDX,Bknown] = StateStr2Vec(dx,signals)
%           because of different order of signals in J <-> signals

% xNames = {dx.signals.stateName};
% for i=1:length(xNames)
% 	if isempty(xNames{i})
% 		xNames{i} = dx.signals(i).blockName;
% 	end
% end
xNames = {dx.signals.blockName};

% Sstate = J.stateName;
Sblock = J.blockName;
S = Sblock;
Bknown = false(1,length(S));
iOrderDX = zeros(size(xNames));
n = 0;
for i=1:length(S)
% 	if isempty(S{i})
% 		S{i} = Sblock{i};
% 	end
	B = strcmp(S{i},xNames);
	if any(B)
		Bknown(i) = true;
		k = find(B);
		if length(k)>1
			SstateName = J.stateName{i};
			xStates = {dx.signals(k).stateName};
			k(~strcmp(SstateName,xStates)) = [];
		end
		if n==0 || ~any(iOrderDX(1:n)==k)
			n = n+1;
			iOrderDX(n) = k;
		end
	end
end
