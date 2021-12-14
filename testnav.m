function testnav(s,a1,a2)
% TESTNAV - verplaatst "view-gedeelte" van scherm
%    volgende toetsen :
%			4 : links (terug)
%			6 : rechts (verder)
%			9 : veel terug
%			3 : veel verder
%			7 : helemaal terug
%			1 : helemaal naar het einde
%			8 : inzoomen
%			2 : uitzoomen
%
%			+ : grafiek 2, 1 punt verder zetten
%			- : grafiek 2, 1 punt terug zetten
%			5 : begin van grafieken gelijk zetten

global lijnen
global assen lijnen ddx xmin xmax

if ~exist('s');s=[];end
if strcmp(s,'init')
	set(gcf,'keypressfcn','testnav','Interruptible','on');
	return
elseif strcmp(s,'plot') & nargin>2
	figure
	subplot(211)
	plot(0.2*(0:length(a1)-1),a1(:,1),0.2*(0:length(a2)-1),a2(:,1))
	grid
	title('motortoerentallen cyclus')
	xlabel('tijd')
	ylabel('[rpm]')
	subplot(212)
	subplot(212)
	plot(0.2*(0:length(a1)-1),a1(:,2),0.2*(0:length(a2)-1),a2(:,2))
	grid
	set(gca,'YDir','reverse')
	title('actuator-posities')
	xlabel('tijd [s]')
	bepfig(0,20)
	testnav('init')
	return
end
a=get(gcf,'CurrentCharacter');
x=get(gca,'XLim');
dx=diff(x);
if isempty(lijnen) | a==13
	assen=findobj(gcf,'Type','axes');
	lijnen=[];
	ddx=[];
	xmin=Inf;
	xmax=-Inf;
	for i=1:length(assen)
		l=[findobj(assen(i),'Type','line')' 0 0];
		lijnen=[lijnen;l(1:2)];
		for j=1:length(l)-2
			X=get(l(j),'XData');
			ddx=[ddx;X(2)-X(1)];
			xmin=min([xmin;X(:)]);
			xmax=max([xmax;X(:)]);
		end
	end
end
verpas=0;
verplijn=[];
if a=='4'
	x=x-dx/5;
	if x(1)<xmin
		x=x-(x(1)-xmin);
	end
	verpas=1;
elseif a=='6'
	x=x+dx/5;
	if x(2)>xmax
		x=x-(x(2)-xmax);
	end
	verpas=1;
elseif a=='9'
	x=x-dx;
	if x(1)<xmin
		x=x-(x(1)-xmin);
	end
	verpas=1;
elseif a=='3'
	x=x+dx;
	if x(2)>xmax
		x=x-(x(2)-xmax);
	end
	verpas=1;
elseif a=='7'
	x=x-x(1);
	verpas=1;
elseif a=='1'
	x=x+(xmax-x(2));
	verpas=1;
elseif a=='8'
	x=x-[-1 1]*dx/10;
	verpas=1;
elseif a=='2'
	x=x+[-1 1]*dx/6;
	if x(1)<xmin
		x=x-(x(1)-xmin);
	elseif x(2)>xmax
		x=x-(x(2)-xmax);
	end
	verpas=1;
elseif a=='+'
	verplijn=1;
elseif a=='-'
	verplijn=-1;
elseif a=='5'
	verplijn=0;
end
if verpas
	bepfig(x);
end
if ~isempty(verplijn)
	for i=1:size(lijnen,1)
		if lijnen(i,2)
			X=get(lijnen(i,2),'XData');
			if verplijn
				set(lijnen(i,2),'XData',X+ddx(1)*verplijn)
			else
				set(lijnen(i,2),'XData',X-X(1))
			end
		end
	end
end
