function Sfound=find(S)
%struct/find - find non-empty nonzero fields
%   Sfound = find(S)
%         returns a struct with the found fields
%      if S is an array, a cell-array is returned

if isempty(S)
	Sfound=struct([]);
	return
elseif ~isscalar(S)
	Sfound=cell(size(S));
	for i=1:numel(S)
		Sfound{i}=find(S(i));
	end
	return
end

fn=fieldnames(S)';
CS=[fn;cell(1,length(fn))];
B=false(1,length(fn));
for i=1:length(fn)
	Si=S.(fn{i});
	B(i)=~(isempty(Si)||Si==0);
	CS{2,i}={Si};	% make sure that in creation the dimenstion stays (1x1)
end
CS=CS(:,B);
Sfound=struct(CS{:});
