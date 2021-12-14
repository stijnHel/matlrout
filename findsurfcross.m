function [X,d,iS,Xn]=findsurfcross(S,X0in,Xrin,Xoffset,Rrotate)
%FINDSURFCORSS - Zoekt naar doorsnijding van oppervlak door lijn
%   [X,d,iS,Xn]=findsurfcross(S,X0,Xr[,Xoffset,Rrotate])
%       Xoffset and Rrotate are related to the surfaces, but the
%       calculations are done based on moving and rotating the rays.
%
% ?zin van Xn laten aanduiden of dit naar binnen of buiten volume gaat?

X=[];
d=inf;
iS=0;
EPS=1e-12;
X0=X0in(:);
Xr=Xrin(:);
bTranslate=nargin>3&&~isempty(Xoffset);
bRotate=nargin>4&&~isempty(Rrotate);
if bTranslate
	Xoffset=Xoffset(:);
	X0=X0-Xoffset;
end
if bRotate
	X0=Rrotate'*X0;
	Xr=Rrotate'*Xr;
end

for i=1:length(S)
	p=[];
	fn=fieldnames(S(i).D);
	switch S(i).type
	case 'surf'
		Xn=S(i).D.norm(:)';
		if abs(Xn*Xr)>EPS
			p=(S(i).D.a-Xn*X0)/(Xn*Xr);
		end
		fn=setdiff(fn,{'norm','a'});
	case 'sphere'
		DX=X0-S(i).D.x0';
		a=sum(Xr.^2);
		b2=-sum(DX'*Xr);
		c=sum(DX.^2)-S(i).D.r^2;
		pD=b2^2-a*c;
		if pD>0	% (geen ==0, anders toch enkel "rakende reflectie")
			p=[b2-sqrt(pD) b2+sqrt(pD)]/a;
		end
		fn=setdiff(fn,{'x0','r'});
	case 'cyl'
		%http://geomalgorithms.com/a07-_distance.html
		if isfield(S(i).D,'x0')
			x0=S(i).D.x0;
			fn=setdiff(fn,'x0');
		else
			x0=[0;0;0];
		end
		v=S(i).D.dir;
		b=v'*Xr;
		if abs(b)>1-1e-14
			% parallel ==> no crossing (on or off the surface - assuming off)
		else
			% check if rays cross the cilinder
			dX=X0-x0(:);
			a=Xr'*dX;
			c=v'*dX;
			dR=dX+((b*c-a)*Xr-(c-b*a)*v)/(1-b^2);
			r=sqrt(dR'*dR);
			if r<=S(i).D.r	% otherwise no crossing
				% How far can this be simplified?
				G=c*v-dX;
				H=Xr-b*v;
				g=sum(G.^2);
				h=sum(H.^2);
				k=sum(G.*H);
				p=(k+[-1 1]*sqrt(k^2-(g-S(i).D.r^2)*h))/h;
			end
		end
		
		fn=setdiff(fn,{'r','dir'});
	case 'Xcyl'
		if isfield(S(i).D,'x0')
			DX=X0(2:3)-S(i).D.x0';
		else
			DX=X0(2:3);
		end
		a=sum(Xr(2:3).^2);
		b2=-sum(DX'*Xr(2:3));
		c=sum(DX.^2)-S(i).D.r^2;
		pD=b2^2-a*c;
		if pD>0	% (geen ==0, anders toch enkel "rakende reflectie")
			p=[b2-sqrt(pD) b2+sqrt(pD)]/a;
		end
		fn=setdiff(fn,{'x0','r'});
	case 'Ycyl'
		if isfield(S(i).D,'x0')
			DX=X0([1 3])-S(i).D.x0';
		else
			DX=X0([1 3]);
		end
		a=sum(Xr([1 3]).^2);
		b2=-sum(DX'*Xr([1 3]));
		c=sum(DX.^2)-S(i).D.r^2;
		pD=b2^2-a*c;
		if pD>0	% (geen ==0, anders toch enkel "rakende reflectie")
			p=[b2-sqrt(pD) b2+sqrt(pD)]/a;
		end
		fn=setdiff(fn,{'x0','r'});
	case 'Zcyl'
		if isfield(S(i).D,'x0')
			DX=X0(1:2)-S(i).D.x0';
		else
			DX=X0(1:2);
		end
		a=sum(Xr(1:2).^2);
		b2=-sum(DX'*Xr(1:2));
		c=sum(DX.^2)-S(i).D.r^2;
		pD=b2^2-a*c;
		if pD>0	% (geen ==0, anders toch enkel "rakende reflectie")
			p=[b2-sqrt(pD) b2+sqrt(pD)]/a;
		end
		fn=setdiff(fn,{'x0','r'});
	otherwise
		error('Onbekend type oppervlak (%s)',S(i).type)
	end
	p(p<=0)=[];
	j=1;
	if ~isempty(p)
		X1=X0(:,ones(1,length(p)))+Xr*p;
	end
	while ~isempty(p)&&j<=length(fn)
		switch fn{j}
		case 'Rmax'
			r=sqrt(sum(bsxfun(@minus,X1,S(i).D.Rmax{1}).^2));
			p(r>S(i).D.Rmax{2})=-1;
		case 'R1Dmax'
			idx=S(i).D.R1Dmax{1};
			rMax=S(i).D.R1Dmax{2};
			r=sqrt(sum(X1(idx,:).^2));
			p(r>rMax)=-1;
		case 'yzRmax'
			for k=1:length(p)
				r=sqrt(X1(2:3,k)'*X1(2:3,k));
				if r>S(i).D.yzRmax
					p(k)=-1;
				end
			end
		case 'Dmax'	% distance limit in certain direction
			A=S(i).D.Dmax{1};
			aMin=S(i).D.Dmax{2};
			aMax=S(i).D.Dmax{3};
			a=A'*X1;
			p(a<aMin|a>aMax)=-1;
		case 'xlim'
			p(X1(1,:)<S(i).D.xlim(1)|X1(1,:)>S(i).D.xlim(2))=-1;
		case 'ylim'
			p(X1(2,:)<S(i).D.ylim(1)|X1(2,:)>S(i).D.ylim(2))=-1;
		case 'zlim'
			p(X1(3,:)<S(i).D.zlim(1)|X1(3,:)>S(i).D.zlim(2))=-1;
		case 'polygone'
			polygon=S(i).D.polygone;
			[~,imn]=min(max(polygon,[],2)-min(polygon,[],2));
			switch imn
			case 1
				i1=2;
				i2=3;
			case 2
				i1=1;
				i2=3;
			case 3
				i1=1;
				i2=2;
			end
			for k=1:length(p)
				isIn=inpolygon(X1(i1,k),X1(i2,k),polygon(i1,:),polygon(i2,:));
				if isIn==0
					p(k)=-1;
				end
			end
		case 'RZ'	% only for drawing
		otherwise
			warning('gegeven "%s" is niet voorzien.',fn{j})
		end
		X1(:,p<0)=[];
		p(p<0)=[];
		j=j+1;
	end % while ~
	if ~isempty(p)
		if isscalar(p)
			j=1;
		else
			[p,j]=min(p);
		end
		if p<d
			d=p;
			X=X1(:,j);
			iS=i;
		end
	end		% ~empty p
end		% for i
if nargout>3
	if isempty(X)
		Xn=[];
	else
		switch S(iS).type
		case 'surf'
			Xn=S(iS).D.norm(:);
		case 'sphere'
			Xn=X-S(iS).D.x0';
			Xn=Xn/sqrt(Xn'*Xn);
		case 'cyl'
			if isfield(S(iS).D,'x0')
				x0=S(iS).D.x0;
			else
				x0=[0;0;0];
			end
			v=S(iS).D.dir;
			Xn=X-x0-((X-x0)'*v)*v;
			Xn=Xn/sqrt(Xn'*Xn);
		case 'Xcyl'
			Xn=[0;X(2:3)];
			Xn=Xn/sqrt(Xn'*Xn);
		case 'Ycyl'
			Xn=[X(1);0;X(3)];
			Xn=Xn/sqrt(Xn'*Xn);
		case 'Zcyl'
			Xn=[X(1:2);0];
			Xn=Xn/sqrt(Xn'*Xn);
		end
	end
end
if ~isempty(X)
	if bRotate
		X=Rrotate*X;
		if nargout>3
			Xn=Rrotate*Xn;
		end
	end
	if bTranslate
		X=X+Xoffset;
	end
end
