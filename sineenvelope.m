function E=sineenvelope(t,x)
%sineenvelope - Calculates envelope of a sine wave
%   With a sine wave, a "nice signal" is meant, with clear zero crossings,
%   without "glitches"
%   A signal without the need of being equidistant is expected.
%   The "envelope" is made by finding the zero crossings with rising edges.
%      Between these crossings the minimum and maximum is found.  The times
%      of the zero crossings are calculated by linear interpolation between
%      the points of the crossings (two points around zero).  The times
%      given are the zero crossings before the minimum and maximum.
%
%    E=sineenvelope(t,x)
%       E = [t min max f]

ii=find(x(2:end)>=0&x(1:end-1)<0);

ti=ii;
j=ii(1);
ti(1)=t(j)+(t(j+1)-t(j))*x(j)/(x(j)-x(j+1));
E=zeros(length(ii)-1,4);
for i=2:length(ii)
	j=ii(i);
	ti(i)=t(j)+(t(j+1)-t(j))*x(j)/(x(j)-x(j+1));
	E(i-1,:)=[(ti(i-1)+ti(i))/2 min(x(ii(i-1):j)) max(x(ii(i-1):j)) 1/(ti(i)-ti(i-1))];
end
