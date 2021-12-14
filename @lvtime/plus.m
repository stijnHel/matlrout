function ctot=plus(c1,c2)
%lvtime/plus - adds seconds to lv-times

if isa(c1,'lvtime')
	if isa(c2,'lvtime')
		error('adding to lvtime''s is meaningless')
	end
	ctot=c1;
	dt=c2;
else
	ctot=c2;
	dt=c1;
end
if length(ctot)>1||length(dt)>1
	% just convert it to seconds(!)
	ctot=seconds(ctot)+dt;
	return
end
if dt==0
	return
end
sdt=sign(dt);
dt=abs(dt);
dt=[0 floor(dt) (dt-floor(dt))*2^32 0];
if dt(2)>2^32	% normally not possible (>=year 2040)
	dt(1)=floor(dt(2)/2^32);
	dt(2)=rem(dt(2),2^32);
end
dt(4)=round((dt(3)-floor(dt(3)))*2^32);
dt(3)=floor(dt(3));

if sdt<0
	dt=(2^32-1)-dt;
	dt(4)=dt(4)+1;
	for i=[4 3 2]
		if dt(i)>=2^32
			dt(i-1)=dt(i-1)+1;
			dt(i)=dt(i)-2^32;
		end
	end
end
ctot.t=ctot.t+dt;
for i=4:-1:2
	while ctot.t(i)>=2^32	% (very unlikely, but possible to need it twice)
		ctot.t(i-1)=ctot.t(i-1)+1;
		ctot.t(i)=ctot.t(i)-2^32;
	end
end
if ctot.t(1)>=2^32
	ctot.t(1)=ctot.t(1)-2^32;
end

