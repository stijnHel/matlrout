function [R,IN,NTest]=GenInputVarTester(Stest,fcn,iTypeArgIn,nElOut)
%GenInputVarTester - Exhaustive function of sets of different input values
%     [R,IN,NTest]=GenInputVarTester(Stest,fcn,iTypeArgIn,nElOut)
%          Stest: struct with variables with different values
%          fcn  : function handle
%          iTypeArgIn: 0 or 'vector': one input argument with all elements
%                      1 or 'struct': struct with separate values
%                          same structure as Stest, except only one value per field
%                      2 or 'args'  : separate arguements
%              the order of the arguments is the same as the fields in Stest
%          nElOut: number of output arguments to fcn
%
%          NTest is a vector of number of elements per variable
%            can be used for reshaping the output
%                       e.g. R=reshape(R,NTest) (in case of one output)
%
% example:
%     % plot grid points for the atan2 function
%     Stest=struct('x',0:10,'y',0:0.1:0.4);
%     [R,IN]=GenInputVarTester(Stest,@atan2,2,1);
%     figure
%     plot3(IN(:,1),IN(:,2),R,'o');grid
%
% constant inputs can be added by having just one value in a field of Stest.

switch iTypeArgIn
	case 'vector'
		iTypeArgIn=0;
	case 'struct'
		iTypeArgIn=1;
	case 'args'
		iTypeArgIn=2;
	case {0,1,2}
		% OK
	otherwise
		error('Wrong input for iTypeArgIn')
end

fNames=fieldnames(Stest)';
nVars=length(fNames);
NTest=zeros(1,nVars);
for i=1:nVars
	NTest(i)=length(Stest.(fNames{i}));
end
nTests=prod(NTest);
ITest=ones(1,nVars);
ITest(2)=0;
ITest(1)=NTest(1)+1;
IN=zeros(nTests,nVars);
% prepare inputs
inV=zeros(1,nVars);
switch iTypeArgIn
	case 0	% vector
		in={inV};
	case 1	% struct
		in={Stest};
	case 2	% args
		in=cell(1,nVars);
end

status('Testing all combinations',0)
nTested=0;
out=cell(1,nElOut);
R=cell(1,nElOut);
while true
	if ITest(1)>NTest(1)
		i=1;
		while i<nVars
			ITest(i)=1;
			i=i+1;
			ITest(i)=ITest(i)+1;
			if ITest(i)<=NTest(i)
				break
			end
		end		% while i
		if ITest(i)>NTest(i)	% the end
			break
		end
		status(nTested/nTests)
	end
	nTested=nTested+1;
	for i=1:nVars
		inV(i)=Stest.(fNames{i})(ITest(i));
	end
	switch iTypeArgIn
		case 0	% vector
			in{1}=inV;
		case 1	% struct
			for i=1:nVars
				in{1}.(fNames{i})(ITest(i))=inV(i);
			end
		case 2	% args
			in=num2cell(inV);
	end
	IN(nTested,:)=inV;
	[out{:}]=fcn(in{:});
	if nTested==1
		for i=1:nElOut
			R{i}=zeros(nTests,length(out{i}));
		end
	end
	for i=1:nElOut
		R{i}(nTested,:)=out{i};
	end
	ITest(1)=ITest(1)+1;	% next
end		% while true (all possibilities)
status
if nElOut==1
	R=R{1};
end
