function d=calcdangd(p1,p2)
%calcdangd - Calculate angular distance (degrees)
%    d=calcdang(p1,p2)

if min(size(p1))>1
	bTrans=size(p1,1)==2&&size(p1,2)>2;
	if bTrans
		p1=p1';
		p2=p2';
	end
	c1=cosd(p1(:,2));
	c2=cosd(p2(:,2));
	X1=[cosd(p1(:,1)).*c1 sind(p1(:,1)).*c1 sind(p1(:,2))];
	X2=[cosd(p2(:,1)).*c2 sind(p2(:,1)).*c2 sind(p2(:,2))];
	d=asind(sqrt(sum((X1-X2).^2,2))/2)*2;
	if bTrans
		d=d';
	end
else
	c1=cosd(p1(2));
	c2=cosd(p2(2));
	X1=[cosd(p1(1))*c1 sind(p1(1))*c1 sind(p1(2))];
	X2=[cosd(p2(1))*c2 sind(p2(1))*c2 sind(p2(2))];

	d=asind(sqrt(sum((X1-X2).^2))/2)*2;
end
