function ctot=times(c1,c2)
%lvtime/times - converts to days and multiply

if isa(c1,'lvtime')&&isa(c2,'lvtime')
	error('multiplying two lvtime''s is meaningless')
end

ctot=double(c1).*double(c2);
