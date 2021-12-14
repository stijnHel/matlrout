function deldate
% DELDATE - Verwijdert datum van een figuur.

x=findobj(gcf,'Tag','datum-as');
if isempty(x)
	fprintf('Niet gevonden !\n');
else
	delete(x);
end