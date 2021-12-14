function E=envelopefilter2(e,k1,k2,N)
% ENVELOPEFILTER1 - Non-linear filter which looks for the envelope of a signal
%   Een lopend maximum en minimum wordt bepaald (de envelopes).  Het
%   maximum zal altijd boven het oorspronkelijke signaal liggen.  Het daalt
%   na minimum N waarden, en dit met een tweede orde filter (k1,k2).
%   E=envelopefilter1(e,k1,k2,N)
%      E : [MIN MAX MEAN];
%        met MIN het lopende minimum, ...
%      e : de meting
%      k1,k2 : factor waarmee minima en maxima kunnen varieren naar het
%          signaal toe.
%
%  zie ook envelopefilter

if nargin<2
	k1=0.2;
	k2=0.6;
	N=3;
elseif nargin<3
	k2=k1;	% ?of 1?
	N=3;
elseif nargin<4
	N=3;
end

E=zeros(length(e),3);
	% 1 : min
	% 2 : max
	% 3 : filter
emn1=e(1);
emn2=emn1;
emx1=emn1;
emx2=emn1;
nmn=0;
nmx=0;
E(1,:)=emn1;
dE=0;
test=[];
for i=2:length(e)
	if e(i)<emn1
		emn1=e(i);
		nmn=0;
	elseif nmn<N
		if e(i)-emn2-dE<=0
			nmn=0;
		else
			nmn=nmn+1;
		end
	else
		emn1=emn1+k1*(e(i)-emn1);
	end
	emn2=min(emn1,emn2+k2*(emn1-emn2));
	if e(i)>emx1
		emx1=e(i);
		nmx=0;
	elseif nmx<N
		if emx2-e(i)-dE<=0
			nmx=0;
		else
			nmx=nmx+1;
		end
	else
		emx1=emx1+k1*(e(i)-emx1);
	end
	emx2=emx2+k2*(emx1-emx2);
	if emx1>emx2
		emx2=emx1;
		nmx=0;
	end
	E(i,1)=emn2;
	E(i,2)=emx2;
	dE=(emx2-emn2)*1e-2;
end
E(:,3)=(E(:,1)+E(:,2))/2;
