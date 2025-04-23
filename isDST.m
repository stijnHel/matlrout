function bST=isDST(T)
%isDST    - Is Daylight Saving Time (Belgium)?
%  bST=isDST(<T not corrected>)

if T(1)>2e6		% Julilan day (better to use Tim2MLtime?)
	T=calccaldate(T);
	T=T(:,[3 2 1 4 5 6]);
elseif T(1)>700000	% matlab time
	T=datevec(T);
end
nT=size(T,1);
if nT>1
	bST=false(nT,1);
	for i=1:nT
		bST(i)=isDST(T(i,:));
	end
	return
end
if length(T)<6
	T(1,6)=0;
end
bST=false;
if T(1)<1977
	% (after 1946) no summer time
elseif T(2)>3&&T(2)<9	% super simpele zomertijd-bepaling
	bST=true;
elseif T(1)>1995&&T(2)==9
	bST=true;
elseif T(1)<1996&&T(2)==10
	% early days (relatively) october always winter time
elseif T(2)==3&&T(3)>24
	wd=rem(weekday(datenum(T))+6,7);
	if wd==0	% sunday
		if T(4)>=2
			bST=true;
		end
	elseif wd+31-T(3)<7
		bST=true;
	end
elseif T(2)==10
	if T(3)<25
		bST=true;
	else
		wd=rem(weekday(datenum(T))+6,7);
		if wd==0	% sunday
			if T(4)<2
				bST=true;
			end
		elseif wd+31-T(3)>=7
			bST=true;
		end
	end
end
