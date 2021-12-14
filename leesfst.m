function x=leesfst(f)
% LEESFST  - Leest fst-file (flash-formaat voor tune)

% Ondertussen is het volgende gevonden :
%   vanaf $30 tot $8f staan gegevens van indices verwijzend naar de "starts" (byte 6 tot 9)
%      in verschillende delen en lengtes (byte 10 en 11)
%      byte 0 lijkt de soort aan te geven (in ASCII-code)
%   van $90 tot $9f staat ook een gelijkaardige regel, maar waarnaar die verwijst weet ik niet
%   van $a0 tot $bf staan ook nog twee gelijkaardige regels die toch ook verwijzen
%      naar de laatste starts
%   Op die manier krijg je 8 blokken van gesorteerde parameters, elk van een andere soort (waarschijnlijk)

fid=fopen(f,'r');
if fid<3
	error('File kon niet geopend worden')
end
x=fread(fid,'*char');
fclose(fid);
head=x(1:192);
n=find(~x(193:20:end));
n=n(1)-1;
nams=setstr(zeros(n,16));
dims=setstr(zeros(n,8));
namlang=cell(n,1);
info=namlang;
%andere methode	
gs=abs(reshape(x(49:192),16,9)');
starts0=gs(:,7:10)*[1;256;65536;16777216];
aantal0=gs(:,11:12)*[1;256];
g1=gs(:,13:16)*[1;256;65536;16777216];
% Het volgende maakt nu geen gebruik van bovenstaande data, terwijl ze er wel
% mee samenhangen.
for j=1:16
	nams(:,j)=x(192+j:20:192+n*20)';
end
starts=abs(x([(209:20:192+n*20)' (210:20:192+n*20)' (211:20:192+n*20)' (212:20:192+n*20)']))*[1;256;65536;16777216];
nrs=abs(x([starts+1 starts+2]))*[1;256];
tests=abs(x([starts+3 starts+4 starts+5 starts+6 starts+7 starts+8]));
% byte 4 is 5 of 14
dims=x([starts+9 starts+10 starts+11 starts+12 starts+13 starts+14 starts+15 starts+16]);
j3=starts(1);
for i=1:n
	j1=j3;
	if abs(x(j1+7))<7	% ?????
		j1=j1+36;
		if i==n
			j3=length(x)+1;
		else
			j3=starts(i+1);
		end
		j2=j1+1+abs(x(j1+1));
		namlang{i}=x(j1+2:j2)';
		j1=j2;
		j2=j1+1+abs(x(j1+1));
		info{i}=x(j1+2:j2)';
		%j1=j2+1;
	else
	end
end
x=struct('naam',nams	...
	,'langnaam',[]	...
	,'info',[]	...
	,'starts0',starts0,'aantal0',aantal0,'gs',gs	...
	,'g',g1,'starts',starts,'dims',dims	...
	,'ruw',x,'tests',tests);
x.langnaam=namlang;
x.info=info;
