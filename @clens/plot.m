function lUit=plot(L,R,Xoffset)
%CLENS/PLOT - Plot oppervlakken, gemaakt voor oppervlakken van lenzen
%    lUit=plot(L,R,Xoffset)
%         L : lens-object
%         R : orientatie (vector of rotatie-matrix)
%         Xoffset : positie nulpunt van lens
%   Dit is maar een snelsnel-hulpprogrammatje
%   Alles wordt 3D getekend, maar toch sterk gericht op 2D (!)

if ~exist('R','var')
	R=[];
elseif min(size(R))==1
	R=CalcRlens(R)';	%???
else
	R=R';
end
if ~exist('Xoffset','var')||isempty(Xoffset)
	Xoffset=[0 0 0];
end

S=L.S;
l=[];

% ipv met lijnen met surfaces werken? (via opties?)
faceColor=[0 0 1];
faceAlpha=0.3;

for i=1:length(S)
	bSurface=false;
	switch S(i).type
	case 'sphere'
		% this plotting only works if only one of xlim, ylim or zlim is given
		x0=S(i).D.x0;
		r=S(i).D.r;
		b=false(3,2);
		if isfield(S(i).D,'xlim')
			xl=S(i).D.xlim;
		else
			xl=[];
		end
		if isfield(S(i).D,'ylim')
			yl=S(i).D.xlim;
		else
			yl=[];
		end
		if isfield(S(i).D,'zlim')
			zl=S(i).D.zlim;
		else
			zl=[];
		end
		if isfield(S(i).D,'yzRmax')
			if isempty(xl)
				if S(i).D.yzRmax<r
					rl=sqrt(r^2-S(i).D.yzRmax^2);
					xl=x0(1)+[-rl rl];
				end
			elseif S(i).D.yzRmax<r
				rl=sqrt(r^2-S(i).D.yzRmax^2);
				if xl(1)-x0(1)<=-r
					xl(2)=min(xl(2),x0(1)-rl);
				else
					xl(1)=max(xl(1),x0(1)+rl);
				end
			end
		end		% if yzRmax
		nLimits = ~isempty(xl)+~isempty(yl)+~isempty(zl);
		if nLimits>1
			warning('Only one limitation on a sphere is implemented!')
		end
		
		% if limitation - better use another function than sphere!!!!
		%   replace sphere --> similar code but going to the right limit in
		%   case of limit!
		
		if nLimits>0
			if ~isempty(xl)
				lim=xl-x0(1);
			elseif ~isempty(yl)
				lim=yl-x0(2);
			else
				lim=zl-x0(3);
			end
			if lim(1)<=-r*(1-eps*10)
				a1=-pi/2;
			else
				a1=asin(lim(1)/r);
			end
			if lim(2)>r*(1-eps*10)
				a2=pi/2;
			else
				a2=asin(lim(2)/r);
			end
			[X,Y,Z]=limsphere(r,a1,a2,false);
			if ~isempty(xl)
				[X,Y,Z]=deal(Z,X,Y);
			elseif ~isempty(yl)
				[X,Y,Z]=deal(Y,Z,X);
			end

			if false	% by using limsphere this is not necessary anymore
				B=true(size(X));

				if ~isempty(xl)
					if xl(1)>x0(1)-r
						B(X<xl(1)-x0(1))=false;
						b(1,1)=true;
					end
					if xl(2)<x0(1)+r
						B(X>xl(2)-x0(1))=false;
						b(1,2)=true;
					end
				end
				if ~isempty(yl)
					if yl(1)>x0(2)-r
						B(Y<yl(1)-x0(2))=false;
						b(2,1)=true;
					end
					if yl(2)<x0(2)+r
						B(Y>yl(2)-x0(2))=false;
						b(2,2)=true;
					end
				end
				if ~isempty(zl)
					if zl(1)>x0(3)-r
						B(Z<zl(1)-x0(3))=false;
						b(3,1)=true;
					end
					if zl(2)<x0(3)+r
						B(Z>zl(2)-x0(3))=false;
						b(3,2)=true;
					end
				end
				if any(b(:))
					B1=any(B,2);
					B2=any(B,1);
					B=B(B1,B2);
					X=X(B1,B2);
					Y=Y(B1,B2);
					Z=Z(B1,B2);
					X(~B)=NaN;
					Y(~B)=NaN;
					Z(~B)=NaN;
				end
			end
		else
			[X,Y,Z]=sphere(50);
			X=X*r;
			Y=Y*r;
			Z=Z*r;
		end
		bSurface=true;
	case 'surf'
		if isfield(S(i).D,'yzRmax')
			phi=0:pi/20:2.00001*pi;
			X=S(i).D.yzRmax*[phi*0;cos(phi);sin(phi)];
			norm=S(i).D.norm;
			if norm(1)==0
				error('Onmogelijke combinatie van definitie en begrenzing van surf')
			end
			X(1,:)=(S(i).D.a-norm(2)*X(2,:)-norm(3)*X(3,:))/norm(1);
			if ~isempty(R)
				X=R*X;
			end
			l=line(X(1,:)+Xoffset(1),X(2,:)+Xoffset(2),X(3,:)+Xoffset(3));
		elseif isfield(S(i).D,'polygone')
			if isempty(R)
				P=S(i).D.polygone;
			else
				P=R*S(i).D.polygone;
			end
			l=line(P(1,[1:end 1])+Xoffset(1),P(2,[1:end 1])+Xoffset(2),P(3,[1:end 1])+Xoffset(3));
		end
	case 'Xcyl'
		[Y,Z,X]=cylinder(S(i).D.r,20);
		X(1,:)=S(i).D.xlim(1);
		X(2,:)=S(i).D.xlim(2);
		bSurface=true;
	case 'Ycyl'
		[X,Z,Y]=cylinder(S(i).D.r,20);
		Y(1,:)=S(i).D.ylim(1);
		Y(2,:)=S(i).D.ylim(2);
		bSurface=true;
	case 'Zcyl'
		[X,Y,Z]=cylinder(S(i).D.r,20);
		Z(1,:)=S(i).D.zlim(1);
		Z(2,:)=S(i).D.zlim(2);
		bSurface=true;
	case 'cyl'	% only works if Dmax points to the same direction as Cdir!
		[X,Y,Z]=cylinder(S(i).D.r,20);
		Z(1,:)=S(i).D.Dmax{2};
		Z(2,:)=S(i).D.Dmax{3};
		XYZ=S(i).D.RZ*[X(:)';Y(:)';Z(:)'];
		X(:)=XYZ(1,:);
		Y(:)=XYZ(2,:);
		Z(:)=XYZ(3,:);
		bSurface=true;
	otherwise
		warning('Onbekende oppervlakte (%s)',S(i).type)
	end
	if bSurface
		if isfield(S(i).D,'x0')
			X=X+x0(1);
			Y=Y+x0(2);
			Z=Z+x0(3);
		end
		if ~isempty(R)
			XYZ=[X(:),Y(:),Z(:)]*R';
			X(:)=XYZ(:,1);
			Y(:)=XYZ(:,2);
			Z(:)=XYZ(:,3);
		end
		if ~isempty(Xoffset)
			X=X+Xoffset(1);
			Y=Y+Xoffset(2);
			Z=Z+Xoffset(3);
		end
		l=surface(X,Y,Z,'facecolor',faceColor,'faceAlpha',faceAlpha);
	end
end		% for i
if nargout
	lUit=l;
end

function Rlens=CalcRlens(Lrich)
Lrich=Lrich/sqrt(sum(Lrich(:).^2));
if max(abs(Lrich(2:3)))<1e-7
	% minstens ongeveer horizontaal vlak
	if Lrich(1)>0
		Rlens=[1 0 0;0 1 0;0 0 1];
	else
		Rlens=[-1 0 0;0 -1 0;0 0 1];
	end
else
	p1=acos(Lrich(1));
	p2=atan2(-Lrich(2),Lrich(3));
	Rlens=rotxr(p2)*rotyr(p1)*rotxr(-p2);
		% eerste rotatie is meestal niet nodig, ze dient enkel om de (interne)
		%    data dicht bij de oorspronkelijke te houden.  Bij niet rotatiesymmetrische
		%    lenzen (prisma, ...) is dit echter wel belangrijk.
end

function [x,y,z] = limsphere(r,a1,a2,bClosed)	% bClosed not yet used(!)
%limsphere - Generate a sphere limited in one dimension.
%   [X,Y,Z] = limsphere(r,a1,a2,bClosed);

if nargin<4||isempty(bClosed)
	bClosed=false;
end

n1 = 20;
n2 = max(5,round(n1*(a2-a1)/pi));

% -pi <= theta <= pi is a row vector.
%  a1 <=   phi <= a2 is a column vector.
theta = (-n1:2:n1)*(pi/n1);
phi = a1+(0:n2)'*((a2-a1)/n2);
n2=n2+1;
bClose1=false;
bClose2=false;
if bClosed
	if a1>100*eps-pi/2
		phi=[0;phi];
		bClose1=true;
		n2=n2+1;
	else
		bClose1=false;
	end
	if a2<pi/2-100*eps
		phi=[phi;0];
		bClose2=true;
		n2=n2+1;
	else
		bClose2=false;
	end
end
cosphi = cos(phi);
sinphi = sin(phi);
if bClose1
	cosphi(1)=0;
	cosphi(1)=cosphi(2);
end
if bClose2
	cosphi(n2)=0;
	sinphi(n2)=sinphi(n2-1);
end
sintheta = sin(theta); sintheta(1) = 0; sintheta(n1+1) = 0;

x = r*cosphi*cos(theta);
y = r*cosphi*sintheta;
z = r*sinphi*ones(1,n1+1);
