function X=CombineStructs(varargin)
%CombineStructs - Combine possibly structure which are possibly not consistent
%    X=CombineStructs({structs})
%    X=CombineStructs(struct1,struct2)
%        structures are supposed to be scalars (or row arrays)

% het is niet moeilijk om van alles structs te maken, zodat
% scalar-limitatie weg mag!

if iscell(varargin{1})
	S=varargin{1};
else
	S=varargin;
end

FN=cell(1,length(S));

for i=1:length(S)
	FN{i}=fieldnames(S{i});
end
fn = unique(cat(1,FN{:}));

for i=1:length(S)
	if length(FN{i})<length(fn)
		if false
			fn1=setdiff(fn,FN{i});
			for j=1:length(fn1)
				S{i}(1).(fn1{j})=[];
			end
		else	% slightly faster
			for j=1:length(fn)
				if ~any(strcmp(FN{i},fn{j}))
					S{i}(1).(fn{j})=[];
				end
			end
		end
	end
end
X=[S{:}];
