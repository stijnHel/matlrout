function E=envelopefilter(e,N)
% ENVELOPEFILTER - Non-linear filter which looks for the envelope of a signal
%   Een lopend maximum en minimum wordt bepaald (de envelopes).  Er wordt
%   een andere methode gebruikt dan bij envelopefilter1.  Hier wordt naar
%   lineaire gedeeltes gezocht tussen pieken.
%   E=envelopefilter(e,N)
%      E : [MIN MAX MEAN];
%        met MIN het lopende minimum, ...
%      e : de meting
%
%  zie ook enverlopefilter1

if size(e,1)==1
	e=e';
end
E=e(:,[1 1 1]);
	% 1 : min
	% 2 : max
	% 3 : filter
E(1,:)=max(e(1:N));
E(end,:)=max(e(end-N+1:end));
for i=2:length(e)-1
	[mx,j]=max(E(i:min(end,i+N-1),2));
	if i>20000
		i=i;	% breakpoint
	end
	if j>1
		E(i,2)=E(i-1,2)+1/(j-1)*(E(i+j-1,2)-E(i-1,2));
	end
	%!!! ook nog minimum
end
E(:,3)=(E(:,1)+E(:,2))/2;
