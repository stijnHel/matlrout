function [Pproj,Suit]=zonnewijzer(S,p,Pset)% ZONNEWIJZER - Berekeningen voor zonnewijzer%    Pproj=zonnewijzer(S,p)%       bepaalt de plaats waar een bepaalde straal door een punt op een vlak valt%         S : structure met positiegegevens%         p : richting straal, maar gezien op de aarde (normaal stand van de zon,%               right ascention en declination), in radialen%   Voor het maken van S kan ook gebruik gemaakt worden van deze functie:%       S=zonnewijzer({<datanaam>,<data>,...})%        mogelijke data :%           'geog' : geografische coordinaten (in graden) of plaatsnaam gekend door geogcoor%           'zuiden' : positie van zuiden ten opzichte van lokale coordinaten%                          (!gegrafische en niet magnetische zuiden!)%                          graden%           'pospunt' : positie van geprojecteerde punt (in meter)%           'posvlak' : orientatie van vlak%           'orvlak' : orientatie van vlak%               ofwel 3 rechthoekige coordinaten (van normale op vlak)%               ofwel inclinatie (0 horizontaal, 90 vertikaal) en positie van rotatie-as% ui:%   apart venster voor inputs (misschien na update toch terug "controle" over ui-inputs(?))%   datums, uren, aparte uren%   extremen projectievlak (!!! denk aan update patch !!!)%   tekenen van lijn door bepaalde uren (over verschillende lijnen)%   misschien ook tekenen van (...)% toevoegen%  op 3D-fig - knoppen voor vaste orientaties (view)%         6 hoofdrichtingen, 3D-standaard, zicht tov proj vlak,%         zicht tov spiegel, zicht tov zuiden...%  ?kiezen voor autoupdate van 3D-vensters?%  ?verschillende "hoofdvenster-layouts"?%          enkel projectievlak%          en/of 3D-vlak%          ?meerdere zichten%  bij 3D-zichten N, O, Z, W pijlen toevoegen%  wat met rotatie projectievlak?% gekende fouten% richting van straal tov punt wordt niet bekeken !(spiegel werkt in twee richtingen%    en punt wordt ook geprojecteerd als straal het punt nog niet gezien heeft!)if ~exist('S','var')	S='maakui';endf=findobj('Tag','zonnewijzerFigure');if iscell(S)  	if nargin>1   		error('Bij opvragen van zonnewijzer-struct mag maar 1 input zijn!')   	end	if ~isempty(S)&isstruct(S{1})		P=S{1};		S(1)=[];	elseif ~isempty(f)		ZW=get(f,'UserData');		P=ZW.S;	else		P=struct('geog',geogcoor('alken-helsen')	...			,'zuiden',0	...			,'bSpiegel',0	...			,'pospunt',[0 0 1]	...			,'orpunt',[0 0 1]	...			,'posvlak',[0 0 0]	...			,'orvlak',[0 0 1]	...			,'limprojvlak',[-10 10 -10 10]	...			,'rotprojectie',0	... nu (nog) niet (meer) gebruikt			,'centr2D',[]	... te berekenen (niet gebruikt)			,'Rprojvlak',[]	...	te berekenen			,'Rrotvlak',[]	... te berekenen (niet gebruikt)			,'Vorpunt',[]	... te berekenen			);	end	if rem(length(S),2)		error('geen even aantal gegevens bij instellen van zonnewijzer')	end	i=1;	bZonStand=0;	% wijzigingen in zonnestand-bepaling	bProj=0;		% wijzigingen in projectie	while i<length(S)		i=i+1;		switch lower(S{i-1})		case 'geog'			P.geog=S{i};			bZonStand=1;		case 'zuiden'			P.zuiden=S{i};			bProj=1;		case 'spiegel'			P.bSpiegel=S{i};			bProj=1;		case 'orpunt'			p=S{i}(:)';			if length(p)==3				if all(p==0)					error('orientatie-vector mag geen nul-vector zijn')				end			elseif length(p)==2			else				error('Verkeerde input voor orpunt')			end			P.orpunt=p;			bProj=1;		case 'pospunt'			P.pospunt=S{i}(:)';			bProj=1;		case 'posvlak'			P.posvlak=S{i}(:)';			bProj=1;		case 'orvlak'			p=S{i}(:)';			if length(p)==3				if all(p==0)					error('orientatie-vector mag geen nul-vector zijn')				end				p=p/sqrt(p*p');			elseif length(p)==2			else				error('Verkeerde input voor orvlak')			end			P.orvlak=p;			bProj=1;		case 'limprojvlak'			P.limprojvlak=S{i};			if P.limprojvlak(1)>P.limprojvlak(2)				x=P.limprojvlak(1);				P.limprojvlak(1)=P.limprojvlak(2);				P.limprojvlak(2)=x;			elseif P.limprojvlak(1)==P.limprojvlak(2)				P.limprojvlak(1)=P.limprojvlak(1)-0.001;				P.limprojvlak(2)=P.limprojvlak(2)+0.001;			end			if P.limprojvlak(3)>P.limprojvlak(4)				x=P.limprojvlak(3);				P.limprojvlak(3)=P.limprojvlak(4);				P.limprojvlak(4)=x;			elseif P.limprojvlak(3)==P.limprojvlak(4)				P.limprojvlak(3)=P.limprojvlak(3)-0.001;				P.limprojvlak(4)=P.limprojvlak(4)+0.001;			end			bProj=1;		case 'rotprojectie'			if length(S{i})~=1				error('Verkeerde input voor rotprojecti')			end			P.rotprojectie=S{i};			bProj=1;		otherwise			error(sprintf('Onbekende input voor zonnewijzer-Positie-bepaling',S{i-1}))		end		i=i+1;	end		% bepaling rotatiematrix projectievlak3D-->projectievlak2D	p=P.orvlak;	if length(p)==3		if max(abs(p(1:2)))<1e-7			% minstens ongeveer horizontaal vlak			if p(3)>0				p=[0 0];			else				p=[pi 0];			end		else			p1=acos(p(3));			p2=atan2(-p(1),p(2));			p=[p1 p2];		end	end	centr2D=mean(reshape(P.limprojvlak,2,2));	P.Rprojvlak=rotzr(p(2))*rotxr(p(1))*rotzr(-p(2));	P.avlak=P.Rprojvlak(3,:)*P.posvlak';	P.Rrotvlak=[cos(P.rotprojectie) -sin(P.rotprojectie);sin(P.rotprojectie) cos(P.rotprojectie)];	if length(P.orpunt)==2		p=P.orpunt;		P.Vorpunt=[-sin(p(2))*sin(p(1)) cos(p(2))*sin(p(1)) cos(p(1))];	else		P.Vorpunt=P.orpunt/sqrt(P.orpunt*P.orpunt');	end	Pproj=P;	if nargout>1		Suit=[bZonStand bProj];	end	returnelseif ischar(S)	switch lower(S)	case 'zbd'		if isempty(f)			return	% kan niets doen		end		f1=gcf;		l=gco;		cp=get(gca,'CurrentPoint');		lUD=get(l,'UserData');		if isempty(lUD)			error('Hier loopt iets fout')		end		if isstruct(lUD)			p=lUD.p;		else			p=lUD;		end		ZW=get(f,'UserData');		%Xform=get(gca,'XForm');		Xform=view(gca);		br=get(gca,'PlotBoxAspectRatio');		X=[get(l,'XData');get(l,'YData');get(l,'ZData')];		Xform=Xform(1:3,1:3);		Xfig=Xform*(X./br(ones(1,size(X,2)),:)');		Xpt=Xform*(cp(1,1:3)./br)';		[mn,iPt]=min((Xfig(1,:)-Xpt(1)).^2+(Xfig(2,:)-Xpt(2)).^2);		if ZW.S.bSpiegel			if ZW.P2(iPt,p,3)>0				Xl=[X(:,iPt) ZW.S.pospunt' squeeze(ZW.P2_3D(iPt,p,:))];			else				Xl=[X(:,iPt) ZW.S.pospunt'];			end		else			if ZW.P2(iPt,p,3)>0				Xl=[X(:,iPt) squeeze(ZW.P2_3D(iPt,p,:))];			else				Xl=[X(:,iPt) ZW.S.pospunt'];			end		end		hL=line(Xl(1,:),Xl(2,:),Xl(3,:)	...			,'color',[1 0 0]	...			);		h=ZW.Pset.h(iPt);		if h>=0 & h<=24			s=sprintf('%5.2fhUTC',ZW.Pset.h(iPt));		else			s=sprintf('%d-%d-%d %d:%02d:%02.0f',calccaldate(ZW.JD(iPt,p)));		end		hT=text(X(1,iPt),X(2,iPt),X(3,iPt),s);		P=struct('p',p	...			,'ZW',ZW	...			,'Xform',Xform,'br',br	...			,'X',X	...			,'Xfig',Xfig	...			,'hL',hL	...			,'hT',hT	...			);		set(l,'UserData',P);		set(f1,'WindowButtonMotionFcn','zonnewijzer zbm'	...			,'WindowButtonUpFcn','zonnewijzer zbu')	case 'zbm'		l=gco;		cp=get(gca,'CurrentPoint');		P=get(l,'UserData');		Xpt=P.Xform*(cp(1,1:3)./P.br)';		[mn,iPt]=min((P.Xfig(1,:)-Xpt(1)).^2+(P.Xfig(2,:)-Xpt(2)).^2);		if P.ZW.S.bSpiegel			if P.ZW.P2(iPt,P.p,3)>0				Xl=[P.X(:,iPt) P.ZW.S.pospunt' squeeze(P.ZW.P2_3D(iPt,P.p,:))];			else				Xl=[P.X(:,iPt) P.ZW.S.pospunt'];			end		else			if P.ZW.P2(iPt,P.p,3)>0				Xl=[P.X(:,iPt) squeeze(P.ZW.P2_3D(iPt,P.p,:))];			else				Xl=[P.X(:,iPt) P.ZW.S.pospunt'];			end		end		set(P.hL,'XData',Xl(1,:),'YData',Xl(2,:),'ZData',Xl(3,:))		h=P.ZW.Pset.h(iPt);		if h>=0 & h<=24			s=sprintf('%5.2fhUTC',P.ZW.Pset.h(iPt));		else			s=sprintf('%d-%d-%d %d:%02d:%02.0f',calccaldate(P.ZW.JD(iPt,P.p)));		end		set(P.hT,'Position',P.X(:,iPt)	...			,'String',s)	case 'zbu'		selType=get(gcf,'selectiontype');		l=gco;		set(gcf,'WindowButtonMotionFcn','','WindowButtonUpFcn','')		P=get(l,'UserData');		switch selType		case 'alt'			set(P.hL,'UserData',[P.hL,P.hT],'ButtonDownFcn','delete(get(gcbo,''UserData''))')		case 'open'			set(P.hL,'UserData',[P.hL,P.hT],'ButtonDownFcn','delete(get(gcbo,''UserData''))')		case 'normal'			delete(P.hL)			delete(P.hT)			P.hL=[];			P.hT=[];		otherwise			delete(P.hL)			delete(P.hT)			P.hL=[];			P.hT=[];			warning('!!onbekend selection-type')		end	case 'maakui'		if isempty(f)			if nargin>1				if isstruct(p)					S=zonnewijzer({p});				else					S=zonnewijzer(p);				end			else				S=zonnewijzer({});			end			f=figure;			set(f,'Name','Zonnewijzer','Numbertitle','off'	...				,'Tag','zonnewijzerFigure'	...				,'Color',[0.9 0.9 0.9]	...				)			ax=axes('Position',[0.01 0.01 0.98 0.98]);			axis(S.limprojvlak)			axis equal			set(gca,'visible','off')			if nargin<3				Pset=GetDefPset;			end			ZW=struct('S',S,'Pset',Pset	...				,'JD',[]	...				,'P1',[],'P2_3D',[],'P2',[]	...				,'bZonStandOK',0	...				,'bProjOK',0	...				,'daglijnen',[]	...				);			set(f,'UserData',ZW)		elseif nargin>1			figure(f);			ZW=get(f,'UserData');			if isempty(ZW.P1)				ZW.bZonStandOK=0;			else				sZonInfl={'geog'};				sProjInfl={'zuiden','bSpiegel','pospunt','orpunt','posvlak'	...					,'orvlak','limprojvlak','rotprojectie'};				bZonStandOK=1;				bProjOK=1;				for i=1:length(sZonInfl)					bZonStandOK=bZonStandOK&isequal(getfield(p,sZonInfl{i}),getfield(ZW.S,sZonInfl{i}));				end				for i=1:length(sProjInfl)					bProjOK=bProjOK&isequal(getfield(p,sProjInfl{i}),getfield(ZW.S,sProjInfl{i}));				end				ZW.S=p;				ZW.bZonStandOK=bZonStandOK;				ZW.bProjOK=bProjOK;			end			if nargin>2				if ~isequal(Pset,ZW.Pset)					ZW.Pset=Pset;					ZW.bZonStandOK=0;				end			end			set(f,'UserData',ZW);		else			figure(f);		end		zonnewijzer update		zonnewijzer maakuiinput	case 'update'		if isempty(f)			errordlg('Update is niet mogelijk als geen venster bestaat - start met zonnewijzer')			return		end		figure(f)		ZW=get(f,'UserData');		if nargin==1			p=leesuis;		end		if ~iscell(p)			error('Bij "update" met twee inputs moet tweede input een cell-array zijn!')		elseif ~isempty(p)			if strcmp(p{1},'herberZon')				p(1)=[];				ZW.bZonStandOK=0;			elseif strcmp(p{1},'herberProj')				p(1)=[];				ZW.bProjOK=0;			end			if rem(length(p),2)				error('Bij "update" met twee inputs moet tweede input een even aantal elementen hebben!')			end		end		i=1;		while i<length(p)			switch lower(p{i})			case 'h'				h=p{i+1};				ZW.Pset.h=h;				ZW.Pset.Nh=max(1,round(1/mean(diff(h))));				ZW.Pset.i12=ZW.Pset.H12;				for j=1:length(ZW.Pset.H12)					[mn,ZW.Pset.i12(j)]=min(abs(h-ZW.Pset.H12(j)));				end				p(i:i+1)=[];				ZW.bZonStandOK=0;			case 'd'				ZW.Pset.D=p{i+1};				p(i:i+1)=[];				ZW.bZonStandOK=0;			case 'Nh'				ZW.Pset.Nh=p{i+1};				p(i:i+1)=[];				ZW.bProjOK=1;			case 'H12'				ZW.Pset.H12=p{i+1};				p(i:i+1)=[];				ZW.bProjOK=1;			case 'i12'				ZW.Pset.i12=p{i+1};				p(i:i+1)=[];				ZW.bProjOK=1;			otherwise				i=i+2;			end		end		if isempty(p)			[ZW.S,wijz]=zonnewijzer({ZW.S});			ZW.bZonStandOK=ZW.bZonStandOK&~wijz(1);			ZW.bProjOK=ZW.bProjOK&~wijz(2);		else			[ZW.S,wijz]=zonnewijzer({ZW.S,p{:}});			ZW.bZonStandOK=ZW.bZonStandOK&~wijz(1);			ZW.bProjOK=ZW.bProjOK&~wijz(2);		end		if ~ZW.bZonStandOK			status('Bepalen zonnestanden')			ZW=CalcPos(ZW);			status			ZW.bZonStandOK=1;			ZW.bProjOK=0;		end		if ~ZW.bProjOK			status('Bepalen projecties')			ZW=CalcProj(ZW);			ZW.bProjOK=1;			status		end		P2=ZW.P2;		figure(f)		delete(findobj(gca,'type','line'))		delete(findobj(gca,'type','patch'))		ccc=get(gca,'colororder');		while size(ccc,1)<size(P2,2)			ccc=[ccc;ccc];		end		Lim=ZW.S.limprojvlak;		patch(Lim([1 2 2 1 1]),Lim([3 3 4 4 3]),[0.4 0.4 0.4])		h=uicontextmenu;		uimenu(h,'Label','plot3D','CallBack','zonnewijzer plot3d');		line(0,0,'Color',[1 1 1],'Linestyle','none'	...			,'Marker','o','Markersize',12	...			,'UIContextMenu',h	...			);		Pset=ZW.Pset;		Nh=Pset.Nh;		i12=Pset.i12;		l=zeros(1,size(P2,2));		sleg=cell(1,size(P2,2));		Lim=ZW.S.limprojvlak;		for i=1:size(P2,2)			P1=squeeze(P2(:,i,:));			if length(Nh)>1				j=Nh(P1(Nh,3)>0);			else				j=find(P1(1:Nh:end,3)>0);				j=(j-1)*Nh+1;			end			line(P1(j,1),P1(j,2),'color',ccc(i,:),'linestyle','none','marker','x','Tag','ZWlijn');			h=uicontextmenu;			sL=Dstring(ZW.Pset.D(i,:));			uimenu(h,'Label',sL	...				,'CallBack',sprintf('zonnewijzer(''plot3d'',%d);',i));			if ~isempty(i12)				if P1(i12(1),3)>0					line(P1(i12(1),1),P1(i12(1),2),'color',ccc(i,:),'linestyle','none','marker','o','markersize',8,'Tag','ZWlijn');				end				if length(i12)>1					if P1(i12(2),3)>0						line(P1(i12(2),1),P1(i12(2),2),'color',ccc(i,:),'linestyle','none','marker','+','markersize',8,'Tag','ZWlijn');					end				end			end			j=find(P1(:,3)>0)';			if ~isempty(j)				jg=[0 find(diff(j)>1) length(j)];				for k=1:length(jg)-1					j1=j(jg(k)+1);					j2=j(jg(k+1));					%!Dit kan fout lopen wanneer 1 punt buiten de grenzen valt! of wanneer limiet helemaal tussen twee punten valt					if j1>1&P1(j1-1,3)==0						j1=j1-1;						if P1(j1,1)<Lim(1)							P1(j1,2)=P1(j1,2)+(P1(j1+1,2)-P1(j1,2))/(P1(j1+1,1)-P1(j1,1))*(Lim(1)-P1(j1,1));							P1(j1,1)=Lim(1);						elseif P1(j1,1)>Lim(2)							P1(j1,2)=P1(j1,2)+(P1(j1+1,2)-P1(j1,2))/(P1(j1+1,1)-P1(j1,1))*(Lim(2)-P1(j1,1));							P1(j1,1)=Lim(2);						end						if P1(j1,2)<Lim(3)							P1(j1,1)=P1(j1,1)+(P1(j1+1,1)-P1(j1,1))/(P1(j1+1,2)-P1(j1,2))*(Lim(3)-P1(j1,2));							P1(j1,2)=Lim(3);						elseif P1(j1,2)>Lim(4)							P1(j1,1)=P1(j1,1)+(P1(j1+1,1)-P1(j1,1))/(P1(j1+1,2)-P1(j1,2))*(Lim(4)-P1(j1,2));							P1(j1,2)=Lim(4);						end					end					if j2<size(P1,1)&P1(j2+1,3)==0						j2=j2+1;						if P1(j2,1)<Lim(1)							P1(j2,2)=P1(j2,2)+(P1(j2-1,2)-P1(j2,2))/(P1(j2-1,1)-P1(j2,1))*(Lim(1)-P1(j2,1));							P1(j2,1)=Lim(1);						elseif P1(j2,1)>Lim(2)							P1(j2,2)=P1(j2,2)+(P1(j2-1,2)-P1(j2,2))/(P1(j2-1,1)-P1(j2,1))*(Lim(2)-P1(j2,1));							P1(j2,1)=Lim(2);						end						if P1(j2,2)<Lim(3)							P1(j2,1)=P1(j2,1)+(P1(j2-1,1)-P1(j2,1))/(P1(j2-1,2)-P1(j2,2))*(Lim(3)-P1(j2,2));							P1(j2,2)=Lim(3);						elseif P1(j2,2)>Lim(4)							P1(j2,1)=P1(j2,1)+(P1(j2-1,1)-P1(j2,1))/(P1(j2-1,2)-P1(j2,2))*(Lim(4)-P1(j2,2));							P1(j2,2)=Lim(4);						end					end					% dan over y (j1 en j2)					l(i)=line(P1(j1:j2,1),P1(j1:j2,2),'color',ccc(i,:)	...						,'Tag','ZWlijn'	...						,'UIContextMenu',h);				end	% for k				sleg{i}=Dstring(ZW.Pset.D(i,:));			end	% if ~isempty(j)		end	% for i		axis equal		sleg=sleg(l~=0);		l=l(l~=0);		if ~isempty(l)			legend(l,sleg{:})		end		ZW.daglijnen=l;		set(f,'UserData',ZW);		axis(ZW.S.limprojvlak)		axis equal		updateuifig	case 'maakuiinput'		f1=maakuifig;		updateuifig		if nargout			Pproj=f1;		end	case 'plot3d'		if isempty(f)			errordlg('plot3d is niet mogelijk als geen venster bestaat - start met zonnewijzer')			return		end		ZW=get(f,'UserData');		f1=nfigure;		plot3(0,0,0);grid		R=ZW.S.Rprojvlak';		lijnen=get3Dprojs(f);		for i=1:length(lijnen)			l=lijnen(i);			line(l.X,l.Y,l.Z	...				,'Color',l.Color	...				,'LineStyle',l.LineStyle	...				,'Marker',l.Marker	...				,'LineWidth',l.LineWidth	...				);		end		Lim=ZW.S.limprojvlak;		x=Lim([1 2 2 1 1]);		y=Lim([3 3 4 4 3]);		z=[0 0 0 0 0];		X=R*[x;y;z]+ZW.S.posvlak([1 1 1 1 1],:)';		line(X(1,:),X(2,:),X(3,:))		P=ZW.S.pospunt;		line(P(1),P(2),P(3)	...			,'Marker','o'	...			,'MarkerSize',12)		if nargin>1			sp=size(p);			if length(sp)~=2|~isnumeric(p)				error('zulke input is hier niet voorzien')			end			if all(sp==[1 2])				Pp=squeeze(ZW.P2(p(1),p(2),1:2));				Pp(3)=0;				P2=R*Pp;				% !als geen spiegel!				P0=2*P'-P2;				line([P0(1) P2(1)],[P0(2) P2(2)],[P0(3) P2(3)]	...					,'color',[1 0 0]	...					,'linewidth',3	...					,'marker','d'	...					);			elseif all(sp==1)				Rz=max(Lim(2)-Lim(1),Lim(4)-Lim(3));				P1=squeeze(ZW.P1(:,p,:));				P2=squeeze(ZW.P2(:,p,:));				P1(:,1)=P1(:,1)+ZW.S.zuiden;				X=ZW.S.pospunt(ones(size(P1,1),1),:)+Rz*[sin(P1(:,1)).*cos(P1(:,2)) cos(P1(:,1)).*cos(P1(:,2)) sin(P1(:,2))];				X(X(:,3)<0,:)=NaN;	% ? nog bepalen van werkelijke op- en onder-gaanpunten?				l=line(X(:,1),X(:,2),X(:,3),'color',[1 1 0],'Tag','zonnebaan'	...					,'buttondownfcn','zonnewijzer zbd'	...					,'UserData',p	...					);				set(gcf,'name',sprintf('3D-zonnewijzer - %s',Dstring(ZW.Pset.D(p,:))))			else				error('Deze input bij plot3d is niet gekend')			end		end		axis equal	case 'togvov'		f1=gcf;		if ~strcmp(get(f1,'Tag'),'zonnewijzerUIinput')			error('Dit intern gebruik werkt enkel met het juiste type current figure')		end		P=get(f1,'UserData');		bOV=get(P.hbOrVlakV,'Value');		v3v=get(P.hOrVlak(3),'Visible');		if bOV==strcmp(v3v,'on')			error('??Verkeerd gebruik van zonnewijzer togVOV??')		end		[vOr,bOr]=getuidata(P.hOrVlak,~bOV);		if bOV			p=cat(2,vOr{1:2});			for i=1:2				if bOr(i)					p(i)=p(i)*pi/180;				end			end			X=[-sin(p(2))*sin(p(1)) cos(p(2))*sin(p(1)) cos(p(1))];			set(P.hOrVlak(1),'Value',[],'String',num2str(X(1)))			set(P.hOrVlak(2),'Value',[],'String',num2str(X(2)))			set(P.hOrVlak(3),'Visible','on'	...				,'Value',[],'String',num2str(X(3))	...				)		else			p=cat(2,vOr{:});			if all(p==0)				errordlg('Vector voor orientatie kan niet volledig nul zijn!!')				p=[0 0 1];			else				p=p/sqrt(p*p');			end			p1=acos(p(3));			p2=atan2(-p(1),p(2));			set(P.hOrVlak(1),'Value',[],'String',num2str(p1*180/pi))			set(P.hOrVlak(2),'Value',[],'String',num2str(p2*180/pi))			set(P.hOrVlak(3),'Visible','off')		end	case 'togvos'		f1=gcf;		if ~strcmp(get(f1,'Tag'),'zonnewijzerUIinput')			error('Dit intern gebruik werkt enkel met het juiste type current figure')		end		P=get(f1,'UserData');		bOV=get(P.hbPtVlakV,'Value');		v3v=get(P.hPtVlak(3),'Visible');		if bOV==strcmp(v3v,'on')			error('??Verkeerd gebruik van zonnewijzer togVOV??')		end		[vOr,bOr]=getuidata(P.hPtVlak,~bOV);		if bOV			p=cat(2,vOr{1:2});			for i=1:2				if bOr(i)					p(i)=p(i)*pi/180;				end			end			X=[-sin(p(2))*sin(p(1)) cos(p(2))*sin(p(1)) cos(p(1))];			set(P.hPtVlak(1),'Value',[],'String',num2str(X(1)))			set(P.hPtVlak(2),'Value',[],'String',num2str(X(2)))			set(P.hPtVlak(3),'Visible','on'	...				,'Value',[],'String',num2str(X(3))	...				)		else			p=cat(2,vOr{:});			if all(p==0)				errordlg('Vector voor orientatie kan niet volledig nul zijn!!')				p=[0 0 1];			else				p=p/sqrt(p*p');			end			p1=acos(p(3));			p2=atan2(-p(1),p(2));			set(P.hPtVlak(1),'Value',[],'String',num2str(p1*180/pi))			set(P.hPtVlak(2),'Value',[],'String',num2str(p2*180/pi))			set(P.hPtVlak(3),'Visible','off')		end	case 'geogcoor'		f1=gcf;		if ~strcmp(get(f1,'Tag'),'zonnewijzerUIinput')			errordlg('Verkeerd gebruik van zonnewijzer UI-functies','zonnewijzer-fout')			return		end		D=get(f1,'UserData');		i=get(D.hGeog,'Value');		s=get(D.hGeog,'UserData');		p=geogcoor(s{i});		set(D.hOLNB(1),'Value',[],'String',p(1)*180/pi);		set(D.hOLNB(2),'Value',[],'String',p(2)*180/pi);	case 'editted'		set(gcbo,'Value',[])	case 'plotlim'		if isempty(f)			errordlg('Update is niet mogelijk als geen venster bestaat - start met zonnewijzer')			return		end		ZW=get(f,'UserData');		l=line(ZW.S.limprojvlak([1 2 2 1 1]),ZW.S.limprojvlak([3 3 4 4 3]));		if nargout			Pproj=l;		end	case 'calcorspiegel'		% parameters : eerste : moment, tweede : projectiepunt		if isempty(f)			errordlg('Berekeningen zijn niet mogelijk als geen venster bestaat - start met zonnewijzer')			return		end		ZW=get(f,'UserData');		if ~ZW.S.bSpiegel			errordlg('Orientatie van spiegel kan enkel bepaald worden als een spiegel gebruikt wordt.')			return		end		Pzon=calcposhemel(ZW.S.geog,p,ZW.Pset.lichaam);		Xwens=Pset-ZW.S.pospunt;		Xwens=Xwens/sqrt(Xwens*Xwens');		Pzon(1)=Pzon(1)+ZW.S.zuiden;		Xzon=[sin(Pzon(1))*cos(Pzon(2)) cos(Pzon(1))*cos(Pzon(2)) sin(Pzon(2))];		Xspiegel=(Xzon+Xwens)/2;		Xspiegel=Xspiegel/sqrt(Xspiegel*Xspiegel');		Pproj=Xspiegel;	case 'get3dproj'		Pproj=get3Dprojs(f);	case 'getdefpset'		Pproj=GetDefPset;	otherwise		errordlg('Verkeerd gebruik van zonnewijzer','Zonnewijzer-fout')	end	returnendpcor=p(1)+S.zuiden;Xrich=0;Pproj3D=0;Pproj=0;alfa=0;XD=0;if p(2)<0	bOK=0;else	bOK=1;	Xrich=[sin(pcor)*cos(p(2)) cos(pcor)*cos(p(2)) sin(p(2))];	if S.bSpiegel		Xdir=Xrich*S.Vorpunt';		if Xdir<=0			bOK=0;		else			Xl=cross(Xrich,S.Vorpunt);			if Xl*Xl'<1e-14				Xrich=-Xrich;	% Loodrecht invallende straal			else				c=Xrich+2*cross(Xl,S.Vorpunt);				Xrich=-c;			end		end	end	if bOK		XD=(S.Rprojvlak(3,:)*Xrich');		if p(2)<=0	% geen zon te zien			alfa=0;		elseif XD>1e-10			alfa=(S.avlak-S.Rprojvlak(3,:)*S.pospunt')/XD;		elseif XD<-1e-10			alfa=0;		elseif XD==0			warning('Straal loopt evenwijdig met projectievlak')			alfa=0;		else			warning('Straal loopt bijna evenwijdig met projectievlak')			alfa=0;		end		% teken alfa bepaalt "juiste richting"		Pproj3D=S.pospunt+Xrich*alfa;		Pproj=(S.Rprojvlak*(Pproj3D-S.posvlak)')';		if abs(Pproj(3))>1e-5			%warning('!!!projectiepunt ligt niet in projectievlak!!!')		else			Pproj(3)=[];		end	endendif nargout>1	Suit=struct('pcor',pcor,'Xrich',Xrich	...		,'XD',XD,'alfa',alfa	...		,'Pproj3D',Pproj3D	...		);endfunction ZW=CalcPos(ZW)S=ZW.S;Pset=ZW.Pset;h=Pset.h;D=Pset.D;Lim=S.limprojvlak;ZW.P1=zeros(length(h),size(D,1),2);ZW.JD=zeros(length(h),size(D,1));for ih=1:length(h)	h1=h(ih);	for iD=1:size(D,1);		ZW.JD(ih,iD)=calcjd(D(iD,:))+h1/24;		ZW.P1(ih,iD,1:2)=calcposhemel(S.geog,ZW.JD(ih,iD),ZW.Pset.lichaam);	end;endfunction ZW=CalcProj(ZW)S=ZW.S;Pset=ZW.Pset;h=Pset.h;D=Pset.D;Lim=S.limprojvlak;P2_3D=zeros(length(h),size(D,1),3);P2=zeros(length(h),size(D,1),3);for ih=1:length(h)	h1=h(ih);	for iD=1:size(D,1);		[p,Su]=zonnewijzer(S,squeeze(ZW.P1(ih,iD,:)));		if length(p)~=2			P2(ih,iD,3)=-1;		else			P2_3D(ih,iD,:)=Su.Pproj3D;			P2(ih,iD,1:2)=p(1:2);			P2(ih,iD,3)=p(1)>=Lim(1)&p(1)<=Lim(2)	...				&p(2)>=Lim(3)&p(2)<=Lim(4);		end	end;endZW.P2_3D=P2_3D;ZW.P2=P2;function f=maakuifigfWijzer=findobj('Tag','zonnewijzerFigure');if isempty(fWijzer)	zonnewijzer	fWijzer=findobj('Tag','zonnewijzerFigure');	if isempty(fWijzer)		error('Er loopt iets ernstig fout!!')	endendf=findobj('Tag','zonnewijzerUIinput');if ~isempty(f)	figure(f)	returnelse	f=nfigure;	set(f,'Tag','zonnewijzerUIinput','Name','Zonnerwijzer instellingen'	...		,'NumberTitle','off','Resize','off'	...		,'Position',[100 100 360 320]);endx0=10;y0=310;x=x0;y=y0;b1=80;b2=45;db=5;uicontrol('Position',[x+240 y-20 100 20],'String','Update'	...	,'Callback','zonnewijzer update','Tag','ZWupdateButton');uicontrol('Position',[x y-17 120 13],'String','geografische positie:'	...	,'HorizontalAlignment','left'	...	,'Style','text');s=geogcoor;s=s([1 1:end]);s{1}=' ';hGeog=uicontrol('Position',[x,y-45,110,20],'String',strvcat(s)	...	,'Style','popupmenu'	...	,'Callback','zonnewijzer geogcoor'	...	,'Tag','plaatsnamen'	...	,'UserData',s	...	);hNB=uicontrol('Position',[x+120 y-20 b1 20],'Style','edit','Tag','geogNB'	...	,'TooltipString','Geef graden noorderbreedte in (bijv. 50.862).'	...	,'Callback','zonnewijzer editted'	...	);hOL=uicontrol('Position',[x+120 y-45 b1 20],'Style','edit','Tag','geogOL'	...	,'TooltipString','Geef graden oorsterlengte in (bijv. 5.2717).'	...	,'Callback','zonnewijzer editted'	...	);uicontrol('Position',[x+120+b1+db y-17 30 13],'Style','text','String','NB'	...	,'HorizontalAlignment','left'	...	)uicontrol('Position',[x+120+b1+db y-42 30 13],'Style','text','String','OL'	...	,'HorizontalAlignment','left'	...	)% direct onder geog pos string : popmenu (of listbox)y=y-50;uicontrol('Position',[x y-17 120 13],'String','orientatie tov zuiden:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hZuiden=uicontrol('Position',[x+120 y-20 b1 20],'Style','edit','Tag','zuiden'	...	,'TooltipString','Geef de hoek tussen het geografische zuiden en het gebruikte coordinatenstelsel.'	...	,'Callback','zonnewijzer editted'	...	);uicontrol('Position',[x+120+b1+db y-17 40 13],'Style','text','String','graden'	...	)y=y-25;uicontrol('Position',[x y-17 120 13],'String','positie stralenpunt:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hPX=uicontrol('Position',[x+120 y-20 b2 20],'Style','edit','Tag','puntX'	...	,'Callback','zonnewijzer editted'	...	);hPY=uicontrol('Position',[x+120+b2+db y-20 b2 20],'Style','edit','Tag','puntY'	...	,'Callback','zonnewijzer editted'	...	);hPZ=uicontrol('Position',[x+120+2*(b2+db) y-20 b2 20],'Style','edit','Tag','puntZ'	...	,'Callback','zonnewijzer editted'	...	);y=y-21;hSpiegel=uicontrol('Position',[x y-17 57 13],'Style','checkbox'	...	,'String','spiegel'	...	,'Tag','bSpiegel'	...	);hPtVbV=uicontrol('Position',[x+60 y-17 57 13],'Style','checkbox'	...	,'String','vector'	...	,'Tag','bSpiegelVector'	...	,'CallBack','zonnewijzer togVOS'	...	);hPtVX=uicontrol('Position',[x+120 y-20 b2 20],'Style','edit','Tag','orPtX'	...	,'Callback','zonnewijzer editted'	...	);hPtVY=uicontrol('Position',[x+120+b2+db y-20 b2 20],'Style','edit','Tag','orPtY'	...	,'Callback','zonnewijzer editted'	...	);hPtVZ=uicontrol('Position',[x+120+2*(b2+db) y-20 b2 20],'Style','edit','Tag','orPtZ'	...	,'Callback','zonnewijzer editted'	...	);	y=y-30;uicontrol('Position',[x y-17 120 13],'String','pos. punt op proj.vlak:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hPpX=uicontrol('Position',[x+120 y-20 b2 20],'Style','edit','Tag','puntPX'	...	,'Callback','zonnewijzer editted'	...	);hPpY=uicontrol('Position',[x+120+b2+db y-20 b2 20],'Style','edit','Tag','puntPY'	...	,'Callback','zonnewijzer editted'	...	);hPpZ=uicontrol('Position',[x+120+2*(b2+db) y-20 b2 20],'Style','edit','Tag','puntPZ'	...	,'Callback','zonnewijzer editted'	...	);y=y-25;uicontrol('Position',[x y-17 100 13],'String','orientatie vlak:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hOrVbV=uicontrol('Position',[x+105 y-17 125 13],'Style','checkbox'	...	,'String','op basis van vector'	...	,'Tag','bVlakVector'	...	,'CallBack','zonnewijzer togVOV'	...	);hOrVX=uicontrol('Position',[x+120 y-40 b2 20],'Style','edit','Tag','orVlakX'	...	,'Callback','zonnewijzer editted'	...	);hOrVY=uicontrol('Position',[x+120+b2+db y-40 b2 20],'Style','edit','Tag','orVlakY'	...	,'Callback','zonnewijzer editted'	...	);hOrVZ=uicontrol('Position',[x+120+2*(b2+db) y-40 b2 20],'Style','edit','Tag','orVlakZ'	...	,'Callback','zonnewijzer editted'	...	);y=y-50;uicontrol('Position',[x y-17 100 13],'String','rotatie vlak:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hRotProj=uicontrol('Position',[x+120 y-20 b1 20],'Style','edit','Tag','rotProj'	...	,'Callback','zonnewijzer editted'	...	);y=y-25;uicontrol('Position',[x y-17 70 13],'String','grenzen:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hLimX1=uicontrol('Position',[x+80 y-20 b2 20],'Style','edit','Tag','limX1'	...	,'Callback','zonnewijzer editted'	...	);hLimX2=uicontrol('Position',[x+80+b2+db y-20 b2 20],'Style','edit','Tag','limX2'	...	,'Callback','zonnewijzer editted'	...	);hLimY1=uicontrol('Position',[x+80+2*(b2+db) y-20 b2 20],'Style','edit','Tag','limY1'	...	,'Callback','zonnewijzer editted'	...	);hLimY2=uicontrol('Position',[x+80+3*(b2+db) y-20 b2 20],'Style','edit','Tag','limY2'	...	,'Callback','zonnewijzer editted'	...	);y=y-25;uicontrol('Position',[x y-17 70 13],'String','dagen:'	...	,'HorizontalAlignment','left'	...	,'Style','text');hDagen=uicontrol('Position',[x+80 y-50 220 50],'Style','edit','Tag','dagen'	...	,'Callback','zonnewijzer editted'	...	,'HorizontalAlignment','left'	...	,'Max',5	...	);y=y-55;	% voor verdere input%fprintf('y=%d\n',y)	% hulplijn tijdens opbouwenP=struct('fWijzer',fWijzer	...	,'hGeog',hGeog	...	,'hOLNB',[hOL hNB]	...	,'hZuiden',hZuiden	...	,'hPuntCoor',[hPX hPY hPZ]	...	,'hSpiegel',hSpiegel	...	,'hbPtVlakV',hPtVbV	...	,'hPtVlak',[hPtVX hPtVY hPtVZ]	...	,'hPuntProj',[hPpX hPpY hPpZ]	...	,'hbOrVlakV',hOrVbV	...	,'hOrVlak',[hOrVX hOrVY hOrVZ]	...	,'hRotProj',hRotProj	...	,'hLimProj',[hLimX1 hLimX2 hLimY1 hLimY2]	...	,'hDagen',hDagen	...	);set(f,'UserData',P);function updateuifigglobal ZWUIconvfConv={'hOLNB','geog',180/pi,0;	...	'hZuiden','zuiden',180/pi,0;	...	'hPuntCoor','pospunt',1,0;	...		'hPtVlak','orpunt',180/pi,1;	...	'hPuntProj','posvlak',1,0;	...	'hOrVlak','orvlak',180/pi,1;	...	'hRotProj','rotprojectie',180/pi,0;	...	'hLimProj','limprojvlak',1,0;	...	'hDagen','D',1,2	...	};ZWUIconv=fConv;if strcmp(get(gcf,'Tag'),'zonnewijzerUIinput')	fUI=gcf;else	fUI=findobj('Tag','zonnewijzerUIinput');	if isempty(fUI)		fUI=zonnewijzer('maakuiinput');	elseif length(fUI)>1		warning('Werken met meerdere uiinputs is nog niet klaar!!')		fUI=fUI(1);	endendP=get(fUI,'UserData');f=findobj('Tag','zonnewijzerFigure');if isempty(f)	zonnewijzerendZW=get(f,'UserData');set(P.hSpiegel,'Value',ZW.S.bSpiegel,'UserData',ZW.S.bSpiegel);for i=1:size(fConv,1)	h=getfield(P,fConv{i,1});	if isfield(ZW.S,fConv{i,2})		d=getfield(ZW.S,fConv{i,2});	else		d=getfield(ZW.Pset,fConv{i,2});	end	fC=fConv{i,3};	bString=0;	if fConv{i,4}		% speciaal		switch fConv{i,1}		case 'hOrVlak'			if length(d)==2				set(h(3),'Visible','off')				set(P.hbOrVlakV,'Value',0)			else				set(h(3),'Visible','on')				set(P.hbOrVlakV,'Value',1)				fC=1;			end		case 'hPtVlak'			if length(d)==2				set(h(3),'Visible','off')				set(P.hbPtVlakV,'Value',0)			else				set(h(3),'Visible','on')				set(P.hbPtVlakV,'Value',1)				fC=1;			end		case 'hDagen'			bString=1;			dNu=clock;			if isempty(d)				sd='';			elseif all(d(:,3)==dNu(1))				sd=sprintf('%d-%d,',d(:,1:2)');			else				sd=sprintf('%d-%d-%d,',d');			end			if ~isempty(sd)				sd(end)='';			end			vd=1;		otherwise			error('Error in updateuifig')		end	end	bDeg=abs(fC-180/pi)<1e-10;	if bDeg		for j=1:length(d)			[nDeg,nMin,nSec]=rad2degS(d(j));			set(h(j),'String',sprintf('%d�%02d''%05.2f"',nDeg,nMin,nSec),'Value',d(j))		end	elseif bString		for j=1:length(h)			set(h(j),'String',sd(j,:))			set(h(j),'Value',vd(j))		end	else		for j=1:length(d)			set(h(j),'String',num2str(d(j)*fC),'Value',d(j))		end	endendfunction [D,bD]=getuidata(h,iSoort)% GETUIDATA - Leest data uit edit boxescNum=zeros(1,255);cNum(abs('0123456789+-eE.'))=1;D=cell(size(h));bD=logical(zeros(size(h)));for i=1:numel(h)	v=get(h(i),'Value');	b=0;	if isempty(v)		%!!meer testen??		sv=get(h(i),'String');		if iSoort==1	% graden			j=find(~cNum(abs(sv)));			if isempty(j)				v=str2num(sv);			else				sv(j)=' ';				vv=sscanf(sv,'%g');				if length(vv)<1					errordlg(sprintf('kan getal "%s" niet interpreteren',sv)	...						,'zonnewijzer-fout');				elseif length(vv)>3					warndlg(sprintf('"%s" geeft teveel getallen!!??',sv)	...						,'zonnewijzer-melding')					vv=vvv(1:3);				end				f=1;				v=vv(1);				for j=2:length(vv)					f=f/60;					v=v+vv(j)*f;				end			end		elseif iSoort==2	% string			v=sv;		else			v=str2num(sv);		end		if isempty(v)			v=sscanf(sv,'%g');			if isempty(v)				v=0;				errordlg(sprintf('kan getal "%s" niet interpreteren',sv),'zonnewijzer-fout')			elseif length(v)>1				warndlg(sprintf('"%s" geeft meerdere getallen!!??',sv),'zonnewijzer-melding')				v=v(1);			end		end		b=1;	end	D{i}=v;	bD(i)=b;endfunction p=leesuis% LEESUIS - Leest waarden in UI-fig voor wijzigingen instellingenglobal ZWUIconvfConv=ZWUIconv;p={};if strcmp(get(gcf,'Tag'),'zonnewijzerUIinput')	fUI=gcf;else	fUI=findobj('Tag','zonnewijzerUIinput');	if isempty(fUI)		%error('UIs kunnen enkel gelezen worden als het geschikte venster bestaat!!!')		return	endendP=get(fUI,'UserData');bS=get(P.hSpiegel,'Value');if bS~=get(P.hSpiegel,'UserData')	p{1,end+1}='spiegel';	p{1,end+1}=bS;endfor iCon=1:size(fConv,1)	Dver=0;	if fConv{iCon,4}>1		iSoort=fConv{iCon,4};	else		iSoort=abs(fConv{iCon,3}-180/pi)<1e-10;	end	[D,bD]=getuidata(getfield(P,fConv{iCon,1}),iSoort);	if fConv{iCon,4}		switch fConv{iCon}		case 'hPtVlak'			b=get(P.hbPtVlakV,'Value');			if b				Dver=any(bD);				dD=cat(2,D{:});			else				Dver=any(bD(1:2));				dD=cat(2,D{1:2});				dD(bD(1:2))=dD(bD(1:2))/fConv{iCon,3};			end		case 'hOrVlak'			b=get(P.hbOrVlakV,'Value');			if b				Dver=any(bD);				dD=cat(2,D{:});			else				Dver=any(bD(1:2));				dD=cat(2,D{1:2});				dD(bD(1:2))=dD(bD(1:2))/fConv{iCon,3};			end		case 'hDagen'			Dver=bD;			if bD				D=D{1};				if isempty(D)					dD=clock;					dD=dD(3:-1:1);				else					[dD,dErr]=InterpreteData(D);					if ~isempty(dErr)						dErr=sprintf('%s,',dErr{:});						warndlg(sprintf('"%s" is geen juist datum-formaat',dErr(1:end-1)),'zonnewijzer-waarschuwing')					end				end			end		otherwise			error('Fout verloop in functie leesuis!')		end	else		dD=cat(2,D{:});		for j=1:length(D)			if bD(j)				Dver=1;				dD(j)=dD(j)/fConv{iCon,3};			end		end	% for	end	% if fConv - else	if Dver		p{1,end+1}=fConv{iCon,2};		p{1,end+1}=dD;	endendfunction X3D=calc3Dproj(X2D)if size(X2D,1)==2	X2D(3,1)=0;endX3D=ZW.S.Rprojvlak'*X2D;function lijnen=get3Dprojs(f)if isempty(f)	errordlg('Ik kan geen 3D-bepaling doen zonder 2D-venster')	returnendZW=get(f,'UserData');R=ZW.S.Rprojvlak';l=findobj(f,'Tag','ZWlijn');lijnen=struct('h',num2cell(l)	...	,'x2D',[],'y2D',[],'z2D',[]	...	,'X',[],'Y',[],'Z',[]	...	,'Color',[],'LineStyle',[],'Marker',[]	...	,'LineWidth',[],'MarkerSize',[]	...	,'MarkerEdgeColor',[],'MarkerFaceColor',[]	...	);for i=1:length(l)	x=get(l(i),'XData');	y=get(l(i),'YData');	z=get(l(i),'ZData');	if isempty(z)		z=x*0;	end	X=R*[x;y;z]+ZW.S.posvlak(ones(length(x),1),:)';	lijnen(i).x2D=x;	lijnen(i).y2D=y;	lijnen(i).z2D=z;	lijnen(i).X=X(1,:);	lijnen(i).Y=X(2,:);	lijnen(i).Z=X(3,:);	lijnen(i).Color=get(l(i),'Color');	lijnen(i).LineStyle=get(l(i),'LineStyle');	lijnen(i).Marker=get(l(i),'Marker');	lijnen(i).LineWidth=get(l(i),'LineWidth');	lijnen(i).MarkerSize=get(l(i),'MarkerSize');	lijnen(i).MarkerEdgeColor=get(l(i),'MarkerEdgeColor');	lijnen(i).MarkerFaceColor=get(l(i),'MarkerFaceColor');endfunction Pset=GetDefPseth=[4:0.2:21];Nh=max(1,round(1/mean(diff(h))));H12=[12 13];i12=H12;for i=1:length(H12)	[mn,i12(i)]=min(abs(h-H12(i)));end%D=[21 3 2006;21 6 2006;21 9 2006;21 12 2006];D=[21+zeros(12,1) (1:12)' 2006+zeros(12,1)];Pset=struct('h',h,'Nh',Nh	...	,'H12',H12,'i12',i12	...	,'D',D	...	,'lichaam','zon'	...	);function s=Dstring(d)if length(d)>3	if length(d)>4		if length(d)>5			s=sprintf('%2d-%02d-%04d %d:%02d:%02.0f',d);		else			s=sprintf('%2d-%02d-%04d %d:%02.0f',d);		end	else		s=sprintf('%2d-%02d-%04d %gh',d);	endelseif d(1)==round(d(1))	s=sprintf('%2d-%02d-%04d',d(1:3));else	s=sprintf('%5.2f-%02d-%04d',d(1:3));endfunction [D,errs]=InterpreteData(l)l(l=='/')='-';Idat=[0 find(l==',') length(l)+1];D=zeros(length(Idat)-1,6);errs={};for i=1:length(Idat)-1	[d,n,lerr,Inxt]=sscanf(l(Idat(i)+1:Idat(i+1)-1),'%d-%d-%d %d:%d:%g',[1 6]);	if n<2		%error('Verkeerde tekst input voor dagen')		d(3)=0;		errs{end+1}='l(Idat(i)+1:Idat(i+1)-1)';	elseif n<3		d0=clock;		d(3)=d0(1);	elseif d(3)<100		d(3)=d(3)+2000;	end	D(i,1:length(d))=d;end