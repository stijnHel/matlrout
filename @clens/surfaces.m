function S=surfaces(L)
%CLENS/SURFACES - Bepaalt oppervlakken van lenzen
%      S=surfaces(L)
%
%  Normally only used internally (during lens-creation)

if length(L)>1
	S=cell(size(L));
	for i=1:numel(L)
		S{i}=surfaces(L(i));
	end
	return
end
switch L.type
	case 'sferisch'
		% gewone lens
		x=-L.D.d/2;
		xl1=x;
		if isinf(L.D.r1)
			D=struct('norm',[1 0 0],'a',x,'yzRmax',L.D.D/2);
			S1=struct('type','surf','D',D);
		elseif L.D.r1>0
			x0=x+sqrt(L.D.r1^2-L.D.D^2/4)-L.D.r1;
			D=struct('r',L.D.r1,'x0',[x0+L.D.r1 0 0],'yzRmax',L.D.D/2,'xlim',[x0-1e-14*L.D.r1 0]);
			S1=struct('type','sphere','D',D);
		elseif L.D.r1<0
			x0=x;
			xl1=xl1+L.D.r1+sqrt(L.D.r1^2-L.D.D^2/4);
			D=struct('r',-L.D.r1,'x0',[x0+L.D.r1 0 0],'yzRmax',L.D.D/2,'xlim',[xl1+1e-14*L.D.r1 x0-1e-14*L.D.r1]);
			S1=struct('type','sphere','D',D);
		else
			error('Stralen = 0 kan niet')
		end
		x=L.D.d/2;
		xl2=x;
		if isinf(L.D.r2)
			D=struct('norm',[1 0 0],'a',x,'yzRmax',L.D.D/2);
			S2=struct('type','surf','D',D);
		elseif L.D.r2>0
			x0=x-sqrt(L.D.r2^2-L.D.D^2/4)+L.D.r2;
			D=struct('r',L.D.r2,'x0',[x0-L.D.r2 0 0],'yzRmax',L.D.D/2,'xlim',[0 x0+1e-14*L.D.r2]);
			S2=struct('type','sphere','D',D);
		elseif L.D.r2<0
			x0=x;
			xl2=xl2-L.D.r2-sqrt(L.D.r2^2-L.D.D^2/4);
			D=struct('r',-L.D.r2,'x0',[x0-L.D.r2 0 0],'yzRmax',L.D.D/2,'xlim',[x0+1e-14*L.D.r2 xl2-1e-14*L.D.r2]);
			S2=struct('type','sphere','D',D);
		else
			error('Stralen = 0 kan niet')
		end
		S=[S1 S2];
		if xl2>xl1
			D=struct('r',L.D.D/2,'xlim',[xl1 xl2]);
			S(end+1)=struct('type','Xcyl','D',D);
		end
	case 'prisma'
		% !!rekening houden met mogelijkheid tot reductie van vlakken of lijnen
		%  bij opgave van eindvlak
		%  ?testen of norm niet evenwijdig is met grondvlak?
		grondvlak=L.D.grondvlak;
		ribbe=L.D.ribbe;
		norm=cross(grondvlak(:,2)-grondvlak(:,1),grondvlak(:,3)-grondvlak(:,2))';
		norm=norm/sqrt(norm*norm');
		a=norm*grondvlak(:,1);
		D=struct('norm',norm,'a',a,'polygone',L.D.grondvlak);
		S=struct('type','surf','D',D);
		S=S(ones(1,2+size(grondvlak,2)));
		if size(ribbe,2)==1
			eindvlak=L.D.grondvlak+ribbe(:,ones(1,size(grondvlak,2)));
			S(2).D.polygone=eindvlak;
		else
			eindvlak=ribbe;
			S(2).D.polygone=eindvlak;
			norm=cross(eindvlak(:,2)-eindvlak(:,1),eindvlak(:,3)-eindvlak(:,2))';
			norm=norm/sqrt(norm*norm');
			a=norm*eindvlak(:,1);
			S(2).norm=norm;
			S(2).D.a=a;
		end
		grondvlak=grondvlak(:,[1:end 1]);
		eindvlak=eindvlak(:,[1:end 1]);
		for i=1:size(grondvlak,2)-1
			V=[grondvlak(:,[i i+1]) eindvlak(:,[i+1 i])];
			norm=cross(V(:,2)-V(:,1),V(:,3)-V(:,2))';
			norm=norm/sqrt(norm*norm');
			a=norm*V(:,1);
			S(i+2).D.norm=norm;
			S(i+2).D.a=a;
			S(i+2).D.polygone=V;
		end
	case 'bol'
		D=struct('r',L.D.r,'x0',[0 0 0]);
		S=struct('type','sphere','D',D);
	case 'cilindrisch'
		% top and bottom surface
		D=struct('norm',L.D.Cdir,'a',-L.D.l/2);	%,'yzRmax',L.D.D/2);!!!!!!!!limitatie
		S=struct('type','surf','D',{D,D});
		S(2).D.a=L.D.l/2;
		%%%%%!!!nog niet klaar!!!!
		%afhankelijk van r1 en r2 moeten 1 of twee cilindrische
		%oppervlakken gemaakt worden of slechts 1 en een vlak
		%(temporarily!) flat surface
		x=-L.D.d/2;
		xl1=x;
		if isinf(L.D.r1)
			x1=x;
			%D=struct('norm',[1 0 0],'a',x,'yzRmax',L.D.D/2);
			%S1=struct('type','surf','D',D);
		elseif L.D.r1>0
			x0=x+sqrt(L.D.r1^2-L.D.D^2/4)-L.D.r1;
			x01=x0+L.D.r1;
			xlim1=[x0-1e-14*L.D.r1 0];
		elseif L.D.r1<0
			x0=x;
			xl1=xl1+L.D.r1+sqrt(L.D.r1^2-L.D.D^2/4);
			x01=x0+L.D.r1;
			xlim=[xl1+1e-14*L.D.r1 x0-1e-14*L.D.r1];
		else
			error('Stralen = 0 kan niet')
		end
		x=L.D.d/2;
		xl2=x;
		if isinf(L.D.r2)
			x2=x;
		elseif L.D.r2>0
			x0=x-sqrt(L.D.r2^2-L.D.D^2/4)+L.D.r2;
			x02=x0-L.D.r2;
			xlim=[0 x0+1e-14*L.D.r2];
		elseif L.D.r2<0
			x0=x;
			xl2=xl2-L.D.r2-sqrt(L.D.r2^2-L.D.D^2/4);
			x02=x0-L.D.r2;
			xlim=[x0+1e-14*L.D.r2 xl2-1e-14*L.D.r2];
		else
			error('Stralen = 0 kan niet')
		end
		S(end+1).type='surf';	% temporarily
		i1=length(S);
		i2=i1+1;
		S(i2).type='surf';	% temporarily
		if isinf(L.D.r1)
			S(i1).D=struct('norm',L.D.Mdir,'a',-L.D.l);
		else
			D1=struct('x0',[x01 0],'r',abs(L.D.r1));%%%%%%%%%%%!!!!!!!!!!
		end
		%%%%%%%%%!!!!!!!!!add dependency of Mdir
		if all(L.D.Cdir(:)==[1;0;0])
			S(end+1).type='Xcyl';
			S(end).D=D;
		elseif all(L.D.Cdir(:)==[0;1;0])
			S(end+1).type='Ycyl';
			S(end).D=D;
		elseif all(L.D.Cdir(:)==[0;0;1])
			S(end+1).type='Zcyl';
			S(end).D=D;
		else
			S(end+1).type='cyl';
			S(end).D=D;
		end
		if xl2>xl1
			D=struct('r',L.D.D/2,'xlim',[xl1 xl2]);
			S(end+1)=struct('type','Xcyl','D',D);
		end
		%
		warning('niet klaar')
	case 'cilinder'
		% top and bottom surface
		if L.D.d>0	% cut of cilinder
			error('Not (yet) implemented cut of cilinder!')
		end
		a=L.D.l/2;
		Dsurf=struct('norm',L.D.Cdir,'a',-a);
		Dcyl=struct('r',L.D.r);
		S=struct('type','surf','D',{Dsurf,Dsurf,Dcyl});
		S(2).D.a=a;
		if all(abs(L.D.Cdir(:))==[1;0;0])	% (direction is not important)
			S(1).D.R1Dmax={2:3,L.D.r};
			S(2).D.R1Dmax={2:3,L.D.r};
			S(3).type='Xcyl';
			S(3).D.xlim=[-a a];
		elseif all(abs(L.D.Cdir(:))==[0;1;0])
			S(1).D.R1Dmax={[1 3],L.D.r};
			S(2).D.R1Dmax={[1 3],L.D.r};
			S(3).type='Ycyl';
			S(3).D.ylim=[-a a];
		elseif all(abs(L.D.Cdir(:))==[0;0;1])
			S(1).D.R1Dmax={1:2,L.D.r};
			S(2).D.R1Dmax={1:2,L.D.r};
			S(3).type='Zcyl';
			S(3).D.zlim=[-a a];
		else
			S(1).D.Rmax={-L.D.Cdir(:)*a,L.D.r};
			S(2).D.Rmax={ L.D.Cdir(:)*a,L.D.r};
			S(3).type='cyl';
			S(3).D.dir=L.D.Cdir;
			S(3).D.Dmax={L.D.Cdir(:),-a,a};
			S(3).D.RZ=calcV1V2_R([0;0;1],L.D.Cdir(:));
				% rotation matrix to convert Z-axis to Cdir
		end
	% toekomst : ...
	%    ?complexere vormen?
	case 'slit'
		S=struct('type','rectangle','width',L.D.width,'height',L.D.height);
	case 'hole'
		S=struct('type','circle','r',L.D.radius);
	otherwise
		error('Onbekend type lens (%s)',L.type)
	end
end
