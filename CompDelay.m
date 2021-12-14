function [e,dels,delt]=CompDelay(e,gegs)
%CompDelay - Compensate for the delays of DSA-devices
%   [e,dels,delt]=CompDelay(e,gegs)
%        This function is made for data read by leesVAtdms.
%      dels : delay in samples
%      delt : delay in time [s]

if 1/gegs.dt>10e3
	ds9233=10;
else
	ds9233=12;
end
ds9234=40;
dels=zeros(1,length(gegs.signals));
for i=1:length(gegs.signals)
	switch gegs.signals(i).DAQdevice
		case 'NI 9233'
			ds=ds9233;
		case 'NI 9234'
			ds=ds9234;
		otherwise
			ds=0;
	end
	dels(i)=ds;
	if ds>0
		e(1:end-ds,i)=e(1+ds:end,i);
		e(end-ds+1:end,i)=0;
	end
end
delt=dels*gegs.dt;
