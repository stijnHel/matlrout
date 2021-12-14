function varargout=zonnew(varargin)
%ZONNEW - Wat specifieke zonnewijzerwerk voor plannen Jef Helsen
%    gebruik :
%       zonnew - op basis van "zonnewijzer" wordt zonnewijzer voor terras
%                bepaald
%       deze routine is ook de callbackroutine voor UI-zaken
%                   Stijn Helsen - maart-juli 2006

% Het volgende is niet altijd nodig!

global ZONNEWarch

if isempty(ZONNEWarch)
	ZONNEWarch{1,1}=clock;
	ZONNEWarch{1,2}=varargin;
else
	ZONNEWarch{end+1,1}=clock;
	ZONNEWarch{end,2}=varargin;
end	
N_ARCH_MAX=300;
if length(ZONNEWarch)>N_ARCH_MAX
	ZONNEWarch=ZONNEWarch(end-N_ARCH_MAX+1:end,:);
end

fHZ=findobj('Tag','Huiszicht');
fZon=findobj('Tag','zonnewijzerFigure');
bAutoSpiegelOr=0;
bSetDateTime=0;
if isempty(fHZ)
	if nargin
		if ischar(varargin{1})
			[Shuis,extra]=leeszwdata(varargin{1});
			zonnew(Shuis);
			for i=1:length(extra)
				eval(extra{i});
			end
			return
		end
	else
		% structuur
		B=3.2;	% breedte muur
		H=2.58;	% hoogte
		BT=3.06;	% breedte van terras (dit wordt ook gebruikt van breedte van kort gedeelte)
		L=1.20;	% luifel-grootte
		%spiegel=[1 BT 0.4];
		spiegel=[1 1 0];
		
		DsetProj=[21 6 2006];	% als lengte kleiner dan 4, plaatselijk middaguur
		PsetProj=[1.6 L/2 H];
		anaDagen=[21-0.5/24 6 2006;21 6 2006;21+0.5/24 6 2006];
		anaUren=0:24:24*365;
		zonDagen=[21 3 2006;21 6 2006;21 9 2006;21 12 2006];
		zonUren=[10:0.05:14];
		wijzerType='analemma';
		geog='kessel-lo-helsen';
		bGeogMiddagRef=1;	% enkel voor analemma
		bAutoSpiegelOr=0;
		
		hoekZuiden=-22;
		Bvenster1=3;
		dBv=0.2;
		dHv=0.2;
		Lm2=3;
		Bvenster2=1.3;
		yV=0.8;
		% projecties op muur
		S1=struct('naam','muur'	...
			,'posvlak',[0 0 0]	...
			,'orvlak',[0 1 0]	...
			,'limprojvlak',[0 BT -H 0]	...
			,'rotprojectie',0);
		% projecties op plafond
		S2=struct('naam','luifel'	...
			,'posvlak',[0 0 H]	...
			,'orvlak',[0 0 -1]	...
			,'limprojvlak',[-L B+Bvenster1+dBv -L 0]	...
			,'rotprojectie',0);
		ZWs=struct('S',{S1,S2});
		Shuis=struct(	...
			'B',B,'H',H,'BT',BT,'L',L,'spiegel',spiegel	...
			,'Bvenster1',Bvenster1	...
			,'dBv',dBv,'dHv',dHv	...
			,'Lm2',Lm2	...
			,'Bvenster2',Bvenster2	...
			,'yV',yV	...
			,'geog',geog	...
			,'hoekZuiden',hoekZuiden	...
			,'DsetProj',DsetProj,'PsetProj',PsetProj	...
			,'anaDagen',anaDagen,'anaUren',anaUren	...
			,'zonDagen',zonDagen,'zonUren',zonUren	...
			,'bGeogMiddagRef',bGeogMiddagRef	...
			,'type',wijzerType	...
			,'bSpiegel',1	...
			,'ZWs',ZWs	...
			,'curZW',1	...
			);
	end
	bSetDateTime=1;
else
	Shuis=get(fHZ,'UserData');
end

if ~isempty(varargin)
	if ischar(varargin{1})
		switch lower(varargin{1})
		case 'toonmuur'
			if length(fHZ)~=1
				error('Juist 1 huiszichtvenster moet bestaan')
			end
			if length(fZon)~=1
				error('Een zonnewijzerfiguur moet bestaan!')
			end
			Shuis.curZW=1;
			set(fZon,'UserData',Shuis.ZWs(Shuis.curZW));
			set(fHZ,'UserData',Shuis)
			zonnewijzer('update')
			%zonnewijzer('update',{'herberZon'})
			return
		case 'toonluifel'
			if length(fHZ)~=1
				error('Juist 1 huiszichtvenster moet bestaan')
			end
			if length(fZon)~=1
				error('Een zonnewijzerfiguur moet bestaan!')
			end
			Shuis.curZW=2;
			set(fZon,'UserData',Shuis.ZWs(Shuis.curZW));
			set(fHZ,'UserData',Shuis)
			zonnewijzer('update')
			%zonnewijzer('update',{'herberZon'})
			return
		case 'toonproj'
			if length(fHZ)~=1
				error('Juist 1 huiszichtvenster moet bestaan')
			end
			if length(fZon)~=1
				error('Een zonnewijzerfiguur moet bestaan!')
			end
			Shuis.curZW=varargin{2};
			set(fZon,'UserData',Shuis.ZWs(Shuis.curZW));
			set(fHZ,'UserData',Shuis)
			zonnewijzer('update')
			return
		case 'perspectief'
			figure(fHZ)
			set(gca,'Projection','perspective')
			return
		case 'orthografisch'
			figure(fHZ)
			set(gca,'Projection','orthographic')
			return
		case 'houdlijnen'
			l=findobj(fHZ,'Tag','HZWlijn');
			set(l,'Tag','HZWlijn1')
			return
		case 'verwijderlijnen'
			l=findobj(fHZ,'Tag','HZWlijn1');
			delete(l);
			return
		case 'breedte'
			v=get(gcbo,'Value');
			ax=findobj(findobj('Tag','Huiszicht'),'Type','axes');
			set(ax,'CameraViewAngle',v);
			return
		case 'hoogte'
			v=get(gcbo,'Value');
			ax=findobj(findobj('Tag','Huiszicht'),'Type','axes');
			p=get(ax,'CameraPosition');
			p(3)=v;
			set(ax,'CameraPosition',p);
			return
		case 'camerapos'
			if length(fZon)~=1|length(fHZ)~=1
				error('Een zonnewijzer- en een "huiszicht-"figuur moet bestaan!')
			end
			Btot=Shuis.B+Shuis.BT+Shuis.dBv;
			ZW=get(fZon,'UserData');
			tp=get(gcf,'SelectionType');
			p=get(gca,'CurrentPoint');
			p=p(1,1:2);
			%disp(p);
			bCamera=0;
			bTarget=0;
			% (onderscheid tussen tuin en terras moet eigenlijk niet gemaakt worden)
			if p(2)>0	% luifel
				if p(2)>Shuis.L|p(1)<0|p(1)>Btot
					warndlg('Dit is buiten de grenzen van de luifel')
				else
					P=[Btot-p(1) p(2) Shuis.H];
					bTarget=1;
				end
				%disp luifel
			elseif p(1)<0
				bCamera=1;
				P=[Btot-p(1) -p(2)-Shuis.BT 0];
				%disp tuin
			elseif p(1)<Btot&p(2)>-Shuis.H
				bTarget=1;
				P=[Btot-p(1) 0 Shuis.H+p(2)];
				%disp muur
			elseif p(1)<Btot+Shuis.BT&p(2)>-Shuis.H-Shuis.BT
				bCamera=1;
				P=[Btot-p(1) -p(2)-Shuis.BT 0];
				%disp terras
			else
				bCamera=1;
				P=[Btot-p(1) -p(2)-Shuis.BT 0];
				%disp tuin(2)
			end
			ax=findobj(fHZ,'Type','axes');
			%disp(P)
			if bCamera
				p=get(ax,'CameraPosition');
				P(3)=p(3);
				set(ax,'CameraPosition',P);
			elseif bTarget
				set(ax,'CameraTarget',P);
			end
			return
		case 'uiupdate'
			if length(fZon)~=1|length(fHZ)~=1
				error('Een zonnewijzer- en een "huiszicht-"figuur moet bestaan!')
			end
			zonnewijzer update
			curZW=Shuis.curZW;
			ZW=get(fZon,'UserData');
			Shuis.ZWs(curZW).S.posvlak=ZW.S.posvlak;
			Shuis.ZWs(curZW).S.orvlak=ZW.S.orvlak;
			Shuis.ZWs(curZW).S.limprojvlak=ZW.S.limprojvlak;
			Shuis.ZWs(curZW).S.rotprojectie=ZW.S.rotprojectie;
			set(fHZ,'UserData',Shuis)
			zonnew
			return
		case 'autoupdateor'
			if length(fZon)~=1|length(fHZ)~=1
				error('Een zonnewijzer- en een "huiszicht-"figuur moet bestaan!')
			end
			bAutoSpiegelOr=1;
		case 'getmeridiaan'
			if length(fZon)~=1|length(fHZ)~=1
				error('Een zonnewijzer- en een "huiszicht-"figuur moet bestaan!')
			end
			M=GetMeridiaan(Shuis);
			if nargout
				varargout{1}=M';
			else
				fprintf('%6.3f  %6.3f  %6.3f\n',M)
			end
			return
		otherwise
			error('onbekende opdracht')
		end
	elseif iscell(varargin{1})
		opties=varargin{1};
		if rem(length(opties),2)
			error('Aantal opties moet even zijn')
		end
		sOpties={'B','H','BT','L','Bvenster1'	...
			,'dBv','dHv','Lm2','Bvenster2','yV'	...
			,'DsetProj','PsetProj','anaDagen','anaUren'	...
			,'zonDagen','zonUren','type'};
		UsOpties=upper(sOpties);
		for i=1:2:length(opties)
			j=strmatch(upper(opties{i}),UsOpties,'exact');
			if isempty(j)
				error(sprintf('optie "%s" is onbekend.',opties{i}))
			end
			Shuis=setfield(Shuis,sOpties{j},opties{i+1});
			if ~isempty(strmatch(upper(opties{i}),upper({'DsetProj','PsetProj'})))
				bAutoSpiegelOr=1;
			end
			if ~isempty(strmatch(upper(opties{i}),upper(	...
					{'type','anaDagen','anaUren','zonDagen','zonUren'})))
				bSetDateTime=1;
			end
		end
	elseif isstruct(varargin{1})
		Shuis=varargin{1};
	else
		error('Verkeerde input')
	end
end
Pscreen=get(0,'ScreenSize');

S=zonnewijzer({});
if isempty(fHZ)
	if ischar(Shuis.geog)
		p=geogcoor(Shuis.geog);
	else
		p=Shuis.geog;
	end
	S.geog=p;
	S.bSpiegel=Shuis.bSpiegel;
	S.pospunt=Shuis.spiegel;
	S.orpunt=[0 0 1];	% recht naar boven gerichte spiegel
	S.zuiden=deg2rad(Shuis.hoekZuiden);
else
	hZ=S.zuiden*180/pi;
	bRedrawMer=abs(hZ-Shuis.hoekZuiden)>1e-6;
	bChanged=bRedrawMer;
	Shuis.hoekZuiden=hZ;
	if ~isequal(S.pospunt,Shuis.spiegel)
		bChanged=1;
		UpdateSpiegelPos(S.pospunt);
		if ~isequal(S.pospunt(1:2),Shuis.spiegel(1:2))
			bRedrawMer=1;
		end
		Shuis.spiegel=S.pospunt;
	end
	if  bRedrawMer
		UpdateMeridiaan(Shuis)
	end
	if bChanged
		set(fHZ,'UserData',Shuis)
	end
end
hMiddag=12-S.geog(1)/pi*12;

if isempty(fZon)
	Pset=zonnewijzer('GetDefPset');
else
	ZW=get(fZon,'UserData');
	Pset=ZW.Pset;
end
%magnN=magnnoord('kessel-lo');
%S.zuiden=deg2rad(magnN-10);
if bSetDateTime
	switch lower(Shuis.type)
	case 'zonnewijzer'
		h=Shuis.zonUren;
		Nh=max(1,round(1/mean(diff(h))));
		H12=[12 13];
		i12=H12;
		for i=1:length(H12)
			[mn,i12(i)]=min(abs(h-H12(i)));
		end
		D=Shuis.zonDagen;
		bGeogMiddagRef=0;
	case 'analemma'
		h=Shuis.anaUren;
		D=Shuis.anaDagen;
		%Nh=30;
		Nh=1;
		jd0=calcjd(D(1,:));
		dd0=round(calccaldate(jd0+h(1)/24));
		iEq=[1 4 5 6];
		for i=2:length(h)
			dd=round(calccaldate(jd0+h(i)/24));
			if all(dd(iEq)==dd0(iEq))
				Nh(end+1)=i;
			end
		end
		if length(Nh)==1
			Nh(end)=length(h)+1;
		end
		H12=[];
		i12=[];
		bGeogMiddagRef=Shuis.bGeogMiddagRef;
	otherwise
		error('Onbekend type')
	end
	if bGeogMiddagRef
		h=h+hMiddag;
	end
	Pset.h=h;
	Pset.Nh=Nh;
	Pset.H12=H12;
	Pset.i12=i12;
	Pset.D=D;
end

ZWs=[];
lijnen=[];
for i=length(Shuis.ZWs):-1:1
	fn=fieldnames(Shuis.ZWs(i).S);
	fn=intersect(fn,{'posvlak','orvlak','limprojvlak','rotprojectie','naam'});
	for j=1:length(fn)
		S=setfield(S,fn{j},getfield(Shuis.ZWs(i).S,fn{j}));
	end
	
	if isempty(ZWs)
		%Moet hier iets aangepast worden om nodeloze bepaling van projecties te vermijden?
		%    (bij bAutoSpiegelOr)
		zonnewijzer('maakui',S,Pset);
		if isempty(fZon)
			fZon=findobj('Tag','zonnewijzerFigure');
			set(fZon,'Position',[10 Pscreen(4)/2 Pscreen(3)/2.1 Pscreen(4)/2.3]);
		end
		ZW=get(fZon,'UserData');
		if bAutoSpiegelOr
			if length(Shuis.DsetProj)<3
				Shuis.DsetProj(3)=2006;
			end
			if length(Shuis.DsetProj)<4
				Shuis.DsetProj(4)=hMiddag;
			end
			PsetProj=Shuis.PsetProj;
			if length(PsetProj)==1
				X=GetMeridiaan(Shuis);
				DX=cumsum([0;sqrt(sum(diff(X').^2,2))]);
				DX=DX/DX(end);
				PsetProj=interp1(DX,X',PsetProj);
			end
			p=zonnewijzer('calcorspiegel',Shuis.DsetProj,PsetProj);
			ZW.S.orpunt=p;
			set(fZon,'UserData',ZW)
			zonnewijzer('update',{'herberProj'})
		end
		ZWs=get(fZon,'UserData');
		S=ZWs.S;
		lijnen=zonnewijzer('get3Dproj');
	else
		ZW.S=S;
		set(fZon,'UserData',ZW)
		zonnewijzer('update',{'herberProj'})
		ZWs=[get(fZon,'UserData') ZWs];
		lijnen1=zonnewijzer('get3Dproj');
		lijnen=[lijnen1;lijnen];
	end
end

Shuis.ZWs=ZWs;
Shuis.curZW=1;

if isempty(fHZ)
	fHZ=figure('Tag','Huiszicht','Name','Zonnewijzer op huis'	...
		,'Position',[Pscreen(3)/2 Pscreen(4)/2 Pscreen(3)/2.1 Pscreen(4)/2.2]	...
		,'UserData',Shuis);
	hMenu=uimenu('Label','controls');
	for i=1:length(Shuis.ZWs)
		uimenu(hMenu,'Label',['Zonnewijzer-' Shuis.ZWs(i).S.naam],'Callback',['zonnew(''toonproj'',' num2str(i) ')']);
	end
	%uimenu(hMenu,'Label','Zonnewijzer-luifel','Callback','zonnew toonluifel');
	uimenu(hMenu,'Label','Perspectief','Callback','zonnew perspectief');
	uimenu(hMenu,'Label','Orthografisch','Callback','zonnew orthografisch');
	uimenu(hMenu,'Label','Houd lijnen','Callback','zonnew houdlijnen');
	uimenu(hMenu,'Label','Verwijder lijnen','Callback','zonnew verwijderlijnen');
	uimenu(hMenu,'Label','Analemma','callback','zonnew({''type'',''analemma''})');
	uimenu(hMenu,'Label','Zonnewijzer','callback','zonnew({''type'',''zonnewijzer''})');
	if isfield(Shuis,'origin')
		lHuis=plotzwdata(Shuis);
		cp=Shuis.data.camerapositie;
		ct=Shuis.data.cameratarget;
		cv=Shuis.data.cameraviewangle;
	else
		lHuis=PlotHuisDeel(Shuis);	% (handles nog nergens gebruikt)
		ax=gca;
		axis equal
		cp=[2 6 0.2];
		ct=[2 0 1.2];
		cv=50;
	end
	X=GetMeridiaan(Shuis);
	lHuis(end+1)=line(X(1,:),X(2,:),X(3,:),'linestyle','--','color',[0 0 0],'Tag','meridiaan');
	if ~isempty(cp)
		set(gca,'CameraPosition',cp)
	end
	if ~isempty(ct)
		set(gca,'CameraTarget',ct)
	end
	if ~isempty(cv)
		set(gca,'CameraViewAngle',cv)
	end
	set(gca,'UserData',struct('Huis',lHuis))
else
	figure(fHZ);
	set(fHZ,'UserData',Shuis);
	l=findobj('Tag','HZWlijn');
	delete(l);
end
s=sprintf('%d-%d-%d %d:%02d:%2.0f,',calccaldate(ZW.JD(1,:))');
title(s(1:end-1))
for i=1:length(lijnen)
	l=lijnen(i);
	line(l.X,l.Y,l.Z	...
		,'Color',l.Color	...
		,'LineStyle',l.LineStyle	...
		,'Marker',l.Marker	...
		,'LineWidth',l.LineWidth	...
		,'Tag','HZWlijn'	...
		);
end

f1=findobj('Tag','Huiszichtcontrol');
if isempty(f1)
	if isfield(Shuis,'origin')
		% Dit is nog niet gemaakt voor algemene gevallen
	else
		Bbtot=Shuis.B+Shuis.Bvenster1;	% bijna totale breedte
		Btot=Bbtot+Shuis.dBv;	% totale breedte
		Btott=Btot+Shuis.BT;
		bO1=3;
		bO2=3;
		hO=2;
		Btoto=Btott+bO2;
		Ht=Shuis.H+Shuis.BT;
		Ho=Ht+hO;
		f1=figure('Tag','Huiszichtcontrol','Name','Huis-controls'	...
			,'Position',[Pscreen(3)/2 30 Pscreen(3)/2.1 Pscreen(4)/2.4]	...
			,'Resize','off');
		pF=get(f1,'position');
		axes('Units','pixels','Position',[0 0 pF(3)-70 pF(4)]	...
			,'XTick',[],'YTick',[]	...
			,'Color','none'	...
			,'XLim',[-Shuis.BT*2,Bbtot+Shuis.BT]	...
			,'YLim',[-Ht*2 Shuis.L*2]	...
			,'ButtonDownFcn','zonnew camerapos'	...
			);
		axis equal
		pF=get(f1,'position');
		pH=uicontrol('Style','slider','Position',[pF(3)-60 0 15 pF(4)]	...
			,'Callback','zonnew hoogte'	...
			,'Tag','hoogtewijzer'	...
			,'Min',-1,'Max',4	...
			,'Value',0.2	...	!!!moet overeenkomen met werkelijke waarde
			);
		pB=uicontrol('Style','slider','Position',[pF(3)-30 0 15 pF(4)]	...
			,'Callback','zonnew breedte'	...
			,'Tag','breedtewijzer'	...
			,'Min',0.1,'Max',140	...
			,'Value',50	...	moet ook overeenkomen
			);
		line([-bO1 Btoto Btoto -bO1 -bO1],-[0 0 Ho Ho 0],'HitTest','off')
		line([0 Btot Btot 0 0 Btott Btott],-[Shuis.H Shuis.H -Shuis.L -Shuis.L Ht Ht 0],'HitTest','off')
	end
end

hUIupdate=findobj('Tag','HZWupdateButton');
if isempty(hUIupdate)
	% Voeg update-knop toe bij zonnewijzer-UI
	fUIin=findobj('Tag','zonnewijzerUIinput');
	if ~isempty(fUIin)
		h=findobj(fUIin,'Tag','ZWupdateButton');
		if isempty(h)
			error('Hier loopt iets fout')
		end
		p=get(h,'Position');
		uicontrol('Parent',fUIin,'Position',[p(1)+10 p(2)-25 p(3)-10 20]	...
			,'String','HuisUpdate'	...
			,'Callback','zonnew UIupdate'	...
			,'Tag','HZWupdateButton');
		hVec=findobj(fUIin,'String','vector');
		h=uicontextmenu('Parent',fUIin);
		uimenu(h,'Label','Update orientatie','CallBack','zonnew autoUpdateOr');
		set(hVec,'UIContextMenu',h)
	end
end

function X=GetMeridiaan(S)
hZ=S.hoekZuiden*pi/180;
p1=S.spiegel;
if isfield(S,'data')
	mvlakken=S.data.meridiaan;
	if isempty(mvlakken)
		X=zeros(3,0);
	else
		Nmer=[-cos(hZ) sin(hZ) 0];
		aMer=Nmer*p1';
		V1=GetVlak(S,mvlakken(1));
		p1(3)=(V1.a-(V1.norm(1:2)*p1(1:2)'))/V1.norm(3);
		X=p1(ones(1,length(mvlakken)),:)';
		for i=2:length(mvlakken)	% (laatste vlak dient enkel om einde aan te geven van meridiaan)
			V2=GetVlak(S,mvlakken(i));
			p2=[Nmer;V1.norm;V2.norm]\[aMer;V1.a;V2.a];
			X(:,i)=p2;
			V1=V2;
		end
	end
else
	th=tan(hZ);
	dx=th*p1(2);
	X=[p1(1)-[0 dx dx dx-th*S.L];
		p1(2) 0 0 S.L;
		0 0 S.H S.H];
end

function V=GetVlak(S,nr)
i=find(cat(2,S.data.V.nr)==nr);
if isempty(i)
	error('Kan vlak niet vinden')
end
V=S.data.V(i);

function l=PlotHuisDeel(S)
ccc=[0 0 0];
l=zeros(1,20);
Bbtot=S.B+S.Bvenster1;	% bijna totale breedte
Btot=Bbtot+S.dBv;	% totale breedte
l(1)=line([0 0 -S.BT -S.BT Btot Btot 0]	... terras
	,[0 -S.Lm2 -S.Lm2 S.BT S.BT 0 0],zeros(1,7)	...
	,'color',ccc);
l(2)=line([0 0 -S.L -S.L Btot Btot 0]	...  luifel
	,[0 -S.Lm2 -S.Lm2 S.L S.L 0 0],zeros(1,7)+S.H	...
	,'color',ccc);
l(3)=line([Btot 0 0],[0 0 -S.Lm2],[0 0 0]	... grenslijn muren en terras
	,'color',ccc);
l(4)=line([Btot Btot],[0 0],[0 S.H]	... vertikale lijn hoek naast venster
	,'color',ccc);
l(5)=line([0 0],[-S.Lm2 -S.Lm2],[0 S.H]	... vertikale lijn achter muur
	,'color',ccc);
l(6)=line([0 0],[0 0],[0 S.H]	... vertikale lijn vanuit nulpunt
	,'color',ccc);
l(7)=line([S.B S.B Bbtot Bbtot S.B],[0 0 0 0 0]	... venster in raam
	,[S.dHv S.H-S.dHv S.H-S.dHv S.dHv S.dHv]	...
	,'color',ccc);
l(8)=line([0 0 0 0 0]	... venster achter muur
	,[-S.yV -S.yV -S.yV-S.Bvenster2 -S.yV-S.Bvenster2 -S.yV]	...
	,[S.dHv S.H-S.dHv S.H-S.dHv S.dHv S.dHv],'color',ccc);
i=8;
dx=0.001;
l(i+1)=patch([0 Btot Btot -S.BT -S.BT 0]	...
	,[0 0 S.BT S.BT -S.Lm2 -S.Lm2]	...
	,zeros(1,6)-dx,[1 1 1]	...
	,'LineStyle','none');
l(i+2)=patch([0 Btot Btot -S.L -S.L 0]	...
	,[0 0 S.L S.L -S.Lm2 -S.Lm2]	...
	,zeros(1,6)+S.H+dx,[1 1 1]	...
	,'LineStyle','none');
l(i+3)=patch([Btot Btot 0 0 Btot Bbtot S.B S.B Bbtot Bbtot]	...
	,zeros(1,10)-dx	...
	,[0 S.H S.H 0 0 S.dHv S.dHv S.H-S.dHv S.H-S.dHv S.dHv],[1 1 1]	...
	,'LineStyle','none');
l(i+4)=patch(zeros(1,10)+dx	...
	,-[0 S.Lm2 S.Lm2 0 0 S.yV S.yV S.yV+S.Bvenster2 S.yV+S.Bvenster2 S.yV]	...
	,[0 0 S.H S.H 0 S.dHv S.H-S.dHv S.H-S.dHv S.dHv S.dHv],[1 1 1]	...
	,'LineStyle','none');
i=i+4;
l(i+1)=line(S.spiegel(1)+[0 0],S.spiegel(2)+[0 0],[0 S.spiegel(3)],'color',ccc	...
	,'Marker','o','MarkerSize',15,'Tag','spiegel'	...
	);
l(i+2)=line(S.spiegel(1),S.spiegel(2),S.spiegel(3),'color',ccc	...
	,'Marker','*','MarkerSize',15,'Tag','spiegel'	...
	);
i=i+2;

l=l(1:i);
%  misschien ook andere zijkant huis

function UpdateSpiegelPos(spiegel)
l=findobj('Tag','spiegel');
for i=1:length(l)
	x=get(l(i),'XData');
	y=get(l(i),'YData');
	z=get(l(i),'ZData');
	x(:)=spiegel(1);
	y(:)=spiegel(2);
	z(end)=spiegel(3);
	if length(x)>2
		warning('!!!onbekende spiegel-positie!!!')
	end
	set(l(i),'XData',x,'YData',y,'ZData',z);
end

function UpdateMeridiaan(S)
l=findobj('Tag','meridiaan');
X=GetMeridiaan(S);
set(l,'XData',X(1,:),'YData',X(2,:),'ZData',X(3,:))
