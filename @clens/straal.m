function [Xuit,Xintern,info]=straal(L,X0,Lpos,varargin)
%CLENS/STRAAL - Bepaalt straal door een lens
%    Xuit=straal(lens,X,Lpos,...)
%      lens moet goed zijn(!)  weinig controles worden uitgevoerd.
%    X0 en Lpos geven positie en richting aan, richting moet niet genormaliseerd zijn (wordt toch genormaliseerd)
%      X0 moet bestaan uit twee vectoren (in kolom of rij), start en richting
%      Lpos kan ook gegeven worden door twee vectoren
%         of door een structure met de volgende velden :
%             lens : nummer van lens in 'lens' of lens-structure
%             pos : positie (van nulpunt van lens-data)
%             orientatie :
%                vector van normale
%                rotatie-matrix (3x3)
%  extra opties :
%      'MAXINTREFL','bDoePlot','bHerteken','bTekenInStraal','bTekenNorm',
%      'lPlotEnd'

%??mogelijkheid voorzien om oppervlakte-afhankelijke refractie-coefficienten te hebben
%   gedeeltelijk om spiegel-oppervlak te kunnen maken.
%is alles 3d?

MAXINTREFL=20;
bDoePlot=nargout==0;
bHerteken=true;
bTekenInStraal=false;
bTekenNorm=false;
bTekenStart=true;
lPlotEnd=[];
b3Dplot=true;
bForceReflection=false;

if ~isempty(varargin)
	if length(varargin)==1
		opties=varargin{1};
	else
		opties=varargin;
	end
	setoptions({'MAXINTREFL','bDoePlot','bHerteken','bTekenInStraal'	...
			,'bTekenNorm','lPlotEnd','bTekenStart','b3Dplot'}  ...
		,opties)
elseif iscell(L)	% impossible - only to force options to be "variable"
	[MAXINTREFL,bDoePlot,bHerteken,bTekenInStraal	...
			,bTekenNorm,lPlotEnd,bTekenStart,b3Dplot]=deal(L{:});
end

if ~exist('Lpos','var')||isempty(Lpos)
	Lpos=[0 1;0 0;0 0];
end
if length(size(X0))>2
	error('Verkeerde input voor X0')
elseif size(X0,1)==2
	X0pos=X0(1,:)';
	X0rich=X0(2,:)';
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
		%-----eenvoudige versie ----- altijd van lens 1 naar lens 2, ...
		X1=[X0pos X0rich];
		opts=makeopts({'bDoePlot','MAXINTREFL'});
		opts{2,1}=false;	% don't plot separately
		info=cell(1,length(Lpos));
		XX=cell(1,length(Lpos));
		for i=1:length(Lpos)
			[Xuit1,Xintern1,info{i}]=straal(L,X1,Lpos(i),opts);
			%Xtot=[Xtot Xintern1 Xuit1(:)];
			XX{i}=[Xintern1 Xuit1(:)];
			X1=Xuit1;
		end
		Xtot=[[X0pos;X0rich] XX{:}];
		if nargout
			Xuit=reshape(Xtot(:,end),length(X0pos),2);
			Xintern=Xtot(:,2:end-1);
		end
		if bDoePlot
			[~,bNewFig]=getmakefig('lens3dplot');
			if bNewFig||bHerteken
				if bTekenStart
					if b3Dplot
						plot3(X0pos(1),X0pos(2),X0pos(3),'x')
					else
						plot(X0pos(1),X0pos(2),'x')
					end
				else
					if b3Dplot
						plot3(0,0,0)	% just to plot...
					else
						plot(0,0)	% just to plot...
					end
				end
				grid
				for i=1:length(Lpos)
					if isnumeric(Lpos(i).lens)
						L1=L(Lpos(i).lens);
					else
						L1=Lpos(i).lens;
					end
					if b3Dplot
						plot(L1,Lpos(i).orientatie,Lpos(i).pos);
					else
						plot(L1,Lpos(i).orientatie);
					end
				end
				if b3Dplot
					view(2)	% 3Dplot - but standard 3D-view(!)
				end
				if ismatlab()
					axis equal
				end
			end
			if isempty(lPlotEnd)
				lPlotEnd=sum(sqrt(sum(Xtot(1:3,:).^2)));
			end
			Xtot(1:3,end+1)=Xtot(1:3,end)+Xtot(4:6,end)*lPlotEnd;
			if b3Dplot
				line(Xtot(1,:),Xtot(2,:),Xtot(3,:));
			else
				line(Xtot(1,:),Xtot(2,:));
			end
		end
		return
	end
	if isnumeric(Lpos.lens)
		L=L(Lpos.lens);
	else
		L=Lpos.lens;
	end
	Xlens=Lpos.pos(:);
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
	Rlens=CalcRlens(Lrich);
end

S=L.S;

if bDoePlot
	lenVec=0.002;
	colVec=[0 1 0];
	[~,bNewFig]=getmakefig('lens3dplot');
	if bNewFig||bHerteken
		if bTekenStart
			if b3Dplot
				plot3(X0pos(1),X0pos(2),X0pos(3),'x')
			else
				plot(X0pos(1),X0pos(2),'x')
			end
		elseif b3Dplot
			plot3(0,0,0)	% just to plot...
			view(2)	% 3Dplot - but standard 3D-view(!)
		else
			plot(0,0)	% just to plot...
		end
		grid
		if ismatlab()
			axis equal
		end
		if b3Dplot
			%plotsurf(S,Rlens,Xlens);
			plot(L,Rlens,Xlens)
		else
			plot(L,Rlens,Xlens)	%??!!
		end
	end
	if isempty(lPlotEnd)
		if isfield(L,'Lteken')
			lPlotEnd=L.Lteken;
		else
			lPlotEnd=baselen(L);
			%lPlotEnd=max(max(cat(2,L.D.D)),sqrt(sum((Xlens-X0pos).^2)));
		end
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
		if b3Dplot
			line([X0pos(1) Xr_(1)],[X0pos(2) Xr_(2)],[X0pos(3) Xr_(3)])
		else
			line([X0pos(1) Xr_(1)],[X0pos(2) Xr_(2)])
		end
		if bTekenInStraal
			if b3Dplot
				line(Xr_(1)-[-0.5 1]*Vy_(1)*lenVec,Xr_(2)-[-0.5 1]*Vy_(2)*lenVec,Xr_(3)-[0 1]*Vy_(3)*lenVec,'color',[1 0 0]);
			else
				line(Xr_(1)-[-0.5 1]*Vy_(1)*lenVec,Xr_(2)-[-0.5 1]*Vy_(2)*lenVec,'color',[1 0 0]);
			end
		end
		if bTekenNorm
			if b3Dplot
				line(Xr_(1)+[-1 1]*Xn_(1)*lenVec,Xr_(2)+[-1 1]*Xn_(2)*lenVec,Xr_(3)+[-1 1]*Xn_(3)*lenVec,'color',colVec);
			else
				line(Xr_(1)+[-1 1]*Xn_(1)*lenVec,Xr_(2)+[-1 1]*Xn_(2)*lenVec,'color',colVec);
			end
		end
	end
	
	% .... bepaling van hoeveelheid reflectie, en breking
	if bForceReflection||sPhiUit>=1||n<=0||n>1e4
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
			[Xr,d,iS,Xn]=findsurfcross(S,Xr+1e-7*Vz,Vz);
			if isempty(Xr)
				break
			elseif iS==0
				error('??Lens binnen gekomen, maar vindt geen punt om buiten te geraken??')
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
				if b3Dplot
					line([Xr_oud(1) Xr_(1)],[Xr_oud(2) Xr_(2)],[Xr_oud(3) Xr_(3)])
				else
					line([Xr_oud(1) Xr_(1)],[Xr_oud(2) Xr_(2)])
				end
				if bTekenInStraal
					if b3Dplot
						line(Xr_(1)-[-0.5 1]*Vz_(1)*lenVec,Xr_(2)-[-0.5 1]*Vz_(2)*lenVec,Xr_(3)-[0 1]*Vz_(3)*lenVec,'color',[1 0 0]);
					else
						line(Xr_(1)-[-0.5 1]*Vz_(1)*lenVec,Xr_(2)-[-0.5 1]*Vz_(2)*lenVec,'color',[1 0 0]);
					end
				end
				if bTekenNorm
					if b3Dplot
						line(Xr_(1)+[-1 1]*Xn_(1)*lenVec,Xr_(2)+[-1 1]*Xn_(2)*lenVec,Xr_(3)+[-1 1]*Xn_(3)*lenVec,'color',colVec);
					else
						line(Xr_(1)+[-1 1]*Xn_(1)*lenVec,Xr_(2)+[-1 1]*Xn_(2)*lenVec,'color',colVec);
					end
				end
			end
			% .... bepaling van hoeveelheid reflectie, en breking
			if sPhiUit>=1||n<=0||n>1e4
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
		elseif isempty(Xr)
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
	if isempty(Vz)
		Xr=nan(3,1);
		Vz=nan(3,1);
		straalUit=[];
	else
		Vz=Vz/sqrt(Vz'*Vz);
	end
	% terug omzetten naar standaard coordinaten
	Xint=[Xint,[Xr;Vz]];
	Xint(1:3,:)=bsxfun(@plus,Xint(1:3,:),Xlens);
	Xuit=Rlens'*[Xr Vz];
	Xuit(:,1)=Xuit(:,1)+Xlens;
	if bDoePlot
		if b3Dplot
			line(Xuit(1,1)+[0 Xuit(1,2)*lPlotEnd],Xuit(2,1)+[0 Xuit(2,2)*lPlotEnd],Xuit(3,1)+[0 Xuit(3,2)*lPlotEnd])
		else
			line(Xuit(1,1)+[0 Xuit(1,2)*lPlotEnd],Xuit(2,1)+[0 Xuit(2,2)*lPlotEnd])
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

function Rlens=CalcRlens(Lrich)
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
