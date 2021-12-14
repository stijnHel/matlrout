function d=dirdelim
% dirdelim.m - functie met als resultaat de delimiter tussen directory-namen
%    Deze routine kan vervangen worden door de standaard Matlab-filesep-routine.

persistent	reedsgebruikt

if isempty(reedsgebruikt)
	fprintf('dirdelim kan vervangen worden door de standaard filesep-routine\n');
	reedsgebruikt=1;
end
d=filesep;
