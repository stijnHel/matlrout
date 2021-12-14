function [dt,i0,up]=timeshif(N,Ntarget,t,dN)
% TIMESHIF - Find shift time
%  [dt,i0]=timeshif(N,Ntarget,t,dN)
%
%	N : engine speed
%     Ntarget : target speed
%	t : time-vector (if 1 element : used as sample-period)
%	dN : error to end time (50 rpm if not given)
%
%    dt = times :
%		first column : first reach of error<dN
%		second column : last reach of error>=dN (until next shift)
%    i0 = indices of starts of shifts

if ~exist('t');t=[];end
if ~exist('dN');dN=[];end

if isempty(t)
	t=0:length(N)-1;
elseif length(t)==1
	t=(0:length(N)-1)*t;
end
if isempty(dN)
	dN=50;
end

absNerror=abs(N-Ntarget);
i_shift=find(abs(diff(Ntarget))>100);
dt=zeros(length(i_shift),2);
i_shift=[i_shift(:);length(N)];
for i=1:length(i_shift)-1
	i_0=i_shift(i)+1;
	i_1=i_shift(i+1);
	j=find(absNerror(i_0:i_1)<dN);
	if isempty(j)
		dt(i,:)=[inf inf];
	else
		dt(i,1)=t(j(1)+i_0-1)-t(i_0);
		j=find(absNerror(i_0:i_1)>=dN);
		dt(i,2)=t(j(length(j))+i_0)-t(i_0);
	end
end


if nargout>1
	i0=i_shift(1:length(i_shift)-1);
	if nargout>2
		up=Ntarget(i0)>Ntarget(i0+1);
	end
end

%(for i=1:length(i0);text(t(i0(i)),500,sprintf('%3.1f',dt(i,1)));end)
