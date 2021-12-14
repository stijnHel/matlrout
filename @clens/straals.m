function Xuit=lensstr3ds(X0,L,Lpos)
% LENSSTR3DS - Bepaalt straal door een lens in 3D - snelle versie
%    Xuit=lensstr3D(X,lens,Lpos)
%      lens moet goed zijn(!)  weinig controles worden uitgevoerd.
%    X0 en Lpos geven positie en richting aan, richting moet niet genormaliseerd zijn (wordt toch genormaliseerd)
%      X0 moet bestaan uit twee vectoren (in kolom)
%      Lpos kan ook gegeven worden door twee vectoren
%         of door een structure met de volgende velden :
%             lens : nummer van lens in 'lens' of lens-structure
%             pos : positie (van nulpunt van lens-data)
%             orientatie :
%                vector van normale
%                rotatie-matrix (3x3)
%   In deze versie is het ook mogelijk om meer input-stralen tegelijk te
%   laten bepalen.  Dit kan door X0 meerdere kolommen te geven (groepen van
%   twee), of door een extra dimentie aan X0 te geven:
%           X0(:,:,1), X0(:,:,2), ...
%   De mogelijkheid om input-vectoren in rijen te zetten is weggehaald.
%
% zie ook lensstr3d, maaklens, lensstraal

%??mogelijkheid voorzien om oppervlakte-afhankelijke refractie-coefficienten te hebben
%   gedeeltelijk om spiegel-oppervlak te kunnen maken.

MAXINTREFL=20;

rMin=1e-3;

if nargin==2|isempty(L)
	if isfield(L,'lens')
		Lpos=L;
		L=[];
	else
		Lpos=[];
	end
end
if isempty(Lpos)
	Lpos=[0 1;0 0;0 0];
end
Rlens=[];
if isstruct(Lpos)
	if length(Lpos)~=1
		error('Momenteel kan ik maar werken met 1 lens')
	end
	if isnumeric(Lpos.lens)
		Lpos.lens=L(Lpos.lens);
	end
	Xlens=L.pos(:);
	if min(size(Lpos.orientatie))==1	% vector
		Lrich=Lpos.orientatie(:);
	elseif all(size(Lpos.pos)==3)	% rotatie-matrix
		Rlens=Lpos.pos;
	else
		error('Verkeerde spec voor orientatie')
	end
else
	if length(size(Lpos))>2
		error('Verkeerde input voor Lpos')
	elseif size(Lpos,1)==2
		Lrich=Lpos(2,:)';
		Xlens=Lpos(1,:)';
	elseif size(Lpos,2)==2
		Lrich=Lpos(:,2);
		Xlens=Lpos(:,1);
	else
		error('Verkeerde input voor Lpos')
	end
end
if isempty(Rlens)
	Lrich=Lrich/sqrt(Lrich'*Lrich);
	if max(abs(Lrich(2:3)))<1e-7
		% minstens ongeveer horizontaal vlak
		if Lrich(1)>0
			Rlens=[1 0 0;0 1 0;0 0 1];
		else
			Rlens=[-1 0 0;0 -1 0;0 0 1];
		end
	else
		p1=acos(Lrich(1));
		p2=atan2(-Lrich(2),Lrich(3));
		Rlens=rotxr(p2)*rotyr(p1)*rotxr(-p2);
			% eerste rotatie is meestal niet nodig, ze dient enkel om de (interne)
			%    data dicht bij de oorspronkelijke te houden.  Bij niet rotatiesymmetrische
			%    lenzen (prisma, ...) is dit echter wel belangrijk.
	end
end
Rlenst=Rlens';

S=L.S;

if size(X0,2)>2
	if ndims(X0)>2
		error('Verkeerde input')
	end
	X0=reshape(X0,3,2,numel(X0)/6);	% zonder meer voorafgaande tests?
		% (!)Matlab5.2
end

Xuit=X0;	% if no lens found, the output is the input
bStatus=length(X0)>10000;
if bStatus
	status('Bepalen van stralen door lenzen',0)
end
for iX0=1:size(X0,3)
	X0rich=X0(:,2,iX0);
	X0pos=X0(:,1,iX0);
	X0rich=X0rich/sqrt(X0rich'*X0rich);

	X=X0pos;
	V=X0rich;

	Y=Rlens*(X-Xlens);
	Vy=Rlens*V;
	[Xr,d,iS,Xn]=findsurfcross(S,Y,Vy);
	n=L.n;	% evt oppervlak-afhankelijk
	if ~isempty(Xr)
		cPhi=Vy'*Xn;
		sPhi=sqrt(1-cPhi*cPhi);
		sPhiUit=sPhi/n;
		straalIn=struct('cPhi',cPhi,'sPhi',sPhi,'sPhiUit',sPhiUit);
		% .... bepaling van hoeveelheid reflectie, en breking
		if sPhiUit>=1|n<=0|n>1e4
			fRefl=1;
			fBrek=0;
		else
			fRefl=0;	%!!!!!
			fBrek=1;
		end
		%!!!momenteel enkel volledige reflectie of volledige breking
		if cPhi<0
			Xn=-Xn;
		end
		Xl=cross(Vy,Xn);
		if fRefl
			if Xl'*Xl<1e-14	% waarom niet met cPhi ongeveer == 1
				Vz=-Vy;	% Loodrecht invallende straal
			else
				c=Vy+2*cross(Xl,Xn);
				Vz=-c;
			end
		end	% hier zou ook een else kunnen staan, maar op termijn moeten
			% breking en reflectie mogelijk toch samen berekend worden
		if fBrek
			if Xl'*Xl<1e-14
				Vz=V;
			else
				t=sqrt(1/(1-sPhiUit*sPhiUit)-1);
				Yl=cross(Xl,Xn);
				Yl=Yl/sqrt(Yl'*Yl);
				Vz=Xn-t*Yl;
				Vz=Vz/sqrt(Vz'*Vz);
			end
			nMaxIntRefl=MAXINTREFL;
			while nMaxIntRefl
				if length(S)==1
					i=1;
				else
					iS1=iS;
					i=setdiff(1:length(S),iS);
				end
				[Xr,d,iS,Xn]=findsurfcross(S(i),Xr+1e-7*Vz,Vz);
				if iS
					iS=i(iS);
				else
					if length(S)>1
						[Xr,d,iS,Xn]=findsurfcross(S(iS1),Xr+1e-7*Vz,Vz);
					end
					if iS
						iS=iS1;
					else
						error('??Lens binnen gekomen, maar vindt geen punt om buiten te geraken??')
					end
				end
				cPhi=Vz'*Xn;
				sPhi=sqrt(1-cPhi*cPhi);
				sPhiUit=sPhi*n;	%?oppervlak-afhankelijk
				straalUit=struct('cPhi',cPhi,'sPhi',sPhi,'sPhiUit',sPhiUit);
				% .... bepaling van hoeveelheid reflectie, en breking
				if sPhiUit>=1|n<=0|n>1e4
					fRefl=1;
					fBrek=0;
				else
					fRefl=0;	%!!!!!
					fBrek=1;
				end
				if cPhi<0
					Xn=-Xn;
				end
				Xl=cross(Vz,Xn);
				if fRefl
					if Xl'*Xl<1e-14	% waarom niet met cPhi ongeveer == 1
						Vz=-Vz;	% Loodrecht invallende straal
					else
						c=Vz+2*cross(Xl,Xn);
						Vz=-c;
					end
				end	% ??ook hier rekening houden met combinatie van reflectie en breking?
				if fBrek
					break	% nu maar een straal
				end
				nMaxIntRefl=nMaxIntRefl-1;
			end	% while intern
			if nMaxIntRefl==0
				warning('!!!Meer dan maximaal aantal interne reflecties, bepaling gestopt.')
				Vz=[];
			else
				if Xl'*Xl>=1e-14
					t=sqrt(1/(1-sPhiUit*sPhiUit)-1);
					Yl=cross(Xl,Xn);
					Yl=Yl/sqrt(Yl'*Yl);	% lengte is ook = 1/cos(phiUit)
					Vz=Xn-t*Yl;
				end
			end	% lichtstraal "buiten" gekomen
		end	% if brek
		if ~isempty(Vz)
			Vz=Vz/sqrt(Vz'*Vz);
			% terug omzetten naar standaard coordinaten
			Xuit(:,1,iX0)=Rlenst*Xr+Xlens;
			Xuit(:,2,iX0)=Rlenst*Vz;
		end
	end	% if snijpunt gevonden
	if bStatus
		status(iX0/size(X0,3))
	end
end	% for iX0
status
