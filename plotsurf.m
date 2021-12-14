function lUit=plotsurf(S,R,Xoffset)
%PLOTSURF - Plot oppervlakken, gemaakt voor oppervlakken van lenzen
%   Dit is maar een snelsnel-hulpprogrammatje

if ~exist('R','var')|isempty(R)
	R=eye(3);
else
	R=R';
end
if ~exist('Xoffset','var')|isempty(Xoffset)
	Xoffset=[0 0 0];
end

fn=fieldnames(S);
if ~isequal(fn,{'type';'D'})
	% misschien een definitie van een lens?
	S=lenssurf(S);
end
l=[];

for i=1:length(S)
	switch S(i).type
	case 'sphere'
		x0=S(i).D.x0;
		r=S(i).D.r;
		xl=S(i).D.xlim;
		Rm=S(i).D.yzRmax;
		rr=Rm/r;
		if rr>1-eps*10
			phi=pi/2;	% of verder?
		else
			phi=asin(rr);
		end
		% nog meer doen met xlim?
		if all(xl<x0(1))
			PHI=pi-phi:phi/10:pi+phi;
		else
			PHI=-phi:phi/10:phi;
		end
		X=bsxfun(@plus,R*[x0(1)+r*cos(PHI);x0(2)+r*sin(PHI);PHI*0],Xoffset);
		l=line(X(1,:),X(2,:),X(3,:));
		phi=0:pi/20:2*pi+1e-10;
		%l(2)=line(phi*0+Xoffset(1),Rm*cos(phi)+Xoffset(2),Rm*sin(phi)+Xoffset(3));
		X=bsxfun(@plus,R*[phi*0;Rm*cos(phi);Rm*sin(phi)],Xoffset);
		l(2)=line(X(1,:),X(2,:),X(3,:));
	case 'surf'
		if isfield(S(i).D,'yzRmax')
			phi=0:pi/20:2.00001*pi;
			X=S(i).D.yzRmax*[phi*0;cos(phi);sin(phi)];
			norm=S(i).D.norm;
			if norm(1)==0
				error('Onmogelijke combinatie van definitie en begrenzing van surf')
			end
			X(1,:)=(S(i).D.a-norm(2)*X(2,:)-norm(3)*X(3,:))/norm(1);
			X=R*X;
			l=line(X(1,:)+Xoffset(1),X(2,:)+Xoffset(2),X(3,:)+Xoffset(3));
		elseif isfield(S(i).D,'polygone')
			P=R*S(i).D.polygone;
			l=line(P(1,[1:end 1])+Xoffset(1),P(2,[1:end 1])+Xoffset(2),P(3,[1:end 1])+Xoffset(3));
		end
	case 'Xcyl'
	end
end
if nargout
	lUit=l;
end
