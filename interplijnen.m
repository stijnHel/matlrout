function S=interplijnen(c)
% INTERPLIJNEN - Interpreteert cell-array van tab-separated lijnen
%   Maakt structure van cell array bestaande uit lijnen tekst.
%   Elke lijn bestaat uit een naam (uniek in de cell-array) gevolgd door
%   een tab, gevolgd door tab-separated data.  Data is numeriek of string.
%   Numeriek als bestaande uit "numerieke karakters" (!!eenvoudig
%   uitgevoerd!! : om exponentiele data toe te laten (1.0e5) wordt letter
%   'e' (en 'E') tot de "numerieke karakters" gerekend, met als gevolg dat
%   'e' of 'e1' getallen zijn! die nadien verkeerd geinterpreteerd worden.)
%   Data moet "tab-separated" zijn (spaties tellen niet!).
%      S=interplijnen(C)
%   bijvoorbeeld : S=interplijnen(['abc' 9 '123']});
%     geeft S==struct('abc',123)

% Stijn Helsen - 2006

n=length(c);
C=cell(2,n);
cOK=false(1,n);
cNum=false(1,255);
cNum(abs('0123456789.-+eE'))=true;
cNum(9)=true;

for i=1:n
	s=c{i};
	j=find([s 9]==9);
	if length(j)>1
		cOK(i)=true;
		j1=j(1);
		C{1,i}=s(1:j1-1);
		if all(cNum(abs(s(j1+1:end))))
			c1=sscanf(s(j1+1:end),'%g');
		else
			c1=cell(1,length(j)-1);
			for k=1:length(j)-1
				c1{k}=s(j(k)+1:j(k+1)-1);
				if all(cNum(abs(c1{k})))
					c1{k}=str2num(c1{k});
				end
			end
			if length(c1)>1
				c1={c1};
			end
		end
		C{2,i}=c1;
	end
end
C(:,~cOK)=[];
S=struct(C{:});

