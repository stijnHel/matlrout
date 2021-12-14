function y=frac2dec(form,x)
%frac2dec - Convert fractional number to decimal parts
%   y=frac2dec([<n1> <n2> ..],x)
%       y: [y1 y2 y3 ...]
%            y1 = floor(y)
%            y2 = floor((y-floor(y))*n1)
%            ....
%  example:
%       x=0.543;  % fraction of a day
%       dhms=frac2dec([24 60 60],x); % converts to day, hour, min, sec
%       x=0.123;  % fraction of a year
%       ydhms=frac2dec([365,24,60,60],x); %-> year, day, hour, min, sec

y=zeros(1,length(form)+1);
for i=1:length(y)
	fx=floor(x);
	y(i)=fx;
	if i<=length(form)
		f=form(i);
	else
		f=1;
	end
	x=(x-fx)*f;
end
y(end)=y(end)+x;
