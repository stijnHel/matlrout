function [Xuit,Xintern,info]=lensstr3d(X0,L,Lpos,varargin)
% LENSSTR3D - Bepaalt straal door een lens in 3D
%    Xuit=lensstr3D(X,lens,Lpos)
%      lens moet goed zijn(!)  weinig controles worden uitgevoerd.
%    X0 en Lpos geven positie en richting aan, richting moet niet genormaliseerd zijn (wordt toch genormaliseerd)
%      X0 moet bestaan uit twee vectoren (in kolom of rij)
%      Lpos kan ook gegeven worden door twee vectoren
%         of door een structure met de volgende velden :
%             lens : nummer van lens in 'lens' of lens-structure
%             pos : positie (van nulpunt van lens-data)
%             orientatie :
%                vector van normale
%                rotatie-matrix (3x3)
%
% zie ook maaklens, lensstraal

%??mogelijkheid voorzien om oppervlakte-afhankelijke refractie-coefficienten te hebben
%   gedeeltelijk om spiegel-oppervlak te kunnen maken.

MAXINTREFL=20;
bDoePlot=nargout==0;
bHerteken=true;
bTekenInStraal=false;
bTekenNorm=false;

if ~isempty(varargin)
	if length(varargin)==1
		opties=varargin{1};
	else
		opties=varargin;
	end
	if ~iscell(opties)||rem(length(opties),2)
		error('Verkeerde opties')
	end
	mOpties={'MAXINTREFL','bDoePlot','bHerteken','bTekenInStraal','bTekenNorm'};
	UMO=upper(mOpties);
	for i=1:2:length(opties)
		j=strmatch(upper(opties{i}),UMO,'exact');
		if isempty(j)
			warning(sprintf('optie "%s" is niet gekend',opties{i}))
		else
			assignval(mOpties{j},opties{i+1});
		end
	end
end

if nargin==2||isempty(L)
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
if length(size(X0))>2
	error('Verkeerde input voor X0')
elseif size(X0,1)==2
	X0rich=X0(2,:)';
	X0pos=X0(1,:)';
elseif size(X0,2)==2
	X0rich=X0(:,2);
	X0pos=X0(:,1);
else
	error('Verkeerde input voor X0')
end
X0rich=X0rich/sqrt(X0rich'*X0rich);
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

S=lenssurf(L);

if bDoePlot
	lenVec=0.002;
	colVec=[0 1 0];
	f=findobj('Tag','lens3dplot');
	if isempty(f)
		f=nfigure;
		set(f,'Tag','lens3dplot');
		bNewFig=true;
	else
		figure(f)
		bNewFig=false;
	end
	if bNewFig||bHerteken
		plot3(X0pos(1),X0pos(2),X0pos(3),'x');grid
		view(2)
		axis equal
		plotsurf(S,Rlens,Xlens);
	end
	if isfield(L,'Lteken')
		Lplot=L.Lteken;
	else
		Lplot=max(max(cat(2,L.D)),sqrt(sum((Xlens-X0pos).^2)));
	end
end

X=X0pos;
V=X0rich;

Y=Rlens*(X-Xlens);
Vy=Rlens*V;
[Xr,d,iS,Xn]=findsurfcross(S,Y,Vy);
n=L.n;	% evt oppervlak-afhankelijk
Xint=zeros(6,0);
if isempty(Xr)
	Xuit=[X V];
else
	cPhi=Vy'*Xn;
	sPhi=sqrt(1-cPhi*cPhi);
	sPhiUit=sPhi/n;
	straalIn=struct('cPhi',cPhi,'sPhi',sPhi,'sPhiUit',sPhiUit);
	if bDoePlot
		Xr_=Rlens'*Xr+Xlens;
		Vy_=Rlens'*Vy;
		Xn_=Rlens'*Xn;
		line([X0pos(1) Xr_(1)],[X0pos(2) Xr_(2)],[X0pos(3) Xr_(3)])
		if bTekenInStraal
			line(Xr_(1)-[-0.5 1]*Vy_(1)*lenVec,Xr_(2)-[-0.5 1]*Vy_(2)*lenVec,Xr_(3)-[0 1]*Vy_(3)*lenVec,'color',[1 0 0]);
		end
		if bTekenNorm
			line(Xr_(1)+[-1 1]*Xn_(1)*lenVec,Xr_(2)+[-1 1]*Xn_(2)*lenVec,Xr_(3)+[-1 1]*Xn_(3)*lenVec,'color',colVec);
		end
	end
	
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
		Xint=[Xr;Vz];
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
			if bDoePlot
				Xr_oud=Xr_;
				Xr_=Rlens'*Xr+Xlens;
				Vz_=Rlens'*Vz;
				Xn_=Rlens'*Xn;
				line([Xr_oud(1) Xr_(1)],[Xr_oud(2) Xr_(2)],[Xr_oud(3) Xr_(3)])
				if bTekenInStraal
					line(Xr_(1)-[-0.5 1]*Vz_(1)*lenVec,Xr_(2)-[-0.5 1]*Vz_(2)*lenVec,Xr_(3)-[0 1]*Vz_(3)*lenVec,'color',[1 0 0]);
				end
				if bTekenNorm
					line(Xr_(1)+[-1 1]*Xn_(1)*lenVec,Xr_(2)+[-1 1]*Xn_(2)*lenVec,Xr_(3)+[-1 1]*Xn_(3)*lenVec,'color',colVec);
				end
			end
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
				Xint=[Xint,[Xr;Vz]];	% !!!Vz niet genormaliseerd(?) of is dit wel?
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
		Xint=[Xint,[Xr;Vz]];
		% terug omzetten naar standaard coordinaten
		Xuit=Rlens'*[Xr Vz];
		Xuit(:,1)=Xuit(:,1)+Xlens;
		if bDoePlot
			line(Xuit(1,1)+[0 Xuit(1,2)*Lplot],Xuit(2,1)+[0 Xuit(2,2)*Lplot],Xuit(3,1)+[0 Xuit(3,2)*Lplot])
		end
	end
end	% if snijpunt gevonden

if nargout>1
	if isempty(Xint)
		Xintern=[];
		info=[];
	else
		Xintern=[Rlens'*Xint(1:3,1:end-1)+Xlens(:,ones(size(Xint,2)-1,1));
			Rlens'*Xint(4:6,1:end-1)];
		info=struct('L',L,'S',S	...
			,'Rlens',Rlens	...
			,'Xr',Xr,'d',d,'iS',iS,'Xn',Xn	...
			,'Xint',Xint,'nIntRefl',MAXINTREFL-nMaxIntRefl	...
			,'sIn',straalIn,'sUit',straalUit	...
			);
	end
end
