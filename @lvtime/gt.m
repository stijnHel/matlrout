function b=gt(t1,t2)
%lvtime/gt - Greater than for lvtime objects

if isa(t1,'lvtime')
	if isa(t2,'lvtime')
		b=(t1-t2)>0;
	elseif t2>1e6
		b=seconds(t1)>t2;
	else
		b=datenum(t1)>t2;
	end
elseif t1>1e6
	b=t1>seconds(t2);
else
	b=t1>datenum(t2);
end
