function d=calcdang(p1,p2)
%calcdang - Calculate angular distance
%    d=calcdang(p1,p2)

if min(size(p1))>1
	bTrans=size(p1,1)==2&&size(p1,2)>2;
	if bTrans
		p1=p1';
		p2=p2';
	end
	c1=cos(p1(:,2));
	c2=cos(p2(:,2));
	X1=[cos(p1(:,1)).*c1 sin(p1(:,1)).*c1 sin(p1(:,2))];
	X2=[cos(p2(:,1)).*c2 sin(p2(:,1)).*c2 sin(p2(:,2))];
	d=asin(sqrt(sum((X1-X2).^2,2))/2)*2;
	if bTrans
		d=d';
	end
else
	c1=cos(p1(2));
	c2=cos(p2(2));
	X1=[cos(p1(1))*c1 sin(p1(1))*c1 sin(p1(2))];
	X2=[cos(p2(1))*c2 sin(p2(1))*c2 sin(p2(2))];

	d=asin(sqrt(sum((X1-X2).^2))/2)*2;
end
