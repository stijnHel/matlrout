function A=readFMTCxml(fn)
%readFMTCxml - Reads an XML-file from FMTC measurements
%     A=readFMTCxml(fn)

% general part
A=readxml(fn,false);
I=A.children(2).children;
A=simplify(I);
% more specific part
if isfield(A,'data')
	sigs=struct2cell(A.data);
	A.signals=cat(2,sigs{:});
	A=rmfield(A,'data');
end

function A=simplify(I)
L={I.tag};
uL=unique(L);
while length(L)~=length(uL)
	for i=1:length(uL)
		ii=strmatch(uL{i},L,'exact');
		if length(ii)>1
			for j=1:length(ii)
				L{ii(j)}=[L{ii(j)} '_' num2str(j)];
			end
		end
	end
	uL=unique(L);
end
D={I.data};
for i=1:length(D)
	if iscell(D{i})&&length(D{i})==1
		D{i}=D{i}{1};
	end
	if isempty(D{i})
		if ~isempty(I(i).children)
			D{i}=simplify(I(i).children);
		end
	elseif ischar(D{i})
		v=str2double(D{i});
		if ~isnan(v)
			D{i}=v;
		end
	end
end
L=[L;D];
A=struct(L{:});
