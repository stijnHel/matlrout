function [meetveld,naamveld,dimveld]=metingvelden(S)
% METINGVELDEN - Geeft namen velden van meetfile
%  [meetveld,naamveld,dimveld]=metingvelden(S)

if isfield(S,'meting')
	meetveld='meting';
elseif isfield(S,'S')
	meetveld='e';
else
	error('de meting moet in veld ''meting'' of in ''e'' staan');
end
if isfield(S,'naam')
	naamveld='naam';
elseif isfield(S,'ne')
	naamveld='ne';
else
	error('de namen van de kanalen moeten in veld ''naam'' of in ''ne'' staan');
end
if isfield(S,'dim')
	dimveld='dim';
elseif isfield(S,'de')
	dimveld='de';
else
	dimveld='';
end
