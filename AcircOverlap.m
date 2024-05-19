function [A,A1,A2,fOverlap1] = AcircOverlap(r1,r2,d)
%AcircOverlap - Calculate overlapping area between 2 circles
%    A = AcircOverlap(r1,r2,d)
%         r1, r2: radii of cicles
%         d: distance between centre points
%         A: area of overlapping region
%    [A,A1,A2,fOverlap1] = AcircOverlap(r1,r2,d)
%         A1, A2: non-overlapping areas of circle 1 and 2

if r1+r2<=d
	A = 0;
	A1 = pi*r1^2;
	A2 = pi*r2^2;
elseif d<=abs(r1-r2)	% full overlap (one within the other)
	if r1<=r2
		A = pi*r1^2;
		A1 = 0;
		A2 = pi*r2^2-A;
	else
		A = pi*r2^2;
		A2 = 0;
		A1 = pi*r1^2-A;
	end
else
	x1 = (r1^2+d^2-r2^2)/(2*d);	% cos_g with g angle between top point and connection line
		% (triangle d, r1, r2)
	a1 = acos(x1/r1);
	y = sqrt(r1^2-x1^2);
	A1_1 = a1*r1^2-x1*y;	% area circle part - triangle (c1,0),(x1,y),(x1,-y)
	x2 = d-x1;
	a2 = acos(x2/r2);
	A2_1 = a2*r2^2-x2*y;	% area circle part - triangle (c2,0),(x2,y),(x2,-y)
	
	A = A1_1+A2_1;
	
	if nargout>1
		A1 = pi*r1^2-A1_1;
		A2 = pi*r2^2-A2_1;
	end
end
if nargout>3
	fOverlap1 = A/(pi*r1^2);
end
