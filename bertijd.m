function t=bertijd(X1,x1,X2,x2,dt,nr);
% BERTIJD - berekent tijd
%   t=bertijd(X1,x1,X2,x2,dt,nr)
%       berekent de tijd tussen het ogenblik dat X1 boven x1 komt,
%       totdat X2 boven x2 komt.
%     indien nr gegeven, zoekt eerst naar de zoveelste keer dat X1>=x1 en dat X2>=x2 komt.

if ~exist('dt');dt=[];end
if ~exist('nr');nr=[];end
if isempty(dt)
	dt=1;
	dim=0;
else
	dim=1;
end
if isempty(nr)
	nr=1;
end
if min([size(X1) size(X2)])~=1
	error('X1 en X2 moeten (niet lege) vectoren zijn');
end
if length(X1)~=length(X2)
	error('lengte van X1 en X2 moeten gelijk zijn');
end

tLijst=[];
n=length(X1);
iEind=0;
for k=1:max(nr)
	iStart=ceil(iEind)+1;
	if X1(iStart)>=x1
		i=find(X1(iStart:n)<x1);
		if isempty(i)
			error('startogenblik niet gevonden')
		end
		iStart=i(1)+iStart-1;
	end
	i=find(X1(iStart:n)>=x1);
	if isempty(i)
		error('startogenblik niet gevonden')
	end
	iStart=i(1)+iStart-1;

	i=find(X2(iStart:n)>=x2);
	if isempty(i)
		error('eindogenblik is niet gevonden')
	end
	iEind=i(1)+iStart-1;
	if any(X1(iStart:iEind)<x1)
		i=find(X1(iStart:iEind)<x1);
		fprintf('!! X1 wordt laag tussen begin en eind (nr. %d)\n',k);
		fprintf('Ik korrigeer het startpunt met ');
		if dim
			fprintf('%g s.\n',max(i)*dt);
		else
			fprintf('%d punten.\n',max(i));
		end
		iStart=max(i)+iStart;
	end
	if ~isempty(find(nr==k))
		iStart=iStart-(X1(iStart)-x1)/diff(X1(iStart-1:iStart));
		iEind=iEind-(X2(iEind)-x2)/diff(X2(iEind-1:iEind));
		tLijst=[tLijst (iEind-iStart)*dt];
	end
end
if nargout>0
	t=tLijst;
else
	if max(tLijst)==0
		if dim
			fprintf('t=0 s\n');
		else
			fprintf('t=0\n');
		end
	else
		n=ceil(log(max(tLijst))/log(10))+1;
		nf=max(0,5-n);
		if nf>4
			if dim
				fprintf(['%5.' num2str(nf-3) 'f ms\n'],tLijst*1000);
			else
				fprintf(['%5.' num2str(nf-3) 'f [1e3]\n'],tLijst*1000);
			end
		else
			if dim
				fprintf(['%5.' num2str(nf) 'f s\n'],tLijst);
			else
				fprintf(['%5.' num2str(nf) 'f\n'],tLijst);
			end
		end
	end
end