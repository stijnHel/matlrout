function out=leeslgw(fn)
% LEESLGW  - Leest Ansys-lgw files
%      out=leeslgw(fn)

% !!!instructies mogen afgekort worden!!!!
%     solve --> solv ----- hoe dit (eenvoudig) aanpakken
%               (maar solvi mag niet!!)
%        mogelijkheid ipv case 'solve'   case {'solv','solve'}

% meer gebruik maken van default waarden (bijv fitem)
% bij aanmaken van "hogere orde elementen" moeten de lagere ook aangemaakt
% worden (lijnen ==> punten; areas ==> punten,lijnen; volumes ==>
% areas,lijnen,punten)

% globals (tijdens testen, nadien mag dit weg)
global LLGWnumchars LLGWparn LLGWparn1 compnames
global LGWcmds onbcmd

if isempty(LGWcmds)
	LGWcmds=prepcmds;	% nu nog niet gebruikt
end
if ~iscell(onbcmd)
	onbcmd={};
end

%!!!erg beperkt
fid=fopen(fn,'rt');
if fid<3
	error('Kan file niet openen')
end

LLGWnumchars=zeros(1,255);  % (false, maar matlab5-compatibel)
% (null-chars niet toegelaten)
LLGWnumchars(abs('0123456789.'))=1;
LLGWparn1=zeros(1,255);
LLGWparn1([abs('a'):abs('z') abs('A'):abs('Z') abs('_')])=1;
LLGWparn=LLGWparn1;
LLGWparn(abs('0123456789'))=1;

Slgw=struct('S',struct('elem',cell(1,1000),'data',[]),'nS',1);
s0=Slgw.S(1);
if 1		% (!!) confusion of Matlab-JIT?
	s1=s0;
	s0.elem='';
	s1.elem='??';
end
Slgw.S(1).elem='par';
Slgw.S(1).data=struct('naam',{},'waarde',{});
compnames=struct('naam',{},'data',{});

commtype=0;
selEl=[];

lnr=0;

while ~feof(fid)
	lnr=lnr+1;
	l=deblank(fgetl(fid));
	s1=s0;
	if ~isempty(l)
		if l(1)~='!'
			% ??!!kontrolleer bij elk element aantal gegevens, mogelijke commtype
			%  hiertoe is het misschien beter om elementen niet direct aan te maken
			% in het bekijken van lparts{1}, maar later.
			if 0	% dit zou niet mogelijk moeten zijn (vooral bij a=1 % ss)
				i=find(l=='!');
				if ~isempty(i)
					l=l(1:i(1)-1);
				end
			end
			ll=lower(l);
			lparts=splits(ll);
			if lparts{1}(1)=='*'
				switch lparts{1}
					case '*set'
						% bepaalt parameter
						Slgw.S(1).data(end+1).naam=lparts{2};
						Slgw.S(1).data(end).waarde=calcpar(Slgw,lparts{3});
					otherwise
						if isempty(onbcmd)
							onbcmd=lparts(1);
							warning(sprintf('onbekend gebruik van *-command (%d:%s)',lnr,l))
						else
							i=strmatch(lparts{1},onbcmd,'exact');
							if isempty(i)
								onbcmd{end+1}=lparts{1};
								warning(sprintf('onbekend gebruik van *-command (%d:%s)',lnr,l))
							end
						end
				end
			elseif lparts{1}(1)=='/'
				switch lparts{1}(2:end)
					case 'prep7'
						% start preprocessor
						commtype=1;
					case 'vscale'
						%/vscale,1,1,0
					case 'post1'
						%/post1
					case 'sol'
						%/sol
					case 'go'
						%/go
					case 'pmeth'
						%/pmeth,off,1
						% enkel te maken met GUI
					case 'nopr'
						%/nopr
						% enkel te maken met GUI
					case 'triad'
						%/triad,off
						% enkel te maken met GUI
					case 'replot'
						%/replot
						% enkel te maken met GUI
					case 'title'
					case 'units'
					case 'show'
					otherwise
						if isempty(onbcmd)
							onbcmd=lparts(1);
							warning(sprintf('onbekend gebruik van /-command (%d:%s)',lnr,l))
						else
							i=strmatch(lparts{1},onbcmd,'exact');
							if isempty(i)
								onbcmd{end+1}=lparts{1};
								warning(sprintf('onbekend gebruik van /-command (%d:%s)',lnr,l))
							end
						end
				end
			else
				switch lparts{1}
					case 'k'
						% maakt keypoint
						s1.elem='keypoint';
						knr=str2num(lparts{2});
						if isempty(knr)
							knr=lparts{2};
						end
						x=calcpar(Slgw,lparts{3});
						y=calcpar(Slgw,lparts{4});
						z=calcpar(Slgw,lparts{5});
						s1.data=struct('nr',knr,'X',[x,y,z]);
					case 'lstr'
						s1.elem='line';
						knr1=str2num(lparts{2});
						if isempty(knr1)
							knr1=lparts{2};
						end
						knr2=str2num(lparts{3});
						if isempty(knr2)
							knr2=lparts{3};
						end
						s1.data=struct('style','straight','knr1',knr1,'knr2',knr2);
						if ~isempty(knr1)&~isempty(knr2)
							[ilijst,X]=zoekpunten(Slgw,[knr1 knr2]);
							if isempty(X)
								error('!!geen coordinaten gevonden van een lijn!!')
							end
							s1.data.ptn=ilijst;
							s1.data.X=X;
						end
					case 'larc'
						knr1=str2num(lparts{2});
						if isempty(knr1)
							knr1=lparts{2};
						end
						knr2=str2num(lparts{3});
						if isempty(knr2)
							knr2=lparts{3};
						end
						if isempty(lparts{4})
							knrc=[]; %?bepalen?
						else
							knrc=str2num(lparts{4});
							if isempty(knrc)
								knrc=lparts{4};
							end
						end
						if isempty(lparts{5})
							rad=[]; %?bepalen?
						else
							rad=calcpar(Slgw,lparts{5});
							if isempty(rad)
								rad=lparts{5};
							end
						end
						s1.elem='line';
						s1.data=struct('style','arc','p1',knr1,'p2',knr2,'pc',knrc,'rad',abs(rad));
						if ~ischar(knr1)&~ischar(knr2)&~ischar(knrc)
							% bepaal coordinaten van punten
							[ilijst,X]=zoekpunten(Slgw,[knr1,knr2,knrc]);
							er=max(abs(X(:)));
							% bepaal positie arc
							% eerst het vlak van de boog (A1 X = d1)
							s1.data.ptn=ilijst;
							s1.data.X=X;
							if abs(cond(X))>1e3 % singular
								A1=(X+1)\[1;1;1];
								d1=0;
							else
								A1=X\[1;1;1];
								d1=1;
							end
							% vlak midden door p1 en p2
							dX=diff(X(1:2,:));
							A2=diff(X(1:2,:));
							d2=sum(diff(X(1:2,:).^2))/2;
							%?beter doen in het geval van 0
							if isempty(rad)
								% bepaal centrum
								A3=diff(X([1 3],:));
								d3=sum(diff(X([1 3],:).^2))/2;
								A=[A1';A2;A3];
								if cond(A)>1000
									error('De boog kan hier niet bepaald worden.')
								end
								Xc=(A\[d1;d2;d3])';
								r=sqrt(sum((Xc-X(1,:)).^2));
							else
								if rad>4
									%set breakpoint
									rad=rad+1-1;
								end
								% p1, p2 en pc liggen op cirkel - bepaal
								% straal, centrum
								bc=A1(2)*A2(3)-A1(3)*A2(2);
								if abs(bc)<er/1e8
									% loodlijn op cirkel door centrum is
									% evenwijdig aan X-as
									% bepaal (y,z)
									% dit geeft wel afrondingsfouten bij
									% valkken loodrecht op Y of Z!!
									x=d1/A1(1);
									if A2(2)==0
										z=d2/A2(3);
										dy=sqrt(rad*rad-(z-X(1,3))^2);
										Xc=[x x;X(1,2)-dy X(1,2)+dy;z z];
									elseif A2(3)==0
										y=d2/A2(2);
										dz=sqrt(rad*rad-(y-X(1,2))^2);
										Xc=[x x;y y;X(1,3)-dz X(1,3)+dz];
									else
										z=roots([(A2(3)/A2(2))^2+1,2*((X(1,2)-d2/A2(2))*A2(3)/A2(2)-X(1,3)),(d2/A2(2)-X(1,2))^2+X(1,3)^2-rad*rad])';
										y=(d2-A2(3)*z)/A2(2);
										Xc=[x x;y;z];
									end
								else
									A0=(d1*A2(3)-d2*A1(3))/bc;
									Aa=A0-X(1,2);
									Ax=(A1(1)*A2(3)-A1(3)*A2(1))/bc;
									B0=-(d1*A2(2)-d2*A1(2))/bc;
									Bb=B0-X(1,3);
									Bx=-(A1(1)*A2(2)-A1(2)*A2(1))/bc;
									pa=1+Ax*Ax+Bx*Bx;
									pb2=-Aa*Ax-Bb*Bx-X(1);
									pc=X(1)*X(1)+Aa*Aa+Bb*Bb-rad*rad;
									% (kan ook op basis van Matlab roots)
									pD=pb2*pb2-pa*pc;
									if pD<0
										warning(sprintf('???onmogelijke boog????(%d:%s)',lnr,l))
										pD=0;
									end
									x=(-pb2+[1 -1]*sqrt(pD))/pa;
									y=A0-Ax*x;
									z=B0-Bx*x;
									Xc=[x;y;z];
								end
								if any(imag(Xc(:)))
									warning(sprintf('Onmogelijke cirkelboog (%d - %d:%s)',Slgw.nS+1,lnr,l))
								end
								r=abs(rad);
								Dd=cross(A2([1 1 1],:)',[Xc X(3,:)']-X([1 1 1],:)');
								[mx,i]=max(abs(Dd(:,1)));
								if Dd(i,1)*Dd(i,3)*rad>0
									Xc=Xc(:,1)';
								else
									Xc=Xc(:,2)';
								end
								if abs(r-sqrt(sum((Xc-X(1,:)).^2)))>1e-6
									error('!!verkeerde straal!!')
								end
							end
							s1.data.Xc=Xc;
							s1.data.r=r;
							A1_0=abs(A1)/r<1e-8;
							if sum(A1_0)==2 % ??eerder testen door gelijk zijn van xyz-coordinaten?
								s=sum(A1);
								d1=d1/s;
								A1=A1/s;
								as=find(~A1_0);
								phi=0;
								% ??juiste deel van boog?
								switch as
									case 1
										rho=atan2(X(1,3)-Xc(3),X(1,2)-Xc(2));
										the=atan2(X(2,3)-Xc(3),X(2,2)-Xc(2));
									case 2
										rho=atan2(X(1,1)-Xc(1),X(1,3)-Xc(3));
										the=atan2(X(2,1)-Xc(1),X(2,3)-Xc(3));
									case 3
										rho=atan2(X(1,2)-Xc(2),X(1,1)-Xc(1));
										the=atan2(X(2,2)-Xc(2),X(2,1)-Xc(1));
								end
								if the<rho
									the=the+2*pi;   % ??wat is hier best?? wisselen, ....
								end
							else
								L=sqrt(A1'*A1);
								[mx,as]=max(abs(A1));
								if as==2
									ip=[3 1];
								else
									ip=1:3;
									ip(as)=[];
								end
								if ip(1)==2
									ib=[3 1];
								else
									ib=1:3;
									ib(ip(1))=[];
								end
								cphi=mx/L;
								phi=acos(cphi);
								sphi=sqrt(1-cphi*cphi);
								b=atan2(A1(ib(2)),A1(ib(1)));
								Ap=eye(3);
								Ab=Ap;
								Ap(ip,ip)=[cphi sphi;-sphi cphi];
								Ab(ib,ib)=[cos(b) sin(b);-sin(b) cos(b)];
								Arot=Ab'*Ap*Ab;
								warning(sprintf('!!cirkelbogen buiten hoofdvlak - niet klaar!!(%d:%s) (-->%d)',lnr,l,Slgw.nS+1))
								X1=Arot*(X(1,:)-Xc)';
								X2=Arot*(X(2,:)-Xc)';
								X1=X1(ip);
								X2=X2(ip);
								rho=atan2(X1(2),X1(1));
								the=atan2(X2(2),X2(1));
								if the<rho
									the=the+2*pi;   % ??wat is hier best?? wisselen, ....
								end
								s1.data.beta=b;
								s1.data.Arot=Arot;
							end
							s1.data.A1=A1';
							s1.data.d1=d1;
							s1.data.phi=[phi as];
							s1.data.rho=rho;
							s1.data.the=the;
						end
					case 'rectng'	% rectangular area
						x1=calcpar(Slgw,lparts{2});
						x2=calcpar(Slgw,lparts{3});
						y1=calcpar(Slgw,lparts{4});
						y2=calcpar(Slgw,lparts{5});
						s1.elem='area';
						s1.data=struct('coor',[x1,y1;x2,y1;x2,y2;x1,y2]);
					case 'pcirc'	% circular area
						r1=calcpar(Slgw,lparts{2});
						r2=calcpar(Slgw,lparts{3});	%???wat als leeg?
						t1=calcpar(Slgw,lparts{4});
						t2=calcpar(Slgw,lparts{5});
						s1.elem='line';	% Er moet eigenlijk een lijn (?of 4 lijnen?) gemaakt worden
								% en ook een area
						s1.data=struct('style','arc','Xc',[0 0 0],'r',r1	...
							,'r2',r2	...
							,'phi',[0 3]	... (in XY vlak)
							,'rho',min(t1,t2),'the',max(t1,t2));
						s1(2).elem='area';
						s1(2).data=struct('line','welknummer?');
					case 'aovl'	% overlapping areas
						switch lower(lparts{2})
							case 'all'
								%zoek alle areas
								A=zoekelems(Slgw,'area');
							case 'p'	% !!! selectie
								A=[];
								warning('Grafische selectie gaat hier niet!!')
							otherwise
								A=zeros(1,length(lparts)-1);
								for i=2:length(lparts)
									A(i-1)=str2num(lparts{i});
								end
						end
						if length(A)==1
							% ?gewoon kopie??
							warning('Bij overlappende area werd maar een area gegeven!!')
							s1=Slgw.S(A);
						elseif length(A)>1
							s1.elem=area;
							S1.data=struct('oper','add','elem',cat(2,Slgw.S(A).data));
						end
					case 'v'
						%v,122,322,321,121,132,132,131,131
						nrs=zeros(1,8);
						for i=1:8
							nr=str2num(lparts{i+1});
							if ~isempty(nr)
								nrs(i)=nr;
							end
						end
						[ilijst,X]=zoekpunten(Slgw,nrs);
						s1.elem='volume';
						s1.data=struct('nrs',nrs,'ptn',ilijst,'X',X);
						% hier zouden ook lijnen en areas gemaakt moeten
						% worden
					case 'flst'
						nr=str2num(lparts{2});
						aantalel=str2num(lparts{3});
						soort=str2num(lparts{4});
						aantalc=str2num(lparts{6});
						if ~isempty(selEl)
							warning(sprintf('!!selectie niet leeg (gebruikt) bij maken van selectie!!',lnr,l))
						end
						selEl=struct('nr',nr,'aantalel',aantalel,'soort',soort  ...
							,'order',lparts{5},'aantalc',aantalc    ...
							,'volgnr',[],'sel',[]);
					case 'fitem'
						if isempty(selEl)
							warning(sprintf('!!!gebruik van fitem zonder flst???(%d:%s)',lnr,l))
						else
							nr=str2num(lparts{2});
							if nr~=selEl.nr
								warning(sprintf('!!gebruik van fitem met ander nummer als flst!!??(%d:%s)',lnr,l))
								selEl=[];
							else
								item=str2num(lparts{3});
								if item<0
									if isempty(selEl.volgnr)
										warning(sprintf('!!!!ander gebruik van item,<>,-n dan verwacht !!(als eerste selectie)!!(%d:%s)',lnr,l))
										item=1;
									else
										%item=selEl.volgnr(end):selEl.volgnr(end)-1-item;   %???juist???
										item=selEl.volgnr(end):-item;   %???juist???
										selEl.volgnr(end)=[];
										selEl.sel(end)=[];
									end
								end
								i=zoekelems(Slgw,selEl.soort);
								%	otherwise
								%		error('Onbekende soort in flst')
								if isempty(i)|length(i)<max(item)
									warning(sprintf('!!!niet voldoende elementen van juist type gevonden bij selectie!!!(%d:%s)',lnr,l))
								else
									selEl.volgnr=[selEl.volgnr item];
									selEl.sel=[selEl.sel i(item)];
								end
							end
						end
					case 'vadd'
						%vadd,p51x
						% voegt volumes samen (en delete oorspronkelijke)
						%   !!bij gebruik van p51x -- te maken met
						%   GUI-selectie
						p1=str2num(lparts{2});
						if isempty(p1)
							if strcmp(lower(lparts{2}),'p51x')
								if isempty(selEl)
									error('!gebruik van selectie zonder selectie te maken!')
								else
									el=selEl.sel;
								end
							else
								error(sprintf('Onbekend gebruik van vadd (%s)',l))
							end
						else
							el=str2num(strvcat(lparts{2:end}));
							i=zoekelems(Slgw,'volume');
							el=i(el);
						end
						% !!als een van de elementen al een "add" is,
						% vervangen.  (!!!!dit loopt niet goed bij
						% combinaties!!!!)
						data=struct('oper','add','elem',cat(2,Slgw.Slgw.S(el).data));
						%!!!mogelijk moeten elementen niet verwijderd
						%worden!!!!!
						Slgw.S(el(1)).data=data;
						Slgw.S(el(2:end))=[];
						Slgw.nS=Slgw.nS-length(el)+1;
						selEl=[];
						%!!!verwijzingen naar punten corrigeren!!!(of toch
						%beter niet bewaren)
					case 'vsbv'
						% lparts{4} is "SEPO" of leeg.
						% dit bepaalt het gedrag bij uitkomen van een
						% oppervlak.
						if length(lparts)<6
							lparts{6}='';
						end
						if isempty(lparts{5})
							del1=1;
						else
							del1=lparts{5}(1)=='d';
						end
						if isempty(lparts{6})
							del2=1;
						else
							del2=lparts{6}(1)=='d';
						end
						i=zoekelems(Slgw,'volume');
						p1=str2num(lparts{2});
						if isempty(p1)|p1<1|p1>length(i)
							warning('gebruik van onbestaand volume (bij vsbv)???')
						else
							el1=i(p1);
							p2=str2num(lparts{3});
							%?p1 ook mogelijk met p51x?
							if isempty(p2)
								if strcmp(lower(lparts{3}),'p51x')
									if isempty(selEl)
										error('!gebruik van selectie zonder selectie te maken!')
									else
										el2=selEl.sel;
									end
								else
									error(sprintf('Onbekend gebruik van vadd (%s)',l))
								end
							else
								el2=i(p2);
							end
							s1.elem='volume';
							data=Slgw.S(el1).data;
							for i=length(el2):-1:1
								data=struct('oper','sub','elem1',data,'elem2',Slgw.S(el2(i)).data,'sepo',lparts{4});
							end
							s1.data=data;
							%!!!mogelijk moeten elementen niet verwijderd
							%worden!!!!!
							idel=[];
							if del1
								idel=el1;
							end
							if del2
								idel=[idel el2];
							end
							if ~isempty(idel)
								Slgw.S(idel)=[];
								Slgw.nS=Slgw.nS-length(idel);
							end
							selEl=[];
							% toch altijd een nieuw (ook al worden er elementen
							% gedelete) om moeilijkheden met plaatsen van
							% volumes gemakkelijk te vermijden.
						end
					case 'keyw'
						%keyw,pr_set,1
					case 'et'
						%et,1,solid96
					case 'mptemp'
						%mptemp,,,,,,,,
					case 'mpdata'
						%mpdata,murx,1,,1
					case 'cm'
						%cm,_y,volu
						%cm,cname,entity
						setcomponent(lparts{2},lparts{3});   %???
					case 'vsel'
						%vsel, , , ,       7
						if length(lparts)>4&strcmp(lower(lparts{5}),'p51x')
							%!!!!doe iets met de selectie...
							selEl=[];
						end
					case 'cmsel'
						%cmsel,s,_y
					case 'vatt'
						%vatt,       1, ,   1,       0
					case 'cmdele'
						%cmdele,_y
					case 'lsel'
						%lsel, , , ,p51x
						if length(lparts)>4&strcmp(lower(lparts{5}),'p51x')
							%!!!!doe iets met de selectie...
							selEl=[];
						end
					case 'lesize'
						%lesize,_y1, , ,20, , , , ,1
					case 'mshape'
						%mshape,1,3d
					case 'mshkey'
						%mshkey,0
					case 'chkmsh'
						%chkmsh,'volu'
					case 'vmesh'
						%vmesh,_y1
					case 'da'
						%da,p51x,mag,0,
						if length(lparts)>1&strcmp(lower(lparts{2}),'p51x')
							%!!!!doe iets met de selectie...
							selEl=[];
						end
					case 'finish'
						%finish
					case 'magsolv'
						%magsolv,2, , ,0.001,25,0
					case 'allsel'
						%allsel,below,volu
					case 'plvect'
						%plvect,b, , , ,vect,elem,on,0
					case 'etable'
						%etable,bhall,b,sum
					case 'pretab'
						%pretab,bhall
					case 'save'
					case 'aplot'
					case 'smrt'	% ?zelfde als SMRTSIZE?
					case 'tunif'	% uniform temperature
					case 'antype'
					case 'trnopt'
					case 'lumpm'
					case 'time'
					case 'outres'
					case 'nsubst'
					case 'solve'
					otherwise
						if isempty(onbcmd)
							onbcmd=lparts(1);
							warning(sprintf('onbekend commando (%d:%s)',lnr,l))
						else
							i=strmatch(lparts{1},onbcmd,'exact');
							if isempty(i)
								onbcmd{end+1}=lparts{1};
								warning(sprintf('onbekend commando (%d:%s)',lnr,l))
							end
						end
				end
			end
			if ~isempty(s1(1).elem)
				if Slgw.nS+length(s1)>length(Slgw.S)
					Slgw.S(Slgw.nS+999)=s0;
				end
				Slgw.S(Slgw.nS+1:Slgw.nS+length(s1))=s1;
				Slgw.nS=Slgw.nS+length(s1);
			end
		end
	end
end
fclose(fid);
out=Slgw.S(1:Slgw.nS);

function lparts=splits(ll)
% splitst lijn in onderdelen (met ',' als delimiter)

setcommand=0;
if any(ll=='=')
	iis=find(ll=='=');
	i=find(ll=='!');	% voor het geval commentaar-delen niet weggehaald zijn.
	if isempty(i)|i(1)>iis(1)
		if length(iis)>1
			warning(sprintf('onverwacht gebruik van "=" (%d:%s)',lnr,l))
		end
		ll(ll=='=')=',';
		setcommand=1;
	end
end
i=[0 find(ll==',') length(ll)+1];
lparts=cell(1,length(i)-1);
for j=1:length(lparts)
	s=deblank(ll(i(j)+1:i(j+1)-1));
	if ~isempty(s)
		while s(1)==' '
			s(1)='';
		end
		lparts{j}=s;
		% else lparts{j} is al leeg
	end
end
if setcommand
	lparts={'*set',lparts{:}};
end

function sval=calcpar(Slgw,s)
% CALCPAR - Bepaalt parameter (met formules)
global LLGWnumchars LLGWparn LLGWparn1
pars={Slgw.S(1).data.naam};
if any(s=='!')
	i=find(s=='!');
	s=deblank(s(1:i(1)-1));
end
sval=s;
if ischar(s)
	s=strrep(s,'**','^');
	i=1;
	allvalues=1;
	while i<=length(s)
		if LLGWparn1(abs(s(i)))
			j=i+find(~LLGWparn(abs(s(i+1:end))));
			if isempty(j)
				j=length(s)+1;
			else
				j=j(1);
			end
			s1=s(i:j-1);
			k=strmatch(s1,pars,'exact');
			if ~isempty(k)
				k=k(1);
				if ~ischar(Slgw.S(1).data(k).waarde)
					s2=num2str(Slgw.S(1).data(k).waarde,20);
					s=[s(1:i-1) s2 s(j:end)];
					j=i+length(s2);
				end
			end
		elseif LLGWnumchars(abs(s(i)))
			j=i+1;
			while j<=length(s)&(LLGWnumchars(abs(s(j)))|lower(s(j))=='e')
				j=j+1;
			end
		else
			j=i+1;
		end
		i=j;
	end % while
	try
		sval=eval(s);
	catch
		warning(sprintf('!!!onuitrekenbare functie!!! (%s)',s))
	end
end

function i=zoekelems(Slgw,eltype)
if isnumeric(eltype)
	if eltype<0|eltype>9
		error('Onbekend element-type')
	else
		E={'node','element','keypoint','line','area','volume'	...
			,'trace','coor','screen'};
		eltype=E{eltype};
	end
end
i=strmatch(eltype,{Slgw.S(1:Slgw.nS).elem})';

function [ilijst,X]=zoekpunten(Slgw,knr)
ilijst=knr;
for i=2:Slgw.nS
	if strcmp(Slgw.S(i).elem,'keypoint')&~ischar(Slgw.S(i).data.nr)
		j=find(knr==Slgw.S(i).data.nr);
		if ~isempty(j)
			ilijst(j)=i;
			knr(j)=inf;
		end
	end
end
if any(~isinf(knr))
	error('Ongedefinieerd punt gebruikt!!')
end
X=zeros(length(knr),3);
for i=1:length(knr)
	X(i,:)=Slgw.S(ilijst(i)).data.X;
end

function x=getcomponent(nm)
global compnames
i=strmatch(lower(nm),{compnames.name},'exact')
if isempty(i)
	error('componentnaam gevraagd, maar onbekend')
end
x=compnames(i).data;

function setcomponent(nm,x)
global compnames
i=strmatch(lower(nm),{compnames.naam},'exact');
if isempty(i)
	compnames(end+1).naam=nm;
	compnames(end).data=x;
else
	compnames(i).data=x;
end

function cmds=prepcmds(cmdlist)
% PREPCMDS - Voorbereiden van mogelijke commando's (ivm afkortingen)

%!!!!!niet klaar!!!

if ~exist('cmdlist','var')|isempty(cmdlist)
	cmdlist={'*set','/prep7','/vscale','/post1','/sol','/go','/pmeth'	...
		,'/nopr','/triad','/replot','/title','/units','/show'	...
		,'k','lstr','larc','rectng','pcirc','aovl','v','flst','fitem'	...
		,'vadd','vsbv','keyw','et','mptemp','mpdata','cm'	...
		,'vsel','cmsel','vatt','cmdele','lsel','lesize','mshape'	...
		,'mshkey','chkmsh','vmesh','da','finish','magsolv'	...
		,'allsel','plvect','etable','pretab','save','aplot'	...
		,'smrt','tunif','antype','trnopt','lumpm','time','outres'	...
		,'nsubst','solve'	...
		};
end
cmdlist=sort(lower(cmdlist));
i=1;
cmdlistkort=cmdlist;
last='';
while i<=length(cmdlist)
	n=min(length(last),length(cmdlist));
	i=i+1;
end
cmds=cmdlist;
