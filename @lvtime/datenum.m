function tn=datenum(t,bLocal,bDST)
%lvtime/datenum - converts a lvtime to a matlab-date
%   tn=datenum(t[,bLocal,bDST])
%         bLocal : to Belgian time (default true)
%         bDST : Daylight Saving Time correction (default false)

if nargin<2
	bLocal=true;
end
if nargin<3
	bDST=false;
end

if bLocal
	tOffset=1/24;
else
	tOffset=0;
end

tFac=[2^32;1;2^-32;2^-64];
t0=datenum(1904,1,1)+tOffset;
tt=double(cat(1,t.t))*tFac;
Bneg=tt>=2^63;
if any(Bneg)
	%tt(Bneg)=tt(Bneg)-2^64;	% too high rounding error!
	ttt=2^32-1-double(cat(1,t(Bneg).t));
	ttt(:,4)=ttt(:,4)+1;
	for i=4:-1:2
		B=ttt(:,i)>=2^32;
		if ~any(B)
			break
		end
		ttt(B,i)=ttt(B,i)-2^32;
		ttt(B,i-1)=ttt(B,i-1)+1;
	end
	tt(Bneg)=-ttt*tFac;
end
tn=reshape(t0+tt/86400,size(t));
if bDST
	for i=find(isDST(tn)')
		tn(i)=tn(i)+1/24;
	end
end
