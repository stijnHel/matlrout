function k=getkan(e,s)
% STRUCT/GETKAN - Geeft kanaal-nummer (uit struct e)
%    i=getkan(e,s)
%   Het nummer dat gegeven wordt telt het eerste kanaal van de eerste
%        mee, maar van de volgende niet.  Dit is dezelfde volgorde als
%        deze die door plotmat gebruikt wordt.
% (Het eerst gevonden kanaal wordt genomen, zonder kontrole
%  op latere voorkomens.)

[meetveld,naamveld]=metingvelden(e);
sl=lower(s);
i0=1;
for i=1:length(e)
	ne=getfield(e(i),naamveld);
	j=fstrmat(lower(ne),sl,2);
	if ~isempty(j)
		if i==1
			k=i;
		else
			k=i0+j-1;
		end
		return
	end	% gevonden
	i0=i0+size(ne,1)-1;
end	% for i
error('kan kanaal niet vinden')
