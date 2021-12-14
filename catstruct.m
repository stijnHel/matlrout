function D=catstruct(varargin)
%catstruct - Concatenate structures with handling disimilar fields
%   D=catstruct(D1,D2,...)
%   D=catstruct({D1,D2,...})

if iscell(varargin{1})
	Dlist=varargin{1};
	bOneInputUsed=true;
else
	Dlist=varargin;
	bOneInputUsed=false;
end

Nd=cellfun('length',Dlist);
D=Dlist{1};
iD=length(D);
fn=fieldnames(D);
D(sum(Nd)).(fn{1})=[];
for i=2:numel(Dlist)
	fn=fieldnames(Dlist{i});
	for j=1:length(Dlist{i})
		iD=iD+1;
		for k=1:length(fn)
			D(iD).(fn{k})=Dlist{i}(j).(fn{k});
		end
	end
end

if bOneInputUsed&&nargin>1
	D=catstruct(D,varargin{2:nargin});
end
