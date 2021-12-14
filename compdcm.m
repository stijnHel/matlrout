function compdcm(P1,P2,nmax)
% COMPDCM  - Vergelijk DCM-gegevens
%    compdcm(P1,P2[,nmax])
%        P1, P2 : struct-array met de volgende data (minstens)
%          naam : namen van gegevens
%          type : 'param', 'vlag', '1D', '2D', 'lijst' (andere worden genegeerd)
%          value : waarde (afhankelijk van het type)
%        als nmax gegeven wordt, wordt maximaal nmax aantal karakters
%          genomen om namen met elkaar te vergelijken.
%    Dit programma werd gemaakt om resultaten van de leesdcm-routine
%    van verschillende dcm-files met elkaar te vergelijken.
%    Vermits de structuur vrij eenvoudig en algemeen is, kan deze
%    routine ook voor andere zaken gebruikt worden.

P1=sort(P1,'naam','upper');
P2=sort(P2,'naam','upper');
if ~exist('nmax')|isempty(nmax)
	nmax=1e10;
end
lijst1=zeros(length(P1),1);
lijst2=zeros(length(P2),1);

nietVergeleken=[];
i1=1;
for i2=1:length(P2)
	if i2<length(P2)&strcmp(upper(P2(i2).naam(1:min(end,nmax))),upper(P2(i2+1).naam(1:min(end,nmax))))
		fprintf('!!nmax te klein om parameters te onderscheiden van elkaar (%s...%s en ..%s)!!\n',P2(i2).naam(1:nmax),P2(i2).naam(nmax+1:end),P2(i2+1).naam(nmax+1:end));
	end
	if i1>length(P1)
		fprintf('%s niet in P1\n',P2(i2).naam)
		continue;
	end
	while strcmpc(upper(P1(i1).naam(1:min(end,nmax))),upper(P2(i2).naam(1:min(end,nmax))))<0
%	while x<0
%	x=strcmpc(upper(P1(i1).naam(1:min(end,nmax))),upper(P2(i2).naam(1:min(end,nmax))));
%		strcmpc(upper(P1(i1).naam(1:min(end,nmax))),upper(P2(i2).naam(1:min(end,nmax))))<0
		fprintf('%s niet in P2\n',P1(i1).naam)
		i1=i1+1;
		if i1>length(P1)
			break;
		end
		x=strcmpc(upper(P1(i1).naam(1:min(end,nmax))),upper(P2(i2).naam(1:min(end,nmax))));
	end
	if i1>length(P1)	% als while gestopt door i1 te groot
		fprintf('%s niet in P1\n',P2(i2).naam)
		continue;
	end
%	fprintf('%3d %3d : %s<----->%s\n',i1,i2,P1(i1).naam,P2(i2).naam)
	if strcmp(upper(P1(i1).naam(1:min(end,nmax))),upper(P2(i2).naam(1:min(end,nmax))))
		lijst1(i1)=i2;
		lijst2(i2)=i1;
		if strcmp(P1(i1).type,P2(i2).type)
			switch P1(i1).type
			case {'param','vlag'}
				if P1(i1).value~=P2(i2).value
					fprintf('%s verschillende waarde : %g <-> %g\n',P1(i1).naam,P1(i1).value,P2(i2).value)
				else
%					fprintf('%s gelijk\n',P1(i1).naam)
				end
			case '1D'
				if all(size(P1(i1).value)==size(P2(i2).value))
					if ~all(all(P1(i1).value==P2(i2).value))
						fprintf('%s heeft verschillende inhoud\n',P1(i1).naam)
					end
				else
					fprintf('%s heeft verschillende grootte\n',P1(i1).naam)
				end
			case '2D'
				if all(size(P1(i1).value)==size(P2(i2).value))
					if ~all(all(P1(i1).value==P2(i2).value))
						fprintf('%s heeft verschillende inhoud\n',P1(i1).naam)
					end
				else
					fprintf('%s heeft verschillende grootte\n',P1(i1).naam)
				end
			case 'lijst'
				nietVergeleken(end+1)=i1;
			otherwise
				nietVergeleken(end+1)=i1;
			end
		else
			fprintf('!!%s heeft verschillende types\n',P1(i1).naam);
		end
		i1=i1+1;
	else
		fprintf('%s niet in P1\n',P2(i2).naam)
	end
end
if ~isempty(nietVergeleken)
	fprintf('!!%d elementen werden niet vergeleken :\n')
	for i=1:length(nietVergeleken)
		fprintf('  %s (%s)\n',P1(i1).naam,P1(i1).type);
	end
end
