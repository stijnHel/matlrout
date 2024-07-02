function tv=datevec(t,bLocal,bDST)
%lvtime/datevec - converts a lvtime to a matlab-date-vector
%   tv=datevec(t[,bLocal,bDST])
%         bLocal : to Belgian time (default true)
%         bDST : Daylight Saving Time correction (default false)

if nargin<2
	bLocal=true;
end
if nargin<3
	bDST=false;
end

tn = datenum(t,bLocal,bDST);
tv = datevec(tn);
