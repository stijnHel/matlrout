function D=MakeStructFromVars(varargin)
%MakeStructFromVars - Makes a structure from a set of variables
%     D=MakeStructFromVars(<variablenames>)

if nargin==1&&iscell(varargin{1})
	list=varargin{1};
else
	list=varargin;
end

V=cell(2,numel(list));
for i=1:numel(list)
	V{1,i}=list{i};
	V{2,i}=evalin('caller',list{i});
end
D=struct(V{:});
