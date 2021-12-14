function cdif=minus(c1,c2)
%lvtime/minus - subtracts to lv-times, and gives the number of elapsed seconds
%  also possible to subtract some seconds from a lv-time

if ~isa(c1,'lvtime')
	if isnumeric(c1)
		cdif=c1-double(c2);
		return
	else
		error('subtracting lvtime-objects can only be done with lvtime as first argument! or (<double>-T)')
	end
end
if length(c1)>1
	cdif=zeros(size(c1));
	if length(c2)>1
		for i=1:numel(c1)
			cdif(i)=c1(i)-c2(i);
		end
	else
		for i=1:numel(c1)
			cdif(i)=c1(i)-c2;
		end
	end
	return
elseif length(c2)>1
	cdif=zeros(size(c2));
	for i=1:numel(c1)
		cdif(i)=c1-c2(i);
	end
	return
end
if isa(c2,'lvtime')
	%dif=c1.t-c2.t;
	dif=double(c1.t)-double(c2.t);
	cdif=dif;
	for i=[4 3 2]
		if cdif(i)<0
			cdif(i)=cdif(i)+2^32;
			cdif(i-1)=cdif(i-1)-1;
		end
	end
	if cdif(1)<0
		bSign=-1;
		cdif(1)=cdif(1)+2^32;
		cdif=(2^32-1)-cdif;
		cdif(4)=cdif(4)+1;
		for i=[4 3 2]
			if cdif(i)>=2^32
				cdif(i-1)=cdif(i-1)+1;
				cdif(i)=cdif(i)-2^32;
			end
		end
	else
		bSign=1;
	end
	cdif=bSign*(cdif*[2^32;1;2^-32;2^-64]);
else
	cdif=c1+(-c2);	% use lvtime/plus-routine
end
