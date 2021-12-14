function [D,X2_1]=MatchStates(X1,X2)
%MatchStates - Match states between two signal structures
%              [D,X2_1]=MatchStates(X1,X2)

XS1=GetStateNames(X1);
XS2=GetStateNames(X2);
% try to find a matching pair (in S1 and S2)
i1=0;
i2=0;
while true
	bInc2=i2==0;
	bFirst1=true;
	s1=[];
	while isempty(s1)
		while i1<length(XS1)
			i1=i1+1;
			if any(XS1{i1}=='.')
				s1=XS1{i1};
				break
			end
		end
		if isempty(s1)&&bFirst1
			i1=0;
			bInc2=true;
		end
	end
	if bInc2
		s2=[];
		while i2<length(XS2)
			i2=i2+1;
			if any(XS2{i2}=='.')
				s2=XS2{i2};
				break
			end
		end
	end
	if isempty(s1)||isempty(s2)
		error('No matching strings found')
	end
	S1=regexp(s1,'\.','split');
	S2=regexp(s2,'\.','split');
	B=false(length(S1),length(S2));
	for i=1:length(S2)
		B(:,i)=strcmp(S1,S2{i});
	end
	i1_sel=find(any(B,2),1);
	if ~isempty(i1_sel)
		i1=i1_sel;
		i2=find(B(i1,:),1);
		break
	end
end
if i1>1&&i2>1&&i1==length(S1)&&i2==length(S2)
	i1=i1-1;
	i2=i2-1;
end
n1=sum(cellfun('length',S1(1:i1)))+i1;
n2=sum(cellfun('length',S2(1:i2)))+i2;
s1=s1(1:n1);
s2=s2(1:n2);
S1=cell(1,length(XS1));
B1=false(1,length(S1));
for i1=1:length(S1)
	if strncmp(XS1{i1},s1,n1)
		B1(i1)=true;
		S1{i1}=XS1{i1}(n1+1:end);
	end
end
S2=cell(1,length(XS2));
B2=false(1,length(S2));
for i2=1:length(S2)
	if strncmp(XS2{i2},s2,n2)
		B2(i2)=true;
		S2{i2}=XS2{i2}(n2+1:end);
	end
end
I2_1=find(B2);
S2=S2(I2_1);
I1=zeros(1,length(S1));
I2=zeros(1,length(XS2));
for i1=1:length(XS1)
	if B1(i1)
		i2=find(strcmp(S1{i1},S2));
		if length(i2)>1
			warning('doubles?! (%s)',S1{i1})
		elseif ~isempty(i2)
			i2=I2_1(i2);
			I1(i1)=i2;
			I2(i2)=i1;
		end
	end
end

D=var2struct(I1,I2,s1,s2);
if nargout>1
	X2_1=X2;
	N=cellfun('length',{X1.signals.values});
	for i=1:length(I2)
		nDims2=X2.signals(i).dimensions;
		if I2(i)
			nDims1=X1.signals(I2(i)).dimensions;
			if nDims2==nDims1
				X2_1.signals(i).values=X1.signals(I2(i)).values;
			elseif nDims2<nDims1
				X2_1.signals(i).values=X1.signals(I2(i)).values(:,1:nDims2);
				warning('Dimensions decrease! (%d:%s),',i,X2.signals(i).blockName)
			else
				X2_1.signals(i).values=X1.signals(I2(i)).values(:,[1:nDims1 ones(1,nDims2-nDims1)]);
				warning('Dimensions increase! (%d:%s),',i,X2.signals(i).blockName)
			end
		else
			warning('zeros filled in?! (%d:%s)',i,X2.signals(i).blockName)
			X2_1.signals(i).values=zeros(max(N),nDims2);	%!!!!!!!!!!!!!!!!!!!
		end
	end
	X2_1.time=X1.time;
end

function XS=GetStateNames(X)
if isfield(X.signals,'stateName')
	XS={X.signals.stateName};
else
	XS=cell(1,length(X.signals));
end
for i=1:length(XS)
	if isempty(XS{i})
		sn=X.signals(i).blockName;
		sn=strrep(sn,' ','_');
		sn=strrep(sn,'/','.');
		XS{i}=sn;
	end
end
