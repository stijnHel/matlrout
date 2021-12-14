function nm=verpmot(e,maxim)
% VERPMOT  - Verwijder motortoerental-meet-pieken

% Verwijder toerentallen boven 6500 rpm.  Vervang deze toerentallen door
% gemiddelde van vorige en volgende toerentallen die onder de grens lagen.
% !!!!!in plaats van gemiddelde wordt nu minimum genomen
if ~exist('maxim')|isempty(maxim)
   maxim=6500;
end
eok=e<maxim;
iok=find(eok);
if isempty(iok)
	fprintf('Geen enkel goed motortoerental!!!\nDaarom geen filtering\n');
	nm=e;
	return
end
if ~eok(1)
	e(1)=e(iok(1));
	eok(1)=1;
	iok=[1;iok];
end
nm=e(iok);
ieok=cumsum(eok);
if ~eok(end)
	e(end)=nm(ieok(end));
	eok(end)=[];
	nm(end+1)=e(end);
end
ienok=find(~eok);
e(ienok)=min(nm(ieok(ienok)),nm(ieok(ienok)+1));

% Verwijder pieken.
de=diff(e);
dmde=de(1:end-1).*de(2:end);
dade=diff(abs(de));
i=find((dmde<-100000)&(abs(dade)<400)&(de(1:end-1)>0));
e(i+1)=(e(i)+e(i+2))/2;
nm=e;
