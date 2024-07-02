function T=datetime(t,bLocal,bDST)
%lvtime/datetime - converts a lvtime to a datetime object
%   tn=datetime(t[,bLocal,bDST])
%         bLocal : to Belgian time (default true)
%         bDST : Daylight Saving Time correction (default false)

if nargin<2
	bLocal=true;
end
if nargin<3
	bDST=false;
end

tv = datevec(t,bLocal,bDST);
T = datetime(tv);
