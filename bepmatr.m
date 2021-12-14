function [Xok,Xnok,Xcor]=bepmatr(Tab,tMin,tMax,herschaal)
% BEPMATR - Beperk matrix

if nargin<2
	error('Zo is er niets te beperken !')
end

if ~exist('herschaal');herschaal=[];end
if ~exist('tMax');tMax=[];end

if isempty(tMin)
	tMin=-1e6;
end
if isempty(tMax)
	tMax=1e6;
end

if (length(tMin)~=1)&(min(size(tMin))<2)
	error('Verkeerd minimum')
end
if (length(tMax)~=1)&(min(size(tMax))<2)
	error('Verkeerd maximum')
end

if min(size(Tab))==2
	if (size(Tab,1)==2)&(size(Tab,2)>2)
		Tab=Tab';
	end
	if (size(tMin,1)==2)&(size(tMin,2)>2)
		tMin=tMin';
	end
	if (size(tMax,1)==2)&(size(tMax,2)>2)
		tMax=tMax';
	end
	[X,Z]=getmatr(Tab);
	if ~isempty(herschaal)
		if length(herschaal)==1
			X1=min(X):herschaal:max(X);
			if max(X)>X1
				X1=[X1 max(X)];
			end
			Z=interp1(X,Z,X1);
			X=X1;
		else
			Z=interp1(X,Z,herschaal);
			X=herschaal;
		end
	end
	if length(tMin)==1
		Tmin=tMin*ones(size(Z));
	else
		Tmin=interp1(tMin(:,1),tMin(:,2),X);
	end
	i=find(ok);
	if ~isempty(i)
		if length(tMax)==1
			Tmin=tMax*ones(size(Z));;
		else
			Tmax=interp1(tMax(:,1),tMax(:,2),X);
		end
	end
else	% 3d-tabel
	if size(tMin,1)==2
		tMin=[NaN tMin(1,:);-1e6 tMin(2,:);1e6 tMin(2,:)];
	elseif size(tMin,2)==2
		tMin=[NaN -1e6 1e6;tMin(:,[1 2 2])];
	end
	if (size(tMax,1)==2)&(size(tMax,2)>2)
		tMax=[NaN tMax(1,:);-1e6 tMax(2,:);1e6 tMax(2,:)];
	elseif size(tMax,2)==2
		tMax=[NaN -1e6 1e6;tMax(:,[1 2 2])];
	end
	[X,Y,Z]=getmatr(Tab);
	if ~isempty(herschaal)
		if length(herschaal)==1
			error('herschaal bij 2d-tabellen moet lengte 2 hebben')
		else
			X1=min(X):herschaal(1):max(X);
			ix=ones(length(X),1);
			i=1;
			while i<length(X)
				j=find(X1>=X(i));
				if isempty(j)
					X1=[X1 X(i)];
					ix(i)=length(X1);
				elseif X1(j(1))==X(i)
					ix(i)=j(1);
				else
					X1=[X1(1:j(1)-1) X(i) X1(j(1):length(X1))];
					ix(i)=j(1);
				end
				i=i+1;
			end
			Y1=(min(Y):herschaal(2):max(Y))';
			iy=ones(length(X),1);
			i=1;
			while i<length(Y)
				j=find(Y1>=Y(i));
				if isempty(j)
					Y1=[Y1;Y(i)];
					iy(i)=length(Y1);
				elseif Y1(j(1))==Y(i)
					iy(i)=j(1);
				else
					Y1=[Y1(1:j(1)-1);Y(i);Y1(j(1):length(Y1))];
					iy(i)=j(1);
				end
				i=i+1;
			end
			X1=X1(ones(length(Y1),1),:);
			Y1=Y1(:,ones(size(X1,2),1));
			Z=interp3d(X,Y,Z,X1,Y1);
			X=X1(1,:);
			Y=Y1(:,1);
		end
	else
		X1=X(:)';
		X1=X1(ones(1,length(Y)),:);
		Y1=Y(:);
		Y1=Y1(:,ones(length(X),1));
		ix=1:length(X);
		iy=1:length(Y);
	end
	if length(tMin)==1
		Tmin=tMin*ones(size(Z));
	else
		[sy,sx]=size(tMin);
		Tmin=interp3d(tMin,X1,Y1);
	end
	if length(tMax)==1
		Tmax=tMax*ones(size(Z));;
	else
		[sy,sx]=size(tMax);
		Tmax=interp3d(tMax,X1,Y1);
	end
end
ok=(Z>=Tmin)&(Z<=Tmax);
if nargout
	Xok=ok;
else
	nfigure
	i=find(~ok);
	Zok=Z;
	Zok(i)=NaN*ones(length(i),1);
	i=find(ok);
	Znok=Z;
	Znok(i)=NaN*ones(length(i),1);
	plot(X,Zok(iy,:),'-')
	hold on
	plot(X,Znok(iy,:),':');grid
	hold off
	nfigure
	plot(Y,Zok(:,ix)')
	hold on
	plot(Y,Znok(:,ix)',':');grid
	hold off
end
