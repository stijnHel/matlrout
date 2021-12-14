function U_IN=CreateInputMatrix(INPUTS,Ts,Duration)
%CreateInputMatrix - Create input matrix for Simulink model
%       U_IN=CreateInputMatrix(INPUTS,Ts)
%              INPUTS :
%                 - cell vector with names of variables with input spec
%                  must match the order of the inputs in the Simulink model
%                 - structure with different inputs in different fields
%                 - cell array, with names in column 1, values in column2
%              Ts : sample time (made for creating steps
%
%              U_IN : input matrix
%
%     structure input values:
%           value               - constant value
%        or
%           [T  Values  Types]	- currently only one value per input
%                   Types: 0: constant part, 1: linear

bDefaultDuration=false;
if ~exist('Duration','var')||isempty(Duration)
	Duration=10;
	bDefaultDuration=true;
elseif Duration==0	% minimal duration
	bDefaultDuration=true;
end

if isstruct(INPUTS)
	INPUTS=[fieldnames(INPUTS),struct2cell(INPUTS)];
elseif iscell(INPUTS)
	if isvector(INPUTS)
		INPUTS=INPUTS(:);
		for i=1:length(INPUTS)
			try
				INPUTS{i,2}=evalin('caller',INPUTS{i});
			catch err
				DispErr(err);
				error('Problems getting input #%d (%s)',i,INPUTS{i})
			end
		end
	end
else
	error('Wrong input!')
end
	
nINPUTS=length(INPUTS);
Tpt=0;
for i=1:nINPUTS
	V=INPUTS{i,2};
	if isscalar(V)
		V=[0 V 0];	%#ok<AGROW> % constant from t=0
	end
	if size(V,1)>1&&any(diff(V(:,1))<=0)
		error('Not increasing time staps for #%d (%s)',i,INPUTS{i})
	end
	T=num2cell(V(:,1));	% times
	for iT=1:length(T)-1
		if V(iT,3)==0&&V(iT+1)-V(iT)>Ts	% add additional point
			T{iT+1}=T{iT+1}-[Ts;0];
		end
	end
	Tpt=union(Tpt,cat(1,T{:}));
end
if bDefaultDuration
	Duration=max(Tpt(end)*2+1,Duration);
elseif Duration<=0
	Duration=Tpt(end);
end
if Duration>Tpt(end)
	Tpt(end+1)=Duration;
end

U_IN=zeros(length(Tpt),nINPUTS+1);
U_IN(:,1)=Tpt;
V1=Tpt;	% creation of vector for one input
B=false(length(Tpt),1);
for i=1:nINPUTS
	B(:)=true;
	V=INPUTS{i,2};
	if isscalar(V)
		V=[0 V 0];	%#ok<AGROW> % constant from t=0
	end
	V1(1)=V(1,2);
	B(1)=false;
	for j=2:size(V,1)
		if V(j-1,3)==0	% constant
			ii=find(B&Tpt<V(j));
			V1(ii)=V(j-1,2);
			B(ii)=false;
			ii=ii(end)+1;
			if Tpt(ii)-Tpt(ii-1)>Ts*1.1
				error('wat nu?')
			end
			V1(ii)=V(j,2);
			B(ii)=false;
		else
			ii=find(B&Tpt<=V(j));
			V1(ii)=V(j-1,2)+(Tpt(ii)-V(j-1))*diff(V(j-1:j,2))/diff(V(j-1:j));
			B(ii)=false;
		end
	end		% for j
	V1(B)=V(end,2);
	U_IN(:,i+1)=V1;
end		% for i
