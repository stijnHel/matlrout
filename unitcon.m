function [c,unitInfo,varargout] = unitcon(u1,u2,u3,varargin)
% UNITCON - Geeft conversies van eenheden
%    c=unitcon(unit1,unit2)
%    c=unitcon(value,unit1,unit2)
%    unitcon <eenheid> toon
%        geeft alle compatibele eenheden.
%
%    andere mogelijkheden:
%           unitcon('addunit',<nieuw>,<SI-unit>,factor[,offset])
%                     SI-unit: *([MLTKA]n) - e.g. L1T-1 for m/s
%                          [MLTKA] (1 letter) for mass/length/time/temperature/el.current
%           unitcon(<unit>,'toon') toont compatibele eenheden
%           [factor,Info] = unitcon(<unit>);
%                Info: struct with all info
%
%   werd hernoemd door de "nieuwe" ctrlguis/unitconv-functie

persistent UNITinfo
if isempty(UNITinfo)
	UNITinfo=struct('unit',{{}},'conv',[],'offset',[],'num',[]);
	% (data-oorsprong : HP48sx)
	addunit('g','M1',0.001)
	addunit('u','M1',1.66057e-27)
	addunit('oz','M1',0.028349523125)
	addunit('mol','1',6.023e23)
	
	addunit('s','T1',1)
	addunit('min','T1',60)
	addunit('h','T1',3600)
	addunit('d','T1',3600*24)
	addunit('yr','T1',365.242198781*unitcon('d','s'))
	addunit('sideryr','T1',365.2564*unitcon('d','s'))
	addunit('tropyr','T1',365.2422*unitcon('d','s'))
	addunit('anomyr','T1',365.2596*unitcon('d','s'))
	addunit('gregyr','T1',365.2425*unitcon('d','s'))
	addunit('julyr','T1',365.25*unitcon('d','s'))
	addunit('eclipsyr','T1',346.2622*unitcon('d','s'))
	addunit('lunaryr','T1',354.4306*unitcon('d','s'))
	
	addunit('m','L1',1)
	addunit('in','L1',0.0254)
	addunit('mi','L1',1609.344)
	addunit('nmi','L1',1852)	% nautical mile
	addunit('ft','L1',0.3048)
	addunit('yd','L1',0.9144)
	addunit('lyr','L1',9.46052840488e15)
	addunit('AU','L1',149597870700)	% IAU 2012
	addunit('pc','L1',unitcon('AU')*648000/pi)	% (IAU resolution B2, august 2015)
	%addunit('AU','L1',1.49597870691e11)
	%addunit('pc','L1',1.49597870691e11*648000/pi)	% (IAU resolution B2, august 2015)
	
	addunit('l','L3',1e-3)
	addunit('cc','L3',1e-6)
	addunit('gal','L3',0.003785411784)
	addunit('galUK','L3',0.004546092)
	addunit('pt','L3',0.000473176473)
	
	addunit('lb','M1',0.45359237)
	
	addunit('kph','L1T-1',1/3.6);
	addunit('mph','L1T-1',unitcon('mi','m')/3600);
	addunit('c','L1T-1',299792458)	% ?consistentie met lyr?
	addunit('knot','L1T-1',4.63/9);
	
	addunit('N','M1L1T-2',1)
	addunit('gf','M1L1T-2',0.00980665)
	addunit('dyn','M1L1T-2',1e-5)
	addunit('lbf','M1L1T-2',9.80665*0.45359237)
	
	addunit('J','M1L2T-2',1)
	addunit('cal','M1L2T-2',4.1868)
	addunit('eV','M1L2T-2',0.160219e-18)
	addunit('hPlanck','M1L2T-1',6.62607015e-34)
	
	addunit('W','M1L2T-3',1)
	addunit('pk','M1L2T-3',745.699871582)
	addunit('hp','M1L2T-3',735.5)
	
	addunit('are','L2',100)
	addunit('acre','L2',4046.87260987)
	
	addunit('Pa','M1L-1T-2',1)
	addunit('bar','M1L-1T-2',1e5)
	addunit('atm','M1L-1T-2',101325)	% fysisch
	addunit('at','M1L-1T-2',98066.5);	% technisch
	addunit('mmHg','M1L-1T-2',13595.1*9.80665/1000)
	addunit('inHg','M1L-1T-2',3386.38815789)	% afh van in en mmHg - in feite temperatuursafhankelijk!! (https://en.wikipedia.org/wiki/Inch_of_mercury)
	addunit('psi','M1L-1T-2',unitcon('lbf/in^2'))
	addunit('torr','M1L-1T-2',101325/760)	% oorspronkelijk zelfde als mmHg, maar niet meer exact na herdefinities
	
	addunit('Wb','M1L2A-1T-2',1)
	addunit('T','M1A-1T-2',1)
	addunit('S','A2T3M-1L-2',1)
	addunit('H','M1L2A-2T-2',1)
	addunit('F','A2T4M-1L-2',1)
	addunit('ohm','M1L2A-2T-3',1)
	addunit('C','A1T1',1)
	addunit('A','A1',1)
	addunit('V','M1L2A-1T-3',1)
	
	addunit('K','K1',1);
	addunit('°C','K1',1,273.15);
	addunit('°F','K1',5/9,2298.35/9);
	addunit('°R','K1',5/9);
	addunit('degC','K1',1,273.15);
	addunit('degF','K1',5/9,2298.35/9);
	addunit('degR','K1',5/9);
	addunit('Gal','L1T-2',0.01);
	% andere eenheden
	addunit('Nm','M1L2T-2',unitcon('N*m'))
	addunit('Wh','M1L2T-2',3600)
	addunit('gBenzine','L3',1/745e3); % 0.745 g/cc, (is 725 g/cc geweest,
	%   maar werd veranderd om in overeenstemming met data van pvdm te komen)
	addunit('r','1',2*pi);
	addunit('°','1',pi/180);
	addunit('deg','1',pi/180);
	addunit('grad','1',pi/200);
	addunit('rpm','T-1',pi/30);
	addunit('Hz','T-1',2*pi);
end

if iscell(u1)
	O = cell(max(1,nargout),2);
	if nargin>1
		error('Sorry, cell input is only compatible with 1 input!')
	end
	for i=1:length(u1)
		[O{i,:}] = unitcon(u1{i});
	end
	I = [O{:,2}];
	c = cat(1,I.b1);
	if nargout>1
		unitInfo = 'MLTAK';
	end
	return
elseif ischar(u1) && strcmpi(u1,'test')
	[unitInfo,c] = getsi(u2,false);
	if nargout>2
		varargout = {siunit(c)};
	end
	return
elseif ischar(u1) && strcmpi(u1,'addunit')
	addunit(u2,u3,varargin{1})
	return
elseif nargin==3
	if ischar(u1)
		val=eval(u1);
	else
		val=u1;
	end
	u1=u2;
	u2=u3;
else
	val=1;
end
[v1,b1,off1]=getsi(u1,true);
if nargin>1
	if strcmp(u2,'toon')
		i=find(sum(b1(ones(1,length(UNITinfo.conv)),:)~=UNITinfo.num,2)==0);
		if nargout
			c = UNITinfo.unit(i);
		elseif isempty(i)
			fprintf('!Er zijn geen compatibele eenheden!\n');
		else
			fprintf('compatibele eenheden :\n');
			printstr(UNITinfo.unit(i));
		end
		return;
	end
	[v2,b2,off2]=getsi(u2,true);
	if any(b1~=b2)
		error('incompatibele eenheden')
	end
	if isempty(off1)
		off1=0;
	end
	if isempty(off2)
		off2=0;
	end
	c=(val*v1+off1-off2)/v2;
elseif nargout
	c=v1;
	if nargout>1
		unitInfo = var2struct(v1,b1,off1);
		unitInfo.baseUnitOrder = 'MLTAK';
	end
else
	fprintf('%g ',v1);
	printsi(b1)
	fprintf('\n');
end

	function addunit(u,si,f,off)
		if any(strcmp(UNITinfo.unit,u))
			iU = find(strcmp(UNITinfo.unit,u));
			warning('Unit overwritten! ("%s")',u)
		else
			iU = size(UNITinfo.unit,2)+1;
			UNITinfo.unit{1,iU}=u;
		end
		UNITinfo.conv(iU)=f;
		if ~exist('off','var')||isempty(off)
			off=0;
		end
		UNITinfo.offset(iU)=off;
		UNITinfo.num(iU,:)=numdim(si);
	end		% function addunit

	function [v,b,offset]=getsi(u,bErrorIfNE)
		%getsi - Interprete formula of units to base units
		uu=u;
		uu(uu=='.')='*';	% allow multiply by point
		[Df,U,Op,OpN]=InterpreteFormula(uu,'-bMatlab');
		Bu=cell(3,length(U));
		for iu=1:length(U)
			[Bu{:,iu}]=GetSIvalues(U{iu},bErrorIfNE);
			if isempty(Bu{1,iu})
				v = [];
				b = [];
				offset = [];
				return
			end
		end
		BO=cell(3,size(Op,1));
		for iO=1:size(Op,1)
			op=Df(2,Op(iO));
			switch op
				case 1	% variable
					iv=Op(iO,5);
					BO(:,iO)=Bu(:,iv);
				case 3	% number
					BO{1,iO}=zeros(1,5);
					BO{2,iO}=Op(iO,5);
					BO{3,iO}=0;
				case 13	% multiply
					i1=-Op(iO,5);
					i2=-Op(iO,6);
					BO{1,iO}=BO{1,i1}+BO{1,i2};	% add powers
					BO{2,iO}=BO{2,i1}*BO{2,i2};	% multiply factors
					BO{3,iO}=0;	% no offset possible
				case 14 % divide
					i1=-Op(iO,5);
					i2=-Op(iO,6);
					BO{1,iO}=BO{1,i1}-BO{1,i2};	% subtract powers
					BO{2,iO}=BO{2,i1}/BO{2,i2};	% divide factors
					BO{3,iO}=0;	% no offset possible
				case 26 % power
					i1=-Op(iO,5);
					i2=-Op(iO,6);
					if ~all(BO{1,i2}==0)
						error('Only scalar powers allowed!')
					end
					BO{1,iO}=BO{1,i1}*BO{2,i2};	% multiply powers
					BO{2,iO}=BO{2,i1}^BO{2,i2};	% divide factors
					BO{3,iO}=0;	% no offset possible
				case 50	% '('
					BO(:,iO)=BO(:,-Op(iO,5));	% just copy
				otherwise
					bb=[OpN{1,:}]==op;
					error('Not allowed operand (%s)!',OpN{2,bb})
			end
		end
		v=BO{2,iO};
		b=BO{1,iO};
		offset=BO{3,iO};
	end		% function getsi

	function b=numdim(si)
		%numdim - convert base unit spec to vector of powers
		SIunitvolg='MLTAK';
		% Massa	[kg]
		% Lengte	[m]
		% Tijd	[s]
		% A (stroom)	[A]
		% K (temp)	[K]
		si=deblank(si);
		b=zeros(1,5);
		while ~isempty(si)
			isi=find(si(1)==SIunitvolg);
			if isempty(isi)	% dimensieloze eenheid
				is=1;
			else
				is=2;
				if si(is)=='-'
					is=is+1;
				end
				while (is<length(si))&&(si(is+1)>='0')&&(si(is+1)<='9')
					is=is+1;
				end
				if is>length(si)
					is=is-1;
				end
				b(isi)=b(isi)+str2double(si(2:is));
			end
			si(1:is)='';
		end
	end		% function numdim

	function s = siunit(b)
		C = {'','.','.','.','.';'kg','m','s','A','K'};
		for ib=1:length(b)
			if b(ib)
				if b(ib)~=1
					C{2,ib} = sprintf('%s^%d',C{2,ib},b(ib));
				end
			end
		end
		C = C(:,b~=0);
		if isempty(C)
			s = '-';
		else
			s = [C{2:end}];
		end
	end		% function printsi

	function printsi(b)
		j=0;
		for ib=1:length(b)
			if b(ib)
				if j
					fprintf('.')
				else
					j=1;
				end
				switch ib
					case 1
						fprintf('kg')
					case 2
						fprintf('m')
					case 3
						fprintf('s')
					case 4
						fprintf('A')
					case 5
						fprintf('K')
					otherwise
						error('onbekende SI-eenheid');
				end
				if b(ib)~=1
					fprintf('^%d',b(ib))
				end
			end
		end
	end		% function printsi

	function [b,v,offset]=GetSIvalues(u,bErrorIfNE)
		%GetSIvalues - convert to powers of base units with factor and offset
		v=1;
		iu=find(strcmp(u,UNITinfo.unit));
		if isempty(iu)&&length(u)>1
			switch u(1)
				case 'Y'	% yotta
					v=1e24;
				case 'Z'	% zetta
					v=1e21;
				case 'E'	% exa
					v=1e18;
				case 'P'	% peta
					v=1e15;
				case 'T'	% tera
					v=1e12;
				case 'G'
					v=1e9;
				case 'M'
					v=1e6;
				case {'k','K'}
					v=1000;
				case 'h'
					v=100;
				case 'D'
					v=10;
				case 'd'
					v=0.1;
				case 'c'
					v=0.01;
				case 'm'
					v=1e-3;
				case {'µ','u'}
					v=1e-6;
				case 'n'
					v=1e-9;
				case 'p'
					v=1e-12;
				case 'f'	% femto
					v=1e-15;
				case 'a'	% atto
					v=1e-18;
				case 'z'	% zepto
					v=1e-21;
				case 'y'	% yocto
					v=1e-24;
				otherwise
					v=0;
			end
			if v
				u(1)='';
				iu=find(strcmp(u,UNITinfo.unit));
			end
		end		% if isempty(iu) && ~scalar(u)
		if isempty(iu)
			if bErrorIfNE
				error('unit %s niet gevonden',u)
			else
				b = [];
				return
			end
		end		% if isempty?(iu)
		v=v*UNITinfo.conv(iu);
		b=UNITinfo.num(iu,:);
		offset=UNITinfo.offset(iu);
	end		% function GetSIvalues

end		% function unitcon
