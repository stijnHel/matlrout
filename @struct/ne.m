function [B,S1,S2] = ne(S1,S2,varargin)
%struct/ne - Test of fields of structures are not equal
%   B = ne(S1,S2)
%     or
%   B = S1 ~= S2

[bExactFields] = false;
[bSortFields] = true;
[bIntersecFields] = true;
[iMaxRecursive] = 0;
[bRemoveEquals] = false;

if ~isstruct(S1)||~isstruct(S2)
	error('Both inputs must be of type struct!')
end

if nargin>2
	setoptions({'bExactFields','bSortFields','bIntersecFields'	...
		,'iMaxRecursive','bRemoveEquals'}	...
		,varargin{:})
end

sS=size(S1);
B=S1;
if ~isequal(sS,size(S2))
	if ~(isscalar(S1)||isscalar(S2))
		error('Both inputs must be of the same size!')
	end
	if isscalar(S1)
		sS=size(S2);
		B=S2;
	end
end

fn1=fieldnames(S1);
fn2=fieldnames(S2);
fn=fn1;

bEqualNames=isequal(fn1,fn2);
if ~bEqualNames
	if bExactFields
		error('Different fields of structs!')
	end
	fn1S=sort(fn1);
	fn2S=sort(fn2);
	if bSortFields
		fn=fn1S;
		if ~isequal(fn1S,fn2S)
			if bIntersecFields
				fn=intersect(fn1S,fn2S);
				if isempty(fn)
					error('No matching fields!')
				end
			else
				error('Not the same fields in structs!')
			end
		end
	elseif bIntersecFields
		fn=intersect(fn1S,fn2S);
		if isempty(fn)
			error('No matching fields!')
		end
	end
	F=[fn';cell(1,length(fn))];
	F{2}=cell(sS);
	B=struct(F{:});
end

for i=1:numel(B)
	for j=1:length(fn)
		if isscalar(S1)
			f1=S1.(fn{j});
		else
			f1=S1(i).(fn{j});
		end
		if isscalar(S2)
			f2=S2.(fn{j});
		else
			f2=S2(i).(fn{j});
		end
		b1=isequaln(f1,f2);
		if b1
			B(i).(fn{j})=false;
		elseif isstruct(f1)&&isstruct(f1)&&isequal(size(f1),size(f2))	...
				&&iMaxRecursive>0
			B(i).(fn{j})=ne(f1,f2,varargin{:},'iMaxRecursive',iMaxRecursive-1);
		else
			B(i).(fn{j})=true;
		end
	end		% for j (length(fn))
end		% for i (numel(B))
if bRemoveEquals
	for j=1:length(fn)
		if ~isstruct(B.(fn{j})) && ~any([B.(fn{j})])
			B = rmfield(B,fn{j});
			if nargout>1
				S1 = rmfield(S1,fn{j});
				S2 = rmfield(S2,fn{j});
			end
		end
	end
end
