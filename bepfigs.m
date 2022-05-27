function []=bepfigs(x,n)
% BEPFIGS beperkt de horizontale schalen van verschillende figuren (gebruik
%    makend van bepfig).
%
%    bepfigs(x,n)
%       met - x = [x0 x1] (= minimale en maximale x-coordinaten)
%           - n ofwel getal ---> alle figuren van 1 tot n worden herschaald
%               ofwel matrix --> alle figuren aangegeven in de matrix
%
%    Zie ook : bepfig
if ~exist('n','var')
	n = navfig('getlinked');
	if isempty(n)
		n=get(0,'children');
	end
end

if nargin==0
	help bepfigs
	return
end

if isnumeric(n) && length(n)==1 && ~isa(f,'matlab.ui.Figure')
	for I=1:n
		bepfig(x,I)
	end
else
	for I=1:length(n)
		bepfig(x,n(I))
	end
end
