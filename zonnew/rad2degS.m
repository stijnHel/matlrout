function [dout,mn,sec]=rad2degS(rad,norm)% RAD2DEG - Zet radialen om in graden (met opsplitsing in graden, minuten en seconden)%     rad2degS(rad[,norm])%          als norm gegeven en ~=1, dan wordt genormeerd naar 0 .. 359.999 graden%     graden=rad2degS(rad[,norm])%     [graf,min,sec]=rad2degS(rad[,norm])if ~exist('norm','var')||isempty(norm)	norm=0;endd=rad*(1+5*eps)*180/pi;if nargout==1	dout=d;else	sd=sign(d);	d=d.*sd;	if norm		d=d-floor(d/360)*360;	else		sg=sign(d);		d=abs(d);	end	mn=(d-floor(d))*60;	d=floor(d);	sec=(mn-floor(mn))*60;	mn=floor(mn);	if ~norm&&sg<0		d=-d;		mn=-mn;		sec=-sec;	end	if nargout		dout=d.*sd;	else		fprintf('%5d�%d''%6.4f"\n',[d(:).*sd(:),mn(:),sec(:)]')	endend