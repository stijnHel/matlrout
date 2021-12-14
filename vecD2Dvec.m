function D1=vecD2Dvec(D)
%vecD2Dvec - Convert vector of structures to structure of vectors
%      D1=vecD2Dvec(D)

bColumnVector=size(D,2)==1;

fn=fieldnames(D);
D1=D(1);
for i=1:length(fn)
	if all(cellfun(@isscalar,{D.(fn{i})}))
		D1.(fn{i})=[D.(fn{i})];
		if bColumnVector
			D1.(fn{i})=D1.(fn{i})';
		end
	else
		warning('This function works (currently) only on scalars!')
	end
end
