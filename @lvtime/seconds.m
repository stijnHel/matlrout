function tn=seconds(t)
%lvtime/seconds - converts a lvtime (or array) to a double, in seconds
%   tn=seconds(t)
%       keeps reference to 1904, and therefore doesn't loose resolution
%            like in double or datenum case.

tn=zeros(size(t));
dt=2^64*cumprod(2^-32+zeros(4,1));
for i=1:numel(t)
	tn(i)=t(i).t*dt;
end
