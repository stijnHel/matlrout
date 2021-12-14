function [y,x]=getkanx(e,s)
% STRUCT/GETKANX  - Geeft kanaal (uit struct e)
%    [y[,x]]=getkan(e,s)
% (Het eerst gevonden kanaal wordt genomen, zonder kontrole
%  op latere voorkomens.)

[meetveld,naamveld]=metingvelden(e);
sl=lower(s);
for i=1:length(e)
	ne=getfield(e(i),naamveld);
	j=fstrmat(lower(ne),sl,2);
	if length(j)
		A=getfield(e(i),meetveld);
		y=A(:,j(1));
		if nargout>1
			if isfield(e,'t')
				x=e(i).t;
			elseif isfield(e,'dt')
				x=(0:length(y)-1)'*e(i).dt;
			else
				x=A(:,1);
			end
		end	% nargout>1
		return
	end	% gevonden
end	% for i
error('kan kanaal niet vinden')
