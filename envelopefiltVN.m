function [E,targets]=envelopefiltVN(e,Nset)
% envelopefiltVN - Non-linear enverlope filter with varying N
%   Een lopend maximum en minimum wordt bepaald (de envelopes).  Er wordt
%   een andere methode gebruikt dan bij envelopefilter1.  Hier wordt naar
%   lineaire gedeeltes gezocht tussen pieken.
%
%       Nset = [idxList N]
%
%   E=envelopefiltVN(e,Nset)
%      E : [MIN MAX MEAN];
%        met MIN het lopende minimum, ...
%      e : de meting
%
%  additional output:
%   [E,N]=envelopefiltVN(e,Nset)
%     N is a two-column matrix with the distance to the "target point".
%
%  zie ook enverlopefilter
%
% should be integrated in envelopefilter (~scalar N ==> var N)

if size(e,1)==1
	e=e';
end
Ne=length(e);
E=e(:,[1 1 1]);
	% 1 : min
	% 2 : max
	% 3 : filter
N=Nset(1,2);	% starting value
E(1,:)=max(e(1:N));
E(end,:)=max(e(Ne-N+1:Ne));
jmx=0;
jmn=0;
if nargout>1
	targets=zeros(Ne,2);
end
NN=round(interp1(Nset(:,1),Nset(:,2),(1:Ne-1)));
if isnan(NN(1))
	i=2;
	while isnan(NN(i))
		i=i+1;
	end
	NN(1:i-1)=NN(i);
end
if isnan(NN(Ne-1))
	i=Ne-1;
	while isnan(NN(i))
		i=i-1;
	end
	NN(i+1:Ne-1)=NN(i);
end
for i=2:Ne-1
	N=NN(i);
	e1=E(i-1,1);
	if jmn>0
		if i+N<=Ne
			if (E(i+N-1,1)-e1)/N<emn
				emn=(E(i+N-1,1)-e1)/N;
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
			if (E(i+N-1,2)-e1)/N>emx
				emx=(E(i+N-1,2)-e1)/N;
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
	%if i>=Nset(1)&&i<=Nset(end,1)
	%	N=round(interp1(Nset(:,1),Nset(:,2),i));
	%end
end
E(:,3)=(E(:,1)+E(:,2))/2;
