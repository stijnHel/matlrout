function cansigui(varargin)
% CANSIGUI - CAN-signal user-interface
%    cansigui - Maakt UI
%       of cansigui(opt_1,...) met opt_x
%          'sort'    - sorteert de signalen
%          'sortmsg' - sorteerd signalen binnen boodschap
%          'msgext'  - CAN-msg als extensie
%          'msgpre'  - CAN-msg als voorzetsel
%    cansigui('remove') - verwijdert geselecteerde elementen
%    cansigui('hold')   - behoudt geselecteerde elementen
%    cansigui('selall') - selecteert alle
%    cansigui('delall') - deselecteerd alle
%    cansigui('repeat') - herhaal laatste
%    cansigui('last')   - geeft laatste instructie
%    cansigui('sellast')- selecteer zoals laatste instelling

global CANSIGlast CANSIGnlijn

if isempty(CANSIGnlijn)
	CANSIGnlijn=8;
end

doeinit=0;
sortSig=0;
msgAdd=0;
if nargin==0
	doeinit=1;
else
	for i=1:length(varargin)
		switch varargin{i}
		case 'sort'
			sortSig=1;
			doeinit=1;
		case 'sortmsg'
			sortSig=2;
			doeinit=1;
		case 'msgext'
			msgAdd=2;
			doeinit=1;
		case 'msgpre'
			msgAdd=1;
			doeinit=1;
		end
	end
end

f=findobj('Type','figure','Tag','CANsigGUI');
hermaak=0;
if doeinit
	ids=canmsgs;
	if isempty(ids)
		error('!!!!geen boodschappen!!!!')
	end
	if sortSig==2
		for i=1:size(ids,1)
			[ss,j]=sort({ids{i,3}.signal});
			ids{i,3}=ids{i,3}(j);
		end
	end
	sigs=cat(2,ids{:,3});
	if isempty(sigs)
		error('!!!!geen signalen!!!!')
	end
	if msgAdd
		ssigs=cell(size(sigs));
		k=0;
		for i=1:length(ids)
			for j=1:length(ids{i,3})
				k=k+1;
				if msgAdd==1
					ssigs{k}=[ids{i,2} '_' ids{i,3}(j).signal];
				elseif msgAdd==2
					ssigs{k}=[ids{i,3}(j).signal '_' ids{i,2}];
				end
			end
		end
	else
		ssigs={sigs.signal};
	end
	i=1;
	while i<length(sigs)
		j=strmatch(ssigs{i},ssigs(i+1:end));
		if ~isempty(j)
			ssigs(i+j)=[];
			sigs(i+j)=[];
		end
		i=i+1;
	end
	if sortSig==1
		[ssigs,i]=sort(ssigs);
		sigs=sigs(i);
	end
	if ~isempty(f)
		close(f)
	end
	f=figure('MenuBar','none','Tag','CANsigGUI'	...
		,'Name','CAN-signaal-selectie-venster'	...
		,'NumberTitle','off');
	dx=130;
	Dx=dx+5;
	Dy=18;
	dy=15;
	S=get(0,'ScreenSize');
	x0=10;
	y0=35;
	ymax=S(4)-80;
	y1=30;
	y1max=ymax-y1;
	h1=uicontrol('String','Verwijder'	...
		,'Position',[5,5,80,20]	...
		,'Callback','cansigui(''remove'')'	...
		,'TooltipString','Verwijder alle geselecteerde items uit CAN-gegevens'	...
		);
	h2=uicontrol('String','Behoud'	...
		,'Position',[95,5,80,20]	...
		,'Callback','cansigui(''hold'')'	...
		,'TooltipString','Verwijder alle niet geselecteerde items uit CAN-gegevens'	...
		);
	h3=uicontrol('String','Sel. alle'	...
		,'Position',[185,5,80,20]	...
		,'Callback','cansigui(''selall'')'	...
		,'TooltipString','Selecteer alle'	...
		);
	h4=uicontrol('String','Decel. alle'	...
		,'Position',[275,5,80,20]	...
		,'Callback','cansigui(''delall'')'	...
		,'TooltipString','Deselecteer alle'	...
		);
	xmin=365;
	if ~isempty(CANSIGlast)
		h5=uicontrol('String','Herhaal laatste'	...
			,'Position',[365,5,80,20]	...
			,'Callback','cansigui(''repeat'')'	...
			,'TooltipString','Herhaal laatste instelling'	...
			);
		h6=uicontrol('String','Sel. laatste'	...
			,'Position',[455,5,80,20]	...
			,'Callback','cansigui(''sellast'')'	...
			,'TooltipString','Selecteer zoals laatste instelling'	...
			);
		xmin=545;
	end
	nSigs=length(sigs);
	minKol=floor((xmin-10)/Dx);
	n=min([nSigs,floor((y1max-y0)/Dy),ceil(nSigs/minKol)]);
	nKol=ceil(nSigs/n);
	n=ceil(nSigs/nKol);
	hBut=zeros(1,length(sigs));
	k=0;
	x=5;
	y=y0+n*Dy;
	for i=1:length(sigs)
		y=y-Dy;
		if y<y0
			y=y0+(n-1)*Dy;
			x=x+Dx;
		end
		hBut(i)=uicontrol('String',ssigs{i}	...
			,'Position',[x,y,dx,dy]	...
			,'Style','checkbox'	...
			,'Tag',sigs(i).signal	...
			);
	end
	Dx=min(max(x+Dx,xmin),S(3));
	p=[5,30,Dx,y0+n*Dy];
	set(f,'Position',p)
	setappdata(f,'hBut',hBut)
	setappdata(f,'sort',sortSig)
	setappdata(f,'msgAdd',msgAdd)
else
	sortSig=getappdata(f,'sort');
	msgAdd=getappdata(f,'msgAdd');
	if isempty(f)
		error('CAN-selectie-figuur niet gevonden')
	end
	hBut=getappdata(f,'hBut');
	if isempty(hBut)
		error('Niet de juiste figuurdata-gevonden')
	end
	switch varargin{1}
	case 'remove'
		CANSIGlast=getsel(hBut,0);
		hermaak=1;
	case 'hold'
		CANSIGlast=getsel(hBut,1);
		hermaak=1;
	case 'selall'
		set(hBut,'Value',1);
	case 'delall'
		set(hBut,'Value',0);
	case 'repeat'
		if isempty(CANSIGlast)
			error('Geen actie beschikbaar')
		end
		hermaak=1;
	case 'last'
		if isempty(CANSIGlast)
			error('Geen actie beschikbaar')
		end
		fprintf('canmsgs(''limit'',{')
		j=1;
		for i=1:length(CANSIGlast)
			j=j+1;
			if j>CANSIGnlijn
				fprintf('\t...\n       ')
				j=0;
			end
			if i>1
				fprintf(',');
			end
			fprintf('''%s''',CANSIGlast{i})
		end
		fprintf('})\n');
	case 'sellast'
		for i=1:length(hBut)
			set(hBut(i),'Value',	...
				~isempty(strmatch(get(hBut(i),'Tag'),CANSIGlast)))
		end
	end
end

if hermaak
	canmsgs('limit',CANSIGlast)
	cin={};
	if sortSig==1
		cin={'sort'};
	elseif sortSig==2
		cin={'sortmsg'};
	end
	if msgAdd==1
		cin{end+1}='msgpre';
	elseif msgAdd==2
		cin{end+1}='msgex';
	end
	cansigui(cin{:})
end

function sel=getsel(hBut,activesel)
sel={};
for i=1:length(hBut)
	if get(hBut(i),'Value')==activesel
		sel{end+1}=get(hBut(i),'Tag');
	end
end
