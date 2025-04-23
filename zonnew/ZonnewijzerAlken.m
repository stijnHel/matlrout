function Dout = ZonnewijzerAlken(varargin)
%ZonnewijzerAlken - Berekeningen en figuren van zonnewijzer
%        ZonnewijzerAlken()
%             Toont de zonnewijzer (na de berekeningen)

%!!!!!!!!!!!
%   "schijnbare vrijheid" over zonnewijzer-orientatie, maar nogal wat
%       delen rekenen op een horizontale!!!

%!!!!! zie zonnewijzer !!!!!

pos = geogcoor('Alken-Helsen');
lStijl = 0.75;	% lengte van de stijl (van voetpunt tot top)
uren = 6:18;	% UTC(!)
dagen = [21 4;
	21 5;
	21 6;
	21 7;
	21 8;
	];
Vzw = [0 0 1];	% Orientation of surface - vertical to sundial surface
			% ----> nog niet (echt) gebruikt!!!!!!
Pzw = [];		% points of sundial surface - if empty, default is used
Vstijl = [];	% vector of the "stijl" - if empty, based on pos
lBaseStijl = 0.25;	% length of base of "stijl-triangle" on sundial surface
[Zoffset] = [0 -0.05];	% offset of surface ((!)related to position of "stijl-punt" on surface)
dText = 0.6;	% 
[bOnlyInternalPoints] = true;
lSteun = 0.1;	% length of support of sundial
pSteun = 0.21;	% distance between support and "zero-point'
[bAnim] = true;	% enable animation (to navigate over time)
tStart = [];
[bCalcError] = false;	% calculate error between "real time" and "sundial time"

if nargin
	setoptions({'pos','lStijl','lBaseStijl','uren','dagen','Vzw','Pzw'	...
		,'bOnlyInternalPoints','Zoffset','lSteun','pSteun','bAnim'	...
		,'tStart','bCalcError'},varargin{:})
end
if isempty(Pzw)
	Pzw = [1150-420 1150 1150 0 0;0 0 1299 1299 1299-959]'/1000;
	%Pzw = -Pzw;
	Pzw = Pzw*[0 -1;1 0];
	Pzw(:,1) = Pzw(:,1)-(min(Pzw(:,1))+max(Pzw(:,1)))/2;
	Pzw(:,2) = Pzw(:,2)-min(Pzw(:,2));
	if ~isempty(Zoffset)
		Pzw = Pzw+Zoffset;
	end
end
if size(dagen,2)<3
	dagen(:,3) = 2024;
end

if isempty(Vstijl)
	a = pos(2);
	Vstijl = lStijl*[0,sin(a),cos(a)];
end

% Bepaling transformatie van oppervlak in 3D naar XY-vlak
%      ---> nog niet gebruikt!!!!!!!!!!!!!
%			---> beter gebruik maken van zonnewijzer!!!!!
Vzw = Vzw/sqrt(sum(Vzw.^2));
if max(abs(Vzw(1:2)))<1e-3	% horizontal
	T3Dto2D = eye(3);
else
	warning('Non-horizontal sundial is not foreseen!!')

end

% (nu (nog) horizontaal vlak, onafhankelijk van Vzw)
Pzw3D = [Pzw,zeros(size(Pzw,1),1)];

T = calcjd(dagen)'+uren(:)/24;

Pts = Vstijl.*[-1 -1 1];	% change axis: North-oriented --> south oriented
Csw = struct('surf',Pzw3D,'Pts',Pts);
P = CalcShadows(Csw,T(:));	% P: [3 x 1 x #time_instances] (1 for 1 point)
P = [-1;-1;1].*squeeze(P);	% back transformation for opposite horizonal orientation
P = reshape(P,3,length(uren),[]);	% P: [3 x #uren x #days]
mnP = mean(P,3);	% (?!!?) best choice to take the mean - with points possible "out of range" - and some zeros??
	% beter mean van genormeerde P
Binternal = false(length(uren),size(dagen,1));
Prnd = Pzw3D([1:end 1],:);
%!!!!! 3D-coordinaten zouden getransformeerd moeten worden naar een 2D
%   oppervlak - ipv Z te negeren
%          zolang horizontaal vlak - geeft dit geen probleem....
for i=1:numel(Binternal)
	Pi = (Prnd-P(:,i)')*[1;1i;0];	%!!!!horizontal!!!
	Binternal(i) = abs(sum(mod(diff(angle(Pi))+pi,2*pi)-pi))>1;	% niet echt veilig(!!) - of toch?
end
Vhours = zeros(length(uren),3);
PhourLines = zeros(length(uren),3);
for i=1:length(uren)
	p = mnP(:,i)/norm(mnP(:,i));
	Vhours(i,:) = p;
	PhourLines(i,:) = FindEdge(Prnd,p);
end
D = var2struct(pos,lStijl,Vstijl,Vzw,Pzw,Pzw3D,dagen,uren,mnP,P,Csw		...
	,Binternal,Vhours,PhourLines);
if bCalcError
	t0 = calcjd(0,1,dagen(1,3));
	T = t0+((0:366)+uren(:)/24);
	Pcheck = CalcShadows(Csw,T(:)).*[-1 -1 1];
	Pcheck = reshape(Pcheck,[3,size(T)]);
	Aall = squeeze(atan2(Pcheck(2,:,:),Pcheck(1,:,:)));
	Avector = atan2(Vhours(:,2),Vhours(:,1));
	Aerr = Aall-Avector;

	% Error in tijd
	%....(interp1(Dz.Avector,Dz.uren,Dz.Aall(:,180))'-Dz.uren)*60
	DTmin = nan(size(Aall));
	for i=1:size(DTmin,2)
		A = Aall(:,i);
		B = ~isnan(A);
		DTmin(B,i) = (interp1(Aall(B,i),uren(B),Avector(B))'-uren(B))*60;
	end

	D.Tcheck = T;
	D.Aall = Aall;
	D.Avector = Avector;
	D.Aerr = Aerr;
	D.DTmin = DTmin;
end

if nargout
	Dout = D;
end

fig = getmakefig('ZonnewijzerAlken_3D');
fig.UserData = D;
fig.ToolBar = 'figure';	% why is this needed to get the toolbar?
ii = [1:size(Pzw3D),1];
plot3(Pzw3D(ii,1),Pzw3D(ii,2),Pzw3D(ii,3))
Dsteun = [];
if isempty(lBaseStijl)
	line([0 Vstijl(1)],[0 Vstijl(2)],[0,Vstijl(3)]	...
		,'color',[0 0 0],'LineWidth',3 ...	
		,'Marker','o','MarkerSize',10,'MarkerFaceColor',[0 0 0] ...	
		,'MarkerIndices',uint64(2))
else
% 	line([0 0 Vstijl(1) 0],[0 lBaseStijl Vstijl(2) 0],[0 0 Vstijl(3) 0]		...
% 		,'color',[0 0 0],'LineWidth',3 ...	
% 		)
	patch([0 0 Vstijl(1) 0],[0 lBaseStijl Vstijl(2) 0],[0 0 Vstijl(3) 0]		...
		,[0 0 0],'LineWidth',2,'FaceAlpha',0.6 ...	
		)
	if ~isempty(lSteun)
		patch([0 lSteun 0 0],zeros(1,4)+pSteun,[0 0 lSteun 0],'k','LineWidth',2,'FaceAlpha',0.5)
		patch([0 -lSteun 0 0],zeros(1,4)+pSteun,[0 0 lSteun 0],'k','LineWidth',2,'FaceAlpha',0.5)
		Dsteun = var2struct(lSteun,pSteun);
		setappdata(fig,'Dsteun',Dsteun)
	end
end
if bOnlyInternalPoints
	line(P(1,Binternal),P(2,Binternal),P(3,Binternal),'Linestyle','none','marker','o','Color',[1 0 0])
else
	line(P(1,:),P(2,:),P(3,:),'Linestyle','none','marker','o','Color',[1 0 0])
end
for i=1:length(uren)
	p = Vhours(i,:)*dText;
	pEdge = PhourLines(i,:);
	line([0 pEdge(1)],[0 pEdge(2)],[0,pEdge(3)],'color',[0 0 0])
	line(p(1),p(2),p(3),'color',[0 0 0],'marker','.')
	if exist('num2roman','file')
		s = num2roman(rem(uren(i)+1,12)+1);
	else
		s = sprintf('%d (%d)',[1 2]+uren(i));
	end
	if p(1)<0
		opt = {'HorizontalAlignment','left','VerticalAlignment','bottom'};
	else
		opt = {'HorizontalAlignment','left','VerticalAlignment','top'};
	end
	text(p(1),p(2),p(3),s,opt{:})
end
view(2)
%axis([-1.1 1.2 -0.5 1.3])
axis equal
axis([min(Pzw3D(:,1)),max(Pzw3D(:,1)),min(Pzw3D(:,2)),max(Pzw3D(:,2))])
axis off
if bAnim
	hShadow = patch([0 0 0],[0 lBaseStijl Vstijl(2)],[0 0 0],[0 0 0.2]	...
		,'LineStyle','none'	...
		,'FaceAlpha',0.3);
	setappdata(fig,'hShadow',hShadow)
	if ~isempty(Dsteun)
		hSsteun = patch([-lSteun 0 lSteun],[0 0 0]+pSteun,[0 0 0],[0 0 0.2]	...
			,'LineStyle','none'	...
			,'FaceAlpha',0.3);
		setappdata(fig,'hSsteun',hSsteun)
	end
	if isempty(tStart)
		t = round(calcjd*1440)/1440;
	elseif isa(tStart,'datenum')
		t = juliandate(tStart);
	elseif length(tStart)>2
		t = calcjd(tStart);
	else
		t = calcjd(Tim2MLtime(tStart));
	end
	setappdata(fig,'tShadow',t)
	UpdateAnim(fig)
	fig.KeyPressFcn = @KeyPressed;
end
if bCalcError
	[~,bNew] = getmakefig('tijdvereffening');
	ii = 2:3:length(uren);
	plot(T(7,:),DTmin(ii,:));grid
	navfig
	if bNew
		navfig(char(4))
	end
	navfig('X')
	legend(reshape(sprintf('%2d uur',uren(ii)+2),6,[])')
	title 'Tijdvereffening ("uur-fout")'
	ylabel [minuten]
end

function pEdge = FindEdge(Prnd,p)
% (!)only for horinontal frame!!
a = 1e10;
for i=1:size(Prnd,1)-1
	A = [p(1),Prnd(i)-Prnd(i+1);
		p(2),Prnd(i,2)-Prnd(i+1,2)];
	if abs(det(A))>1e-6
		ab = A\Prnd(i,1:2)';
		b = ab(2);
		if b>=0 && b<=1 && ab(1)>0
			a = min(a,ab(1));
		end
	end
end
pEdge = a*p;

function UpdateAnim(fig)
t = getappdata(fig,'tShadow');
t = round(t*1440)/1440;
D = fig.UserData;
P = CalcShadows(D.Csw,t);
x = -P(1);
y = -P(2);
hShadow = getappdata(fig,'hShadow');
hShadow.XData(3) = x;
hShadow.YData(3) = y;
tt = datetime(t+1/2880,'convertFrom','juliandate','TimeZone','Europe/Brussels'	...
	,'Format','dd-MMM-uuuu HH:mm');
		% +2/2880 because format truncates(!)
%s = calccaldate(t,[],true);
%s = s(1:end-6);
s = char(tt);
title(s)
Dsteun = getappdata(fig,'Dsteun');
if ~isempty(Dsteun)
	hSteun = getappdata(fig,'hSsteun');
	Csw = D.Csw;
	Csw.Pts = [0 -Dsteun.pSteun Dsteun.lSteun];
	P = CalcShadows(Csw,t);
	hSteun.XData(2) = -P(1);
	hSteun.YData(2) = -P(2);
end

function KeyPressed(fig,ev)
t = getappdata(fig,'tShadow');
bUpdate = false;
switch ev.Character
	case {' ','n'}
		t = t+1/24;
		bUpdate = true;
	case 'p'
		t = t-1/24;
		bUpdate = true;
	otherwise
		switch ev.Key
			case 'leftarrow'
				t = t-1/1440;
				bUpdate = true;
			case 'rightarrow'
				t = t+1/1440;
				bUpdate = true;
			case 'uparrow'
				t = t+1;
				bUpdate = true;
			case 'downarrow'
				t = t-1;
				bUpdate = true;
			case 'pageup'
				t = t+30;
				bUpdate = true;
			case 'pagedown'
				t = t-30;
				bUpdate = true;
		end
end
if bUpdate
	t = round(t*1440)/1440;
	setappdata(fig,'tShadow',t)
	UpdateAnim(fig)
end
