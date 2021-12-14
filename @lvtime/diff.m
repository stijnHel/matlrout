function dt=diff(t)
%lvtime/diff - differentiate successive lvtime objects
%  dt=diff(t) where t is an object-array of type lvtime

if size(t,1)==1
	dt=zeros(1,length(t)-1);
	for i=1:length(dt)
		dt(i)=t(i+1)-t(i);
	end
else
	dt=zeros(size(t,1)-1,size(t,2));
	for iCol=1:size(t,2)
		for iRow=1:size(dt,1)
			dt(iRow,iCol)=t(iRow+1,iCol)-t(iRow,iCol);
		end
	end
end
