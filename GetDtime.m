function tOut=GetDtime
%GetDtime - Gives the time from D0

dt=now-datenum(2009,2,20,11,30,0);
dt0=now-datenum(2008,4,1,8,30,0);
if nargout
	tOut=[dt,dt0];
else
	c=clock;
	dt100=rem(dt,100);
	fprintf('%.0f days survived (full %.0f - cd%+.0f)...\n',dt,dt0,dt100-c(3))
end
