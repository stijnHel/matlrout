function nnr=toonmod(sys,doeprint,nr,recurs,sNr,haalnrweg)
% TOONMOD - opent alle figuren van een simulink model.
%  toonmod(sys,doeprint,nr)

if ~exist('sys');sys=[];end
if ~exist('doeprint');doeprint=[];end
if ~exist('recurs');recurs=[];end
if ~exist('nr');nr=[];end
if ~exist('sNr');sNr=[];end
if ~exist('haalnrweg');haalnrweg=[];end

if isempty(sys);
  sys=bdroot;
end
if isempty(doeprint)
  doeprint=0;
end
if isempty(nr)
	doenr=0;
	if isempty(haalnrweg)
		haalnrweg=doenr;
	end
else
	doenr=1;
	if isempty(haalnrweg)
		haalnrweg=doeprint;
	end
end
if isempty(recurs)
	if doeprint
		if exist(['del ' tempdir 'ttt.ps'])
			dos(['del ' tempdir 'ttt.ps']);
		end
	end
	if exist(sys)~=4
	  	error('toonmod kan alleen gebruikt worden op een geopend simulink-model');
	end
end

s=get_param(sys,'Name');
b=get_param(sys,'Blocks');
l=get_param(sys,'Lines');

% zoek grootte model
mn=[1e6 1e6];
mx=-mn;
b=verblokn(b);
for i=1:length(b)
	m=[sys '/' expbloknaam(b{i})];
	p=get_param(m,'Position');
	set_param(m,'selected','off');
	% houd rekening met de naam (niet helemaal juist gedaan ivm breedte tekst en met aantal lijnen)
	mn=get_param(m,'move name');
	or=get_param(m,'orientation');
	sn=get_param(m,'hide name');
	if sn	% naam wordt getoond
		if mn	% bottom right (normaal)
			if rem(or,2)	% 90 of 270 graden gedraaid
				p(3)=p(3)+40; % !!! breedte tekst
			else
				p(4)=p(4)+20; % !!! aantal lijnen
			end
		else
			if rem(or,2)
				p(1)=p(1)-40;
			else
				p(2)=p(2)-20;
			end
		end
	end
	mn=min(mn,p(1:2));
	mx=max(mx,p(3:4));
end
for i=1:length(l)
	mn=min([mn;l(i).Points]);
	mx=max([mx;l(i).Points]);
end

sp=' ';
if doenr
	nr=nr+1;
	i=find(sys=='/');
	if isempty(i)
		i=0;
	end
	nmblok=strrep(sys(i(1)+1:length(sys)),'/','//');
	i=find(nmblok==10);
	nmblok(i)=sp(ones(size(i)));
	tekstblok=setstr([sys '/' nmblok 10 date 10 '(' sNr ' p.' num2str(nr) ')']);
	pos=[(mn(1)+mx(1))/2 mx(2)+20];
	if isempty(find_system('Name',tekstblok))
		add_block('built-in/Note',tekstblok)
		set_param(tekstblok,'position',[pos pos+[5 5]])
	end
end
if doeprint
	print('ttt','-append',['-s' s]);
end
if haalnrweg
	delete_block(tekstblok);
end

j=0;
for i=1:length(b)
	m=[sys '/' sprintf('%s',expbloknaam(b{i}))];
	if strcmp(get_param(m,'BlockType'),'SubSystem') & ~(hasmask(m) & hasmaskdlg(m)) & isempty(get_param(m,'OpenFcn'))
		j=j+1;
		sNr1=[sNr sprintf('%d.',j)];
		open_system(m);
		nr=toonmod(m,doeprint,nr,1,sNr1,haalnrweg);
		if doeprint,close_system(m);end
	end
end

if doeprint & isempty(recurs)
  dos(['copy ' tempdir 'ttt.ps lpt1']);
  if nargout
  	nnr=getblcks(sys);
  end
elseif nargout
	nnr=nr;
end

function bcor=expbloknaam(b)
bcor=strrep(b,'/','//');

function b2=verblokn(b)
b2={};
for i=1:length(b)
	if b{i}(1)=='/'
		fprintf('Blokken beginnend met een "/" kan ik niet gebruiken (%s)\n',b{i})
	else
		b2{end+1}=b{i};
	end
end
