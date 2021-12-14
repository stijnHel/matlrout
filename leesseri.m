function S=leesseri(x,dt)
% LEESSERI - Leest seriele data (analoog gemeten) met tijdscompensatie bij elke overgang
%   S=leesseri(x,dt,nstart,nstop)
%      x="binair signaal" (0 of ~=0)
%      dt=tijd in "meetpunten"
%
% er is weinig fout-controle
% Deze routine werd gemaakt voor het lezen van seriele data van de alaska-GIB.
% (1 start-bit, 2 stopbit

dt1=dt/2;
y=zeros(round(length(x)/dt)+10,1);
y(1)=x(1);
x0=x(1);
% zoeken naar eerste wisseling
i=2;
while x(i)==x0
	i=i+1;
end
%???als i>dt eerste punten toevoegen?
x0=x(i);
y(2)=x0;
i=i+dt1;	% (?x(i:i+dt)==x0, anders error)
j=1;
while 1
	i=i+dt;
	if i>length(x)
		break;
	end
	if x(round(i))~=x0	% herinitialiseer timing
		i=floor(i);
		x0=x(i);
		while x(i)==x0
			i=i-1;
		end
		i=i+dt1;
	end
	j=j+1;
	y(j)=x0;
end
%Zoek start eerste message
i=1;
while ~all(y(i:i+9))
	i=i+1;
end
i=i+8;

% "Lezen van bytes"
z=zeros(1,floor(j/11));
k=0;
bitval=[1 cumprod(2+zeros(1,7))];
while 1
	while y(i)
		i=i+1;
		if i>j-10
			break;
		end
	end
	if i>j-10
		break;
	end
	k=k+1;
	z(k)=bitval*y(i+1:i+8);
	if ~all(y(i+9:i+10))
		warning('!!!stop bits niet nul!!! lezen wordt gestopt!!!');
		break;
	end
	i=i+11;
end

% Interpreteren van data
S=struct('ID',cell(k,1),'data',[]);
i=1;
j=0;
while i+3<=k
	l=z(i+1);
	if i+l>=k
		break;
	end
	if sum(z(i:i+l-2))~=z(i+l-1)
		warning('!!!checksum klopt niet!!!')
		break;
	end
	j=j+1;
	S(j).ID=z(i);
	S(j).data=z(i+2:i+l-2);
	i=i+l;
end
S=S(1:j);
