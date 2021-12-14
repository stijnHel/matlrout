function D=min(D1,D2)
%struct/min - Minimum fields of structures from each other

if ~isstruct(D1)
	error('This function (currently) only works if the first argument is a struct')
end

if ~isscalar(D1)
	error('structures must be scalars (currently)')
end

fn1=fieldnames(D1);
CD=[fn1';cell(1,length(fn1))];
B=false(1,length(fn1));
if isnumeric(D2)	% minus(<struct>,numeric)
	if ~isscalar(D2)
		error('numerical input arguments must be scalars')
	end
	for i=1:length(fn1)
		if isnumeric(D1.(fn1{i}))
			if isscalar(D2)||isequal(size(D1.(fn1{i})),size(D2))
				CD{2,i}=min(D1.(fn1{i}),D2);
				B(i)=true;
			else
				warning('size of two corresponding fields is not equal (%s)'	...
					,fn1{i})
				B(i)=true;
			end
		end		% if numeric
	end		% for i
else	% minus(<struct>,<struct>)
	for i=1:length(fn1)
		if isnumeric(D1.(fn1{i}))
			if ~isfield(D2,fn1{i})
			elseif isequal(size(D1.(fn1{i})),size(D2.(fn1{i})))
				CD{2,i}=min(D1.(fn1{i}),D2.(fn1{i}));
				B(i)=true;
			else
				warning('size of two corresponding fields is not equal (%s)'	...
					,fn1{i})
				B(i)=true;
			end
		end
	end		% for i
	
end		% minus(<struct>,<struct>)
D=struct(CD{:,B});
