function ctot=rdivide(c1,c2)
%lvtime/rdivide - converts to days and divide

if isa(c2,'lvtime')
	error('dividing by a lvtime is meaningless')
end

ctot=double(c1)./c2;
