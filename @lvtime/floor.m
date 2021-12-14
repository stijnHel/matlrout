function t=floor(t)
%lvtime/floor - Get time at or before given time with full second
%      t=floor(t)

for i=1:length(t)
	t(i).t(3:4)=0;
end
