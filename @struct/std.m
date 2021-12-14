function Ss = std(S,dim)
%struct/std - take std of all fields (if numeric and shapes are equal)
%    Ss = std(S[,dim])
%        S: struct-array
%        dim: dimension:
%             1-...: dimension in struct-array ----> not implemented!!!!!!
%            -1: all dimensions in struct-array
%             0: fields are summed in each struct-element
%        only handled fields are kept

if nargin<2||isempty(dim)
	dim = find(size(S)>1,1);
	if isempty(dim)
		dim=0;
	end
end

fn = fieldnames(S);
BfldOK = true(1,length(fn));
if dim==0
	Ss = S;
	for j=1:length(fn)
		for i=1:numel(S)
			if isnumeric(S(i).(fn{j}))
				Ss(i).(fn{j}) = std(Ss(i).(fn{j}));
			else
				BfldOK(j) = false;
				break
			end
		end
	end
elseif dim<0
	Ss = S(1);
	for j=1:length(fn)
		C = {S.(fn{j})};
		if ~all(cellfun(@isnumeric,C))
			BfldOK(j) = false;
			continue
		end
		SZ = cellfun(@size,C,'UniformOutput',false);
		if ~all(cellfun(@(x) isequal(x,SZ{1}),SZ))
			BfldOK(j) = false;
			continue
		end
		iD = length(SZ{1})+1;
		D = cat(iD,C{:});
		Ss.(fn{j}) = std(D,[],iD);
	end
else
	i = cell(1,ndims(S));
	[i{:}] = deal(':');
	i{dim} = 1;
	Ss = S(i{:});
	for i=1:length(fn)
	end
	error('Sorry, this is not implemented!')
end

for i=1:length(fn)
	if ~BfldOK(i)
		Ss = rmfield(Ss,fn{i});
	end
end
