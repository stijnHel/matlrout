function plot1vanreeks(func,fn,reeks,f1,Yind)
% PLOT1VANREEKS - Plot 1 file van een reeks voor snelle opvolging
%    plot1vanreeks(func,fn,reeks,f1)
%        funct : functie op te roepen om file te lezen
%        fn : van de vorm '<begin>%d<einde>'
%        reeks : lijst van te lezen files
%                als leeg worden alle files van het juiste formaat bepaald
%                           (of getracht)
%                als lengte 1, is het gelijkaardig, alleen worden de files
%                           gezocht

bReload=0;
switch func
	case 'next'
		S=getappdata(gcf,'reeksplot');
		i=S.i+1;
		if i>length(S.reeks)
			i=1;
		end
		S.i=i;
		setappdata(gcf,'reeksplot',S);
		bReload=1;
	case 'previous'
		S=getappdata(gcf,'reeksplot');
		i=S.i-1;
		if i<1
			i=length(S.reeks);
		end
		S.i=i;
		setappdata(gcf,'reeksplot',S);
		bReload=1;
	otherwise
		if length(reeks)<2
			i=find(fn=='%');
			if length(i)~=1||i==length(fn)||fn(i+1)~='d'
				error('Verkeerd gebruik van plot1vanreeks')
			end
			fn1=[fn(1:i-1) '*' fn(i+2:end)];
			if length(reeks)
				fn1=zetev([],fn1);
			end
			d=dir(fn1);
			D=strvcat(d.name);
			D=D(:,i:end);
			reeks=zeros(1,size(D,1));
			for i=1:length(reeks)
				k=sscanf(D(i,:),'%d');
				if isempty(k)
					reeks(i)=-1;
				else
					reeks(i)=k;
				end
			end
			reeks(reeks<0)=[];
			if isempty(reeks)
				error('!!!Geen files gevonden!!!')
			end
			if length(reeks)==1
				warning('Reeks bestaat uit slechts 1 file!!!')
			else
				reeks=sort(reeks);
			end
		end
		if ~exist('f1','var')|isempty(f1)
			f1=reeks(1);
		end
		if ~exist('Yind','var')
			Yind=[];
		end
		if ~exist('Xind','var')
			Xind=1;
		end
		if ~exist('func','var')|isempty(func)
			func='leesalg';
		end

		if1=find(reeks==f1);
		if isempty(if1)
			error('Een file te lezen buiten de reeks??')
		end
		e=feval(func,sprintf(fn,f1));
		[ax,hL]=plotmat(e,Yind,Xind);
		lijnen=cat(1,hL{:});
		h=uicontrol('style','text','string',num2str(f1),'position',[0 0 100 14]);
		S=struct('fn',fn	...
			,'reeks',reeks	...
			,'i',if1	...
			,'func',func	...
			,'lijnen',lijnen	...
			,'Xind',Xind	...
			,'Yind',Yind	...
			,'nKanalen',size(e,2)	...
			,'hNum',h	...
			,'autoRange',1	...
			);
		setappdata(gcf,'reeksplot',S);
		navfig
		navfig('addkey','v',0,'plot1vanreeks next')
		navfig('addkey','V',0,'plot1vanreeks previous')
end
if bReload
	S=getappdata(gcf,'reeksplot');
	e=feval(S.func,sprintf(S.fn,S.reeks(S.i)));
	if size(e,2)~=S.nKanalen
		warning('Er is een ander aantal kanalen dan bij vorige file!!')
		S.nKanalen=size(e,2);
		setappdata(gcf,'reeksplot',S);
	end
	lijnen=S.lijnen;
	iX=S.Xind;
	iY=S.Yind';
	iY=iY(:);
	iY(iY==0)=[];
	if length(lijnen)~=length(iY)
		error('!!!!!Er loopt iets fout!!!!')
	end
	for i=1:length(iY)
		if iY(i)<=size(e,2)
			set(lijnen(i),'XData',e(:,iX),'YData',e(:,iY(i)))
		else
			set(lijnen(i),'XData',[],'YData',[])
		end
	end
	set(S.hNum,'String',sprintf('%d (%d/%d)',S.reeks(S.i),S.i,length(S.reeks)))
	if S.autoRange
		navfig X
	end
end
