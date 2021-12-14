function leesbas(f)
% LEESBAS  - Leest basic programma

global BASinstr BASfun

if isempty(BASinstr)
	BASinstr=cell(255,1);
	BASinstr{14}=struct('soort',0);
	BASinstr{15}=struct('soort',1);

	BASinstr{17}=0;
	BASinstr{18}=1;
	BASinstr{19}=2;
	BASinstr{20}=3;
	BASinstr{21}=4;
	BASinstr{22}=5;
	BASinstr{23}=6;
	BASinstr{24}=7;
	BASinstr{25}=8;
	BASinstr{26}=9;
	BASinstr{10}=10;
	BASinstr{28}=struct('soort',16);
	BASinstr{29}=struct('soort',17);
	BASinstr{31}=struct('soort',18);

	BASinstr{129}='end';
	BASinstr{130}='for';
	BASinstr{131}='next';
	BASinstr{132}='data';
	BASinstr{133}='input';
	BASinstr{134}='dim';
	BASinstr{135}='read';
	BASinstr{136}='let';
	BASinstr{137}='goto';
	BASinstr{138}='run';
	BASinstr{139}='if';
	BASinstr{140}='restore';
	BASinstr{141}='gosub';
	BASinstr{142}='return';
	BASinstr{143}='rem';
	BASinstr{144}='stop';
	BASinstr{145}='print';
	BASinstr{146}='clear';
	BASinstr{147}='list';
	BASinstr{148}='new';
	BASinstr{149}='on';
	BASinstr{150}='wait';
	BASinstr{151}='def';
	BASinstr{152}='poke';
	BASinstr{153}='cont';
	BASinstr{154}='nHELL';%??
	BASinstr{155}='`NVIRON';%??
	BASinstr{156}='out';
	BASinstr{157}='lprint';
	BASinstr{158}='llist';
	BASinstr{159}='kALETTE';%??
	BASinstr{160}='width';
	BASinstr{161}='lse';
	BASinstr{162}='tron';
	BASinstr{163}='troff';
	BASinstr{164}='swap';
	BASinstr{165}='erase';
	BASinstr{166}='edit';
	BASinstr{167}='error';
	BASinstr{168}='resume';
	BASinstr{169}='delete';
	BASinstr{170}='auto';
	BASinstr{171}='renum';
	BASinstr{172}='defstr';
	BASinstr{173}='defint';
	BASinstr{174}='defsng';
	BASinstr{175}='defdbl';
	BASinstr{176}='line';
	BASinstr{177}='while';
	BASinstr{178}='wend';
	BASinstr{179}='call';

	BASinstr{192}='cls';
	BASinstr{193}='motor';%??
	BASinstr{194}='bsave';
	BASinstr{195}='bload';
	BASinstr{196}='sound';
	BASinstr{197}='beep';
	BASinstr{198}='pset';
	BASinstr{199}='preset';
	BASinstr{200}='screen';
	BASinstr{201}='key';
	BASinstr{202}='locate';
	BASinstr{204}='to';
	BASinstr{205}='then';
	BASinstr{206}='tab(';%?
	BASinstr{207}='step';
	BASinstr{208}='usr';
	BASinstr{209}='fn';
	BASinstr{210}='spc(';
	BASinstr{211}='not';
	BASinstr{212}='erl';
	BASinstr{213}='err';
	BASinstr{214}='string$';
	BASinstr{215}='using';
	BASinstr{216}='instr';
	BASinstr{217}='´';
	BASinstr{218}='varptr';
	BASinstr{219}='csrlin';
	BASinstr{220}='point';
	BASinstr{221}='off';
	BASinstr{222}='inkey$';
	BASinstr{230}='>';
	BASinstr{231}='=';
	BASinstr{232}='<';
	BASinstr{233}='+';
	BASinstr{234}='-';
	BASinstr{235}='*';
	BASinstr{236}='/';
	BASinstr{237}='^';
	BASinstr{238}='and';
	BASinstr{239}='or';
	BASinstr{240}='xor';
	BASinstr{241}='equ';
	BASinstr{242}='imp';
	BASinstr{243}='mod';
	BASinstr{244}='\';


	BASfun=cell(255,1);
	BASfun{129}='left$';
	BASfun{130}='right$';
	BASfun{131}='mid$';
	BASfun{132}='sgn';
	BASfun{133}='int';
	BASfun{134}='abs';
	BASfun{135}='sqr';
	BASfun{136}='rnd';
	BASfun{137}='sin';
	BASfun{138}='log';
	BASfun{139}='exp';
	BASfun{140}='cos';
	BASfun{141}='tan';
	BASfun{142}='atn';
	BASfun{143}='fre';
	BASfun{144}='inp';
	BASfun{145}='pos';
	BASfun{146}='len';
	BASfun{147}='str$';
	BASfun{148}='val';
	BASfun{149}='asc';
	BASfun{150}='chr$';
	BASfun{151}='peek';
	BASfun{152}='space$';
	BASfun{153}='oct$';
	BASfun{154}='hex$';
	BASfun{155}='lpos';
	BASfun{156}='cint';
	BASfun{157}='csng';
	BASfun{158}='cdbl';
	BASfun{159}='fix';
	BASfun{160}='pen';
	BASfun{161}='stick';
	BASfun{162}='strig';
	BASfun{163}='eof';
	BASfun{164}='loc';
	BASfun{165}='lof';
end
fid=fopen(f,'r');
if fid<3
	if all(f~='.')
		f=[f '.bas'];
		fid=fopen(f,'r');
	end
end
if fid<3
	error('File kon niet geopend worden');
end
x=fread(fid);
fclose(fid);

if x(1)>=48&x(1)<=57
	fprintf('Dit is waarschijnlijk een gewone tekstfile\n');
	%fprintf('%s',setstr(x));
	return;
elseif x(1)~=255
	fprintf('De eerste byte is anders dan verwacht (%d)\n',x(1));
end
i=3;
while x(i)~=0
	i0=i;
	lnr=x(i+1)+x(i+2)*256;
	s=sprintf('%d ',lnr);
	i=i+3;
	while x(i)
		[y,n]=readprim(x,i);
		s=[s y];
		i=i+n;
	end
	%printhex(x(i0:i));
	%fprintf('%s (%02x %02x %02x %02x %02x %02x)\n',s,x(i:i+5));
	fprintf('(%4d) %s\n',x(i0),s);
	i=i+2;
end

function [y,n]=readprim(x,i)
% READPRIM - Leest een "primaat"
global BASinstr BASfun
instr=BASinstr{x(i)};
if x(i)==255
	if ~isempty(BASfun{x(i+1)})
		y=BASfun{x(i+1)};
		n=2;
	else
		fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
		y=sprintf('?fun(%d)?',x(i+1));
		n=2;
	end
elseif ~isempty(instr)
	if ischar(instr)
		y=instr;
		n=1;
	elseif isstruct(instr)
		switch instr.soort
			case 0
				y=sprintf('%d',x(i+1)+x(i+2)*256);
				n=3;
			case 1
				y=num2str(x(i+1));
				n=2;
			case 16
				y=sprintf('%d',x(i+1)+x(i+2)*256);
				n=3;
			case 17
				z=[1 256 65536]*(x(i+1:i+3)+[0;0;128])*2^(x(i+4)-152);
				y=sprintf('%g',z);
				n=5;
			case 18
				z=x(i+1:i+7);
				if all(x(i+1:i+8)==0)
					z=0;
				else
					z(7)=z(7)+128;
					z=[1 cumprod(ones(1,6)*256)]*z*2^(x(i+8)-184);
				end
				y=sprintf('%g',z);
				n=9;
			otherwise
				error('Onbekende soort');
		end
	else
		y=num2str(instr);
		n=1;
	end
elseif x(i)>=32&x(i)<127
	y=setstr(x(i));
	n=1;
else
	fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
	y=sprintf('?%d?',x(i));
	n=1;
end
