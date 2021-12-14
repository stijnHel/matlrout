function [X,Dc,gegs_o]=leespwm(f)
% LEESPWM - leest metingen van pwm-metingen van accutex
global EVDIR

fid=fopen([EVDIR deblank(f)],'rt');
if fid<=0
	error('Ik kan de file niet openen')
end
x=fscanf(fid,'%c');
fclose(fid);
iLF=find(abs(x)==10);
i=1;
i0=1;
gegs=struct('x1','','x2','');
naarbar=unitconv('kPa','bar');
gegsLijst={	''				...  1
			,'NAM'		...  2
			,''			...  3
			,''			...  4
			,''			...  5
			,''			...  6
			,''			...  7
			,'CNUM'		...  8
			,''			...  9
			,'N'			... 10
			,''			... 11
			,'AI'			... 12
			,'AO'			... 13
			,'BI'			... 14
			,'BO'			... 15
			,''			... 16
			};	% !!!!! voorlopig niet gebruikt
ai=[];ao=[];bi=[];bo=[];
nSweep=[];nPoints=[];
technician='';
oudemeting=[];
while 1
	lijn=x(i0:iLF(i)-1);
	i0=iLF(i)+1;
	i=i+1;
	j=find(lijn==',');
	if isempty(j)
		break;
	end
	j=j(1);
	if lijn(1)=='"'
		if ~isempty(oudemeting)&~oudemeting
			error('Een kombinatie van oude en nieuwe meetgegevens ??!');
		else
			oudemeting=1;
		end
		if (lijn(j-1)~='"')|(lijn(j+1)~='"')|(lijn(end)~='"')
			error('Ik verwachtte meer ''"''''s')
		end
		x1=lijn(2:j-2);
		x2=deblank(lijn(j+2:end-1));
	else
		if ~isempty(oudemeting)&oudemeting
			error('Een kombinatie van oude en nieuwe meetgegevens ??!');
		else
			oudemeting=0;
		end
		x1=lijn(1:j-1);
		x2=deblank(lijn(j+1:end));
	end
	if isempty(x2)
		error('Ik dacht dat x2 altijd "iets" zou bevatten')
	end
	if strcmp(lower(x1),'junk')
		% doe er niets mee
	elseif strcmp(x1,'Supply Offset')|strcmp(x1,'AI')
		ai=str2num(x2)*naarbar;
	elseif strcmp(x1,'Control Offset')|strcmp(x1,'AO')
		ao=str2num(x2)*naarbar;
	elseif strcmp(x1,'Supply Gain')|strcmp(x1,'BI')
		bi=str2num(x2)*naarbar;
	elseif strcmp(x1,'Control Gain')|strcmp(x1,'BO')
		bo=str2num(x2)*naarbar;
	elseif strcmp(x1,'Number of sweeps')|strcmp(x1,'CNUM')
		nSweep=str2num(x2);
	elseif strcmp(x1,'Number of steps')|strcmp(x1,'N')
		nPoints=str2num(x2);
	elseif strcmp(x1,'Technician')|strcmp(x1,'NAM')
		technician=x2;
	else
		fprintf('%-10s : %s\n',x1,x2)
		gegs.x1=strvcat(gegs.x1,x1);
		gegs.x2=strvcat(gegs.x2,x2);
	end
end
if isempty(ai)|isempty(ao)|isempty(bi)|isempty(bo)
	error('Niet voldoende (of juiste) informatie in de header');
end
if ~strcmp(lijn,'"pressures"')&~strcmp(lijn,'pressures')
	error('Ik verwachtte op deze lijn "pressures"');
end

%!!!!????
if ~oudemeting
	Ai=ai;
	Ao=ao;
	Bi=bi;
	Bo=bo;
	ai=Ao;
	bi=Bo;
	ao=Ai;
	bo=Bi;
	ai=0;bi=naarbar;
	ao=0;bo=naarbar;
end
%!!!!????
plijst=zeros(1,0);
while x(i0)==' ';i0=i0+1;end
while (x(i0)>='0')&(x(i0)<='9')
	plijst(end+1)=str2num(x(i0:iLF(i)-1));
	i0=iLF(i)+1;
	while x(i0)==' ';i0=i0+1;end
	i=i+1;
end
lijn=x(i0:iLF(i)-1);
if ~strcmp(lijn,'"input","output"')&~strcmp(lijn,'supply,control')
	error('Ik verwachtte op deze lijn "input","output"');
end
x(1:iLF(i))='';
e=sscanf(x,'%g , %g\n');
e=reshape(e,2,length(e)/2)';
if rem(length(e),length(plijst))
	error('Er is een fout met het aantal meetpunten')
end
x={};
ne=length(e)/length(plijst);
dc=[0:100/(ne/2-1):100];
dc=[dc fliplr(dc)];
if length(dc)~=ne
	error('Iets fout met bepaling van dc')
end
plijst=plijst*naarbar;
for i=1:length(plijst)
	x{i}=struct('druk',plijst(i),'input',e((i-1)*ne+(1:ne),1)*bi+ai,'output',e((i-1)*ne+(1:ne),2)*bo+ao);
%x{i}=struct('druk',plijst(i),'input',e((i-1)*ne+(1:ne),1)*bo+ao,'output',e((i-1)*ne+(1:ne),2)*bi+ai);
end
if nargout
   X=x;
	if nargout>1
		Dc=dc;
		if nargout>2
			gegs_o=gegs;
		end
	end
else
	nfigure
	for i=1:length(x)
		subplot(1,length(x),i);
		plot(dc,[x{i}.input,x{i}.output]);grid
		title(f);
		xlabel('duty-cycle [%]');
		ylabel('druk [bar]')
	end
end
