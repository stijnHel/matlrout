function [Bout,fn,RB]=CmpStrFields(S1,S2,fn,varargin)
%CmpStrFields - Compare fields of a structure
%         [Bout,fn]=CmpStrFields(S1,S2[,fn])

bRecursive = false;
options=[];
if nargin<3
	fn=[];
elseif iscell(fn)
	options=varargin;
elseif ischar(fn)
	options=[{fn} varargin];
	fn=[];
end
if nargin<3||isempty(fn)
	fn1=fieldnames(S1);
	fn2=fieldnames(S2);
	if ~isequal(sort(fn1),sort(fn2))
		fn=intersect(fn1,fn2);
		if isempty(fn)
			error('No similar fields to compare!')
		end
		warning('Not equal structs! only matching fields are compared ((%d,%d)->%d)'	...
			,length(fn1),length(fn2),length(fn))
	else
		fn=fn1;
	end
end
if ~isempty(options)
	setoptions({'bRecursive'},options{:})
end

if numel(S1)==0
	if numel(S1)~=numel(S2)
		error('struct-arrays must have equal sizes!')
	end
	if nargout==0
		warning('Using this function counts on output arguments in case of struct-arrays!')
	end
	Bout=zeros(length(fn),numel(S1));
	for i=1:numel(S1)
		Bout(:,i)=CmpStrFields(S1(i),S2(i),fn,'bRecursive',bRecursive);
	end
	return
elseif numel(S2)==0
	error('struct-arrays must have equal sizes!')
end
B=false(1,length(fn));
if bRecursive
	RB=struct('B',cell(1,length(fn)),'fn',[],'RB',[]);
else
	RB=[];
end
for i=1:length(fn)
	B(i)=isequal(S1.(fn{i}),S2.(fn{i}));
	if bRecursive&&~B(i)&&isstruct(S1.(fn{i}))&&isstruct(S2.(fn{i}))
		[RB(i).B,RB(i).fn,RB(i).RB]=CmpStrFields(S1.(fn{i}),S2.(fn{i}));
	end
end

if nargout
	Bout=B;
else
	DispDiff(fn,B,RB)
end

function DispDiff(fn,B,RB,s0)
if nargin<4
	s0='';
end
lF=cellfun('length',fn);
sFrm=['%s%-' num2str(max(lF)) 's: %s\n'];
sEq={'not equal','equal'};
for i=1:length(fn)
	fprintf(sFrm,s0,fn{i},sEq{B(i)+1})
	if ~isempty(RB)&&~isempty(RB(i).B)
		DispDiff(RB(i).fn,RB(i).B,RB(i).RB,[s0 '    '])
	end
end
