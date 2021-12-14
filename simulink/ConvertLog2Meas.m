function [e,ne,de,e2,gegs]=ConvertLog2Meas(D)
%ConvertLog2Meas - Converts a (Simulink-)log to a measurement array
%       [e,ne,de,e2,gegs]=ConvertLog2Meas(D)
%
%  see also GetAllSLLogs

DT=zeros(1,length(D));
N=zeros(1,length(D));
for i=1:length(D)
	DT(i)=median(diff(D(i).Time));
	N(i)=length(D(i).Time);
end
dtMin=min(DT);
rDT=floor(DT/dtMin*8)/8;
uDT=unique(rDT(~isnan(DT)))*dtMin;
if length(uDT)>2
	fprintf('     %g\n',uDT)
	error('Too many different sampling times')
end
ne=cell(1,length(D));
de={'-'};de=de(1,ones(1,length(D)));	% default dimension

ii=find(rDT==1);	% select signals with the same (high) sampling rate
[e,ne,de,Time]=CombineSignals(D,N,ii,0,ne,de);
gegs=struct('dt',uDT,'Time',Time);

i0=length(ii);
if i0==length(D)
	e2=[];
else
	ii=setdiff(1:length(D),ii);	% select the signals with low sampling rate
	[e2,ne,de,Time]=CombineSignals(D,N,ii,i0,ne,de);
	gegs.Time={gegs.Time,Time};
end

function [e,ne,de,Time]=CombineSignals(D,N,ii,i0,ne,de)
[mxN,iN]=max(N(ii));
if isempty(iN)
	e=zeros(0,length(ii));
	Time=[];
	warning('Empty measurement?')
	return
end
e=zeros(mxN,length(ii));
Time=D(ii(iN)).Time;
for i=1:length(ii)
	ne{i0+i}=D(ii(i)).Name;
	if isfield(D,'unit')
		de{i0+i}=D(ii(i)).unit;
	end
	if N(ii(i))==mxN
		e(:,i)=D(ii(i)).Data;
	else
		e(:,i)=interp1(D(ii(i)).Time,D(ii(i)).Data,Time);
	end
end
