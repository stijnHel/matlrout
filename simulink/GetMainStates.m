function [R,VV,E,X]=GetMainStates(model,X0,X)
%GetMainStates - Get main states (based on eigen values) in a given state
%       [R,VV,E,X]=GetMainStates(model,X0,X)

bDisp=nargout==0;

if ~exist('X0','var')||isempty(X0)
	X0=Simulink.BlockDiagram.getInitialState(model);
end

if ~exist('X','var')||isempty(X)
	if isstruct(X0)
		X=X0;
	else
		X=Simulink.BlockDiagram.getInitialState(model);
	end
	C=regexprep({X.signals.blockName},'\n',' ');
	for i=1:length(C)
		if strncmp(C{i},model,length(model))
			C{i}=C{i}(length(model)+2:end);
		end
		X.signals(i).blockName=C{i};
		if isempty(X.signals(i).stateName)
			X.signals(i).stateName=C{i};
		end
	end
	[X.signals.blockName]=deal(C{:});
end

[A,~,~,~]=linmod(model,X0);
if any(isnan(A(:))|isinf(A(:)))
	warning('NaN''s or Inf''s found!')
	B=any(isnan(A)|isinf(A),2)';
	iOK=find(~B);
else
	iOK=1:size(A,1);
end
if size(A,1)==length(X.signals)
	jOK=iOK;
else
	jOK=iOK;
	j=0;
	for i=1:length(X.signals)
		n=X.signals(i).dimensions;
		jOK(j+1:j+n)=i;
		j=j+n;
	end
end
[VV,EE]=eig(A(iOK,iOK));
E=diag(EE).';
rE=real(E);
iE=imag(E);
iPosE=find(rE>0);
if any(iPosE)
	warning('Positive eigenvalues!:')
	nPosE=cell(1,length(iPosE));
	iPosEstates=cell(1,length(iPosE));
	for i=1:length(iPosE);
		[nPosE{i},iPosEstates{i}]=GetNames(iPosE(i),VV,X,jOK);
		fprintf('%d:\n',i)
		fprintf('     %s\n',nPosE{i}{:})
	end
else
	nPosE={};
	iPosEstates=[];
end
[MnE,iMnE]=sort(rE);
iMnE(MnE>MnE(1)/1e5|iE(iMnE)<0)=[];
MnE=E(iMnE);
nMnE=cell(1,length(iMnE));
iMnEstates=cell(1,length(iMnE));
for i=1:length(iMnEstates)
	[nMnE{i},iMnEstates{i}]=GetNames(iMnE(i),VV,X,jOK);
end

if any(iE)
	[MxIE,iMxIE]=sort(iE,2,'descend');
	iMxIE(MxIE<MxIE(1)/1e5|iE(iMxIE)<0)=[];
	MxIE=E(iMxIE);
	nMxIE=cell(1,length(iMxIE));
	iMxIEstates=cell(1,length(iMxIE));
	for i=1:length(iMxIEstates)
		[nMxIE{i},iMxIEstates{i}]=GetNames(iMxIE(i),VV,X,jOK);
	end
else
	MxIE=[];
	iMxIE=[];
	nMxIE=cell(1,0);
	iMxIEstates=cell(1,0);
end

%[~,iMxIE]=max(iE);
%[nMxIE,iMxEstates]=GetNames(iMxIE,VV,X,jOK);

R=struct('EposE',E(iPosE),'nPosE',{nPosE},'iPosE',iPosE,'iPosEstates',{iPosEstates}	...
	,'EminRealE',MnE,'nMinE',{nMnE},'iMnE',iMnE,'iMnEstates',{iMnEstates}		...
	,'EmaxImagE',MxIE,'nMaxE',{nMxIE},'iMxE',iMxIE,'iMxEstates',{iMxIEstates}	...
	,'stateNames',{{X.signals(jOK).blockName}}	...
	,'iOK',iOK,'jOK',jOK	...
	);

if bDisp
	fprintf('List of eigenvalues (and most important states) for negative real parts of eigenvalues:\n')
	fprintf('---------------------------------------------------------------------------------------\n')
	for i=1:length(R.nMinE);fprintf('   %d   (%8.2f,%8.2fi)\n...............\n',i,real(R.EminRealE(i)),imag(R.EminRealE(i)));printstr(R.nMinE{i});end
	fprintf('\n\n')
	fprintf('List of eigenvalues (and most important states) for high imaginary parts of eigenvalues:\n')
	fprintf('----------------------------------------------------------------------------------------\n')
	for i=1:length(R.nMaxE);fprintf('   %d   (%8.2f,%8.2fi)\n...............\n',i,real(R.EmaxImagE(i)),imag(R.EmaxImagE(i)));printstr(R.nMaxE{i});end
end

function [n,iV]=GetNames(B,VV,X,iOK)
V=abs(VV(:,B));
S=X.signals(iOK);
BH=V>.02;
iV=find(BH);
n={S(BH).blockName};
