function [Bf,Af]=firstOrder(tau,dt)
%firstOrder - create filter vectors for simple 1st order filter
%     [Bf,Af]=firstOrder(tau[,dt])

if nargin>1
	tau=tau/dt;
end

k=exp(-1/tau);
Bf=1-k;
Af=[1 -k];
