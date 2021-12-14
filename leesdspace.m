function [e,ne,de,e2,gegs]=leesdspace(fName)
%leesdspace - Reads dSpace log (to "standard format")
%   [e,ne,de,e2,gegs]=leesdspace(fName)

e2=[];

X=load(fFullPath(fName,false,'.mat'));
fn=fieldnames(X);
if length(fn)~=1
	error('Only one variable expected in MAT-file!')
end
X=X.(fn{1});
bMultiX=length(X.X)>1;
if bMultiX
	nX=cellfun('length',{X.X.Data});
	[nx,iX]=max(nX);
	if length(nX)>2
	else
	end
	i2=X.X(setdiff(1:length(nX),iX));
	Xx=X.X(iX);
	nY=cellfun('length',{X.Y.Data});
	Xy=X.Y(nY==nx);
else
	Xx=X.X;
	Xy=X.Y;
end
T=Xx.Data';
nChan=length(Xy);
e=zeros(length(T),nChan);
ne={Xy.Name};
if isfield(Xy,'Path')
	for i=1:length(ne)
		ne{i}=[Xy(i).Path '/' ne{i}];
	end
end
for i=1:nChan
	e(:,i)=Xy(i).Data;
end
de={Xy.Unit};

gegs=struct('name',fn,'T',T,'dt',(T(end)-T(1))/(length(T)-1)	...
	,'nX',Xx.Name);
extraFields={'Capture','Description','RTProgram','Info'};
for i=1:length(extraFields)
	if isfield(X,extraFields{i})
		gegs.(extraFields{i})=X.(extraFields{i});
	end
end
