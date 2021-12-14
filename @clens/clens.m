function c=clens(typ,varargin)
%CLENS/CLENS - Maakt een lens-object
%    L=clens(typ,...)
%  types :
%     'sferisch': lens bestaande uit twee bolvormige of vlakke oppervlakken
%          en evenuteel een cylindrische buitenrand
%          data : [D,f,d,nlens] of [D,r1,r2,d,nlens]
%              of zelfde maar dan in aparte argumenten
%     'prisma'
%          data : grondvlak (coordinaten in kolommen),
%              ribbe (lengte of richting), nlens
%     'bol'
%          data : r, nlens
%     'cilindrisch' : gelijkaardig aan sferisch (dus 2 aparte cirkels), maar
%            cilindrisch ipv sferisch
%          data : dir (letter X, Y of Z) of richting
%              nlens, D (breedte), d (dikte), l (lengte),	...
%              en ofwel f, ofwel r1, r2
%     'cilinder' : cilinder
%          data : dir (letter X, Y of Z) of richting
%              nlens, r (straal), l (lengte), optioneel d (voor "afgesneden
%                  cilinder")
%     'slit' : no lens but an rectangular opening
%          data: width, height
%          foreseen - but not implemented!
%     'hole' : similar to slit, but circular opening

nlens=1.51;
inp=varargin;
S=[];
if nargin==0
	%!!default lens
	typ='sferisch';
	f=0.04;
	r1=2*f*(nlens-1);
	L=struct('D',0.025,'r1',r1,'r2',r1,'d',0,'f',f);
elseif ~ischar(typ)
	if ~isstruct(typ)||~isfield(typ,'type')||~isfield(typ,'D')
		error('Wrong type-input!')
	end
	S=typ;
	typ='free';
	L=struct();
	if nargin>1
		if ~isempty(varargin{1})
			nlens=varargin{1};
		end
		if nargin>2
			L=varargin{2};
		end
	end
else
	switch typ
	case 'sferisch'
		if isempty(inp)
			inp={.025,0.04,0,nlens};
		end
		switch length(inp)
		case 1
			lens=inp{1};
			switch length(lens)
			case 4
				D=lens(1);
				f=lens(2);
				d=lens(3);
				nlens=lens(4);
				r1=2*f*(nlens-1);
				r2=r1;
			case 5
				D=lens(1);
				r1=lens(2);
				r2=lens(3);
				d=lens(4);
				nlens=lens(5);
				f=1/(1/r1+1/r2)/(nlens-1);
			otherwise
				error('Verkeerde specificatie van een normale lens')
			end
		case 4
			D=inp{1};
			f=inp{2};
			d=inp{3};
			nlens=inp{4};
			if ischar(nlens)
				nlens=BrekingsIndex(nlens);
			end
			r1=2*f*(nlens-1);
			r2=r1;
		case 5
			D=inp{1};
			r1=inp{2};
			r2=inp{3};
			d=inp{4};
			nlens=inp{5};
			if ischar(nlens)
				nlens=BrekingsIndex(nlens);
			end
			if isinf(r1)&&isinf(r2)
				f=inf;
			else
				f=1/(1/r1+1/r2)/(nlens-1);
			end
		otherwise
			error('Verkeerde specificatie van een normale lens')
		end
		if abs(r1)<D/2||abs(r2)<D/2
			warning('Impossible lens!!! (r1=%g,r2=%g,r(D)=%g',r1,r2,D/2)
		end
		L=struct('D',D,'r1',r1,'r2',r2,'d',d,'f',f);
	case 'prisma'
		if isempty(inp)
			inp={[0 0.1 0;0 0 0.1;0 0 0],.1,nlens};
		end
		if length(inp)==3
			grondvlak=inp{1};
			if size(grondvlak,2)<3
				error('Minimaal 3 punten opgeven als grondvlak')
			end
			if size(grondvlak,1)==2
				grondvlak(3,1)=0;	% maak 3D, grondvlak in XY-vlak
			elseif size(grondvlak,2)>3
				% kontrole
				norm=cross(grondvlak(:,2)-grondvlak(:,1),grondvlak(:,3)-grondvlak(:,2))';
				lim=max(abs(norm(:)))*1e-10;
				a=norm*grondvlak(:,1);
				for i=4:size(grondvlak,2)
					if abs(norm*grondvlak(:,i)-a)>lim
						warning('Niet alle punten van grondvlak in zelfde vlak, mogelijk lopen sommige routines fout!')
					end
				end
			end
			ribbe=inp{2};
			nlens=inp{3};
		else
			error('Verkeerde specificatie van een prisma')
		end
		if length(ribbe)==1 % lengte, ribben loodrecht op eerste twee ribben van grondvlak
			norm=cross(grondvlak(:,2)-grondvlak(:,1),grondvlak(:,3)-grondvlak(:,2));
			norm=norm/sqrt(norm'*norm);
			ribbe=ribbe*norm;
		elseif isequal(size(ribbe),[1 3])
			ribbe=ribbe';
		elseif size(ribbe,2)~=1&&size(ribbe,2)~=size(grondvlak,2)
			error('Verkeerde specificatie van de ribbe van een prisma')
		end
		L=struct('grondvlak',grondvlak,'ribbe',ribbe);
	case 'bol'
		if isempty(inp)
			r=0.1;
		else
			r=inp{1};
			if length(inp)>1
				nlens=inp{2};
			end
		end
		L=struct('r',r,'n',nlens);	% !!!!!!
	case 'cilindrisch'  % axes
		if isempty(inp)
			inp={'Z',nlens,0.05,0.001,0.2,0.3};
		end
		dirC=inp{1};
		% conversion to orientations:
		%      Cdir : orientation of centerline
		%      Mdir : main direction
		if ischar(dirC)
			switch upper(dirC)
				case 'X'
					Cdir=[1;0;0];
					Mdir=[0;1;0];
				case 'Y'
					Cdir=[0;1;0];
					Mdir=[0;0;1];
				case 'Z'
					Cdir=[0;0;1];
					Mdir=[0;1;0];
				otherwise
					error('impossible direction of cylinder')
			end
		elseif iscell(dirC)
			Cdir=dirC{1};
			Mdir=dirC{2};
		elseif min(size(dirC))==1
			Cdir=dirC(:);
			Cdir=Cdir/sqrt(Cdir'*Cdir);
			if abs(Cdir(1))<0.1
				Mdir=cross(Cdir,[1;0;0]);
			else
				Mdir=cross(Cdir,[0;0;1]);
			end
		else
			if all(size(dirC)==[3 2])
				Cdir=dirC(:,1);
				Mdir=dirC(:,2);
			elseif all(size(dirC)==[2 3])
				Cdir=dirC(1,:)';
				Mdir=dirC(2,:)';
			else
				error('wrong definition of direction of cylinder')
			end
		end
		Mdir=Mdir/sqrt(Mdir'*Mdir);
		nlens=inp{2};
		D=inp{3};
		d=inp{4};
		l=inp{5};
		if length(inp)==6
			f=inp{6};
			r1=2*f*(nlens-1);
			r2=r1;
		elseif length(inp)==7
			r1=inp{6};
			r2=inp{7};
			if isinf(r1)&&isinf(r2)
				f=inf;
			else
				f=1/(1/r1+1/r2)/(nlens-1);
			end
		else
			error('Verkeerde specificatie van een cilindrische lens')
		end
		L=struct('Cdir',Cdir,'Mdir',Mdir,'D',D,'r1',r1,'r2',r2,'d',d,'f',f,'l',l);
	case 'cilinder'
		if isempty(inp)
			inp={'Z',nlens,0.01,0.01};
		end
		dirC=inp{1};
		% conversion to orientations:
		%      Cdir : orientation of centerline
		if ischar(dirC)
			switch upper(dirC)
				case 'X'
					Cdir=[1;0;0];
				case 'Y'
					Cdir=[0;1;0];
				case 'Z'
					Cdir=[0;0;1];
				otherwise
					error('impossible direction of cylinder')
			end
		elseif iscell(dirC)
			Cdir=dirC{1};
		elseif min(size(dirC))==1
			Cdir=dirC(:);
			Cdir=Cdir/sqrt(Cdir'*Cdir);	% make sure it's a unit vector
		else
			if all(size(dirC)==[3 2])
				Cdir=dirC(:,1);
			elseif all(size(dirC)==[2 3])
				Cdir=dirC(1,:)';
			else
				error('wrong definition of direction of cylinder')
			end
		end
		nlens=inp{2};
		r=inp{3};
		l=inp{4};
		if length(inp)>4
			d=inp{5};
		else
			d=0;
		end
		L=struct('Cdir',Cdir,'r',r,'l',l,'d',d);
	case 'slit'
		warning('Not yet implemented!!')
		if length(inp)==1
			width=inp{1}(1);
			height=inp{1}(2);
		else
			width=inp{1};
			height=inp{2};
		end
		L=struct('width',width,'height',height);
		nlens=0;
	case 'hole'
		warning('Not yet implemented!!')
		L=struct('radius',inp{1});
		nlens=0;
	otherwise
		error('Onbekend type lens')
	end
end
if ischar(nlens)
	nlens=BrekingsIndex(nlens);
end
c=class(struct('type',typ,'n',nlens,'D',L,'S',S),'clens');
if isempty(S)
	c.S=surfaces(c);
end

function nlens=BrekingsIndex(materiaal)
switch lower(materiaal)
	case 'glas'
		nlens=1.515;
	case 'licht flintglas'
		nlens=1.515;
	case 'zwaar flintglas'
		nlens=1.65;
	case 'zeer zwaar flintglas'
		nlens=1.88;
	case 'water'
		nlens=1.335;
	case 'diamant'
		nlens=2.42;
	case 'plexiglas'
		nlens=1.49;
	otherwise
		warning('!!onbekend soort - standaard glas waarde (1.515) wordt genomen!!')
		nlens=1.515;
end
