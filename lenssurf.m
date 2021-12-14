function S=lenssurf(L)
%LENSSURF - Bepaalt oppervlakken van lenzen

if length(L)>1
	S=cell(size(L));
	for i=1:numel(L)
		S{i}=lenssurf(L(i));
	end
	return
end
if ~isfield(L,'type')|strcmp(L.type,'sferisch')
	% gewone lens
	x=-L.d/2;
	xl1=x;
	if isinf(L.r1)
		D=struct('norm',[1 0 0],'a',x,'yzRmax',L.D/2);
		S1=struct('type','surf','D',D);
	elseif L.r1>0
		x0=x+sqrt(L.r1^2-L.D^2/4)-L.r1;
		D=struct('r',L.r1,'x0',[x0+L.r1 0 0],'yzRmax',L.D/2,'xlim',[x0-1e-14*L.r1 0]);
		S1=struct('type','sphere','D',D);
	elseif L.r1<0
		x0=x;
		xl1=xl1+L.r1+sqrt(L.r1^2-L.D^2/4);
		D=struct('r',-L.r1,'x0',[x0+L.r1 0 0],'yzRmax',L.D/2,'xlim',[xl1+1e-14*L.r1 x0-1e-14*L.r1]);
		S1=struct('type','sphere','D',D);
	else
		error('Stralen = 0 kan niet')
	end
	x=L.d/2;
	xl2=x;
	if isinf(L.r2)
		D=struct('norm',[1 0 0],'a',x,'yzRmax',L.D/2);
		S2=struct('type','surf','D',D);
	elseif L.r2>0
		x0=x-sqrt(L.r2^2-L.D^2/4)+L.r2;
		D=struct('r',L.r2,'x0',[x0-L.r2 0 0],'yzRmax',L.D/2,'xlim',[0 x0+1e-14*L.r2]);
		S2=struct('type','sphere','D',D);
	elseif L.r2<0
		x0=x;
		xl2=xl2-L.r2-sqrt(L.r2^2-L.D^2/4);
		D=struct('r',-L.r2,'x0',[x0-L.r2 0 0],'yzRmax',L.D/2,'xlim',[x0+1e-14*L.r2 xl2-1e-14*L.r2]);
		S2=struct('type','sphere','D',D);
	else
		error('Stralen = 0 kan niet')
	end
	S=[S1 S2];
	if xl2>xl1
		D=struct('r',L.D/2,'xlim',[xl1 xl2]);
		S(end+1)=struct('type','Xcyl','D',D);
	end
else
	switch L.type
	case 'prisma'
		% !!rekening houden met mogelijkheid tot reductie van vlakken of lijnen
		%  bij opgave van eindvlak
		%  ?testen of norm niet evenwijdig is met grondvlak?
		grondvlak=L.grondvlak;
		ribbe=L.ribbe;
		norm=cross(grondvlak(:,2)-grondvlak(:,1),grondvlak(:,3)-grondvlak(:,2))';
		norm=norm/sqrt(norm*norm');
		a=norm*grondvlak(:,1);
		D=struct('norm',norm,'a',a,'polygone',L.grondvlak);
		S=struct('type','surf','D',D);
		S=S(ones(1,2+size(grondvlak,2)));
		if size(ribbe,2)==1
			eindvlak=L.grondvlak+ribbe(:,ones(1,size(grondvlak,2)));
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
	% toekomst : bol, ...
	%    ?complexere vormen?
	otherwise
		error('Onbekend type lens')
	end
end
