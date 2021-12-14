function [E,targets]=envelopefilter(e,N)
% ENVELOPEFILTER - Non-linear filter which looks for the envelope of a signal
%   Een lopend maximum en minimum wordt bepaald (de envelopes).  Er wordt
%   een andere methode gebruikt dan bij envelopefilter1.  Hier wordt naar
%   lineaire gedeeltes gezocht tussen pieken.
%   E=envelopefilter(e,N)
%      E : [MIN MAX MEAN];
%        met MIN het lopende minimum, ...
%      e : de meting
%
%  additional output:
%   [E,N]=envelopefilter(e,N)
%     N is a two-column matrix with the distance to the "target point".
%
%  zie ook enverlopefilter1

if size(e,1)==1
	e=e';
end
Ne=length(e);
E=e(:,[1 1 1]);
	% 1 : min
	% 2 : max
	% 3 : filter
N1=N-1;
E(1,:)=max(e(1:N));
E(end,:)=max(e(Ne-N1:Ne));
jmx=0;
jmn=0;
if nargout>1
	targets=zeros(Ne,2);
end
for i=2:Ne-1
	e1=E(i-1,1);
	if jmn>0
		if i+N<=Ne
			if (E(i+N1,1)-e1)/N<emn
				emn=(E(i+N1,1)-e1)/N;
				jmn=N;
			end
		end
	else
		nl=min(Ne,i+N-1);
		[emn,jmn]=min((E(i:nl,1)-e1)./(1:nl-i+1)');
	end
	jmn=jmn-1;
	if jmn>0
		E(i,1)=e1+emn;
	end
	e1=E(i-1,2);
	if jmx>0
		if i+N<=Ne
			if (E(i+N1,2)-e1)/N>emx
				emx=(E(i+N1,2)-e1)/N;
				jmx=N;
			end
		end
	else
		nl=min(Ne,i+N-1);
		[emx,jmx]=max((E(i:nl,2)-e1)./(1:nl-i+1)');
	end
	jmx=jmx-1;
	if jmx>0
		E(i,2)=e1+emx;
	end
	if nargout>1
		targets(i,1)=jmn;
		targets(i,2)=jmx;
	end
end
E(:,3)=(E(:,1)+E(:,2))/2;
