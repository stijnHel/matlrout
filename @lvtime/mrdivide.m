function ctot=mrdivide(c1,c2)
%lvtime/mrdivide - converts to days and divide

if isa(c2,'lvtime')
	error('dividing by a lvtime is meaningless')
end

ctot=double(c1)/c2;
