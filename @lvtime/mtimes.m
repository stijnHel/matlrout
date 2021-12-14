function ctot=mtimes(c1,c2)
%lvtime/mtimes - converts to days and multiply

if isa(c1,'lvtime')&&isa(c2,'lvtime')
	error('multiplying two lvtime''s is meaningless')
end

ctot=double(c1)*double(c2);

