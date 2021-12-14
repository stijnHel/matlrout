function iD=zoekdoorgg(x,x0,n)
%ZOEKDOORG - Zoekt doorgangen bij ongeveer gekende periode

iD=zeros(1,round(length(x)/n)+100);
i=1;
while x(i)>=x0
	i=i+1;
end
iiD=0;
while i<length(x)
	while i<length(x)&&x(i)<x0
		i=i+1;
	end
	if x(i)>=x0
		if iiD>0
			if abs(i-iD(iiD)-n)>10
				if iiD>1
					if abs(diff(iD(iiD-1:iiD))-n)>10
						iiD=iiD-1;
					end
				else
					iiD=iiD-1;
				end
			end
		end
		iiD=iiD+1;
		iD(iiD)=i-1+(x0-x(i-1))/(x(i)-x(i-1));
		i=i+n-10;
		while i<length(x)&&x(i)>=x0
			i=i+1;
		end
	end
end
iD=iD(1:iiD);

	