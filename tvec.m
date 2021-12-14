function T=tvec(e,dt)
%tvec     - Creates time vector for measurement
%     T=tvec(e,dt)

N=size(e,1);
if nargin==1
	T=e(:,1);
	return
elseif isnumeric(dt)
	if isscalar(dt)
		% OK
	else
		dt=dt(12);	% see leeshead
	end
elseif isstruct(dt)
	dt=dt.dt;
else
	error('wrong input')
end
T=(0:N-1)'*dt;
