function [XY,V,XYZ,Z1]=ProjGPS2XY(P,varargin)
%ProjGPS2XY - Project GPS-coordinates to flat surface
%         [XY,V,XYZ,Z1]=ProjGPS2XY(P,...)
%                P: coordinates ([t lat long]) - angles in degrees
%                   or output of ReadLogGPS
%
%                XY : flat coordinates (projected to a plane) [m]
%                     no standard geographic coordinate system used(!)
%                     XY = [North East] (!)
%                V  : speed [m/s]
%                XYZ: 3D coordinates [m]
%                Z1 : projection base point
%         options:
%              bSphere: spherical earth (default false)
%              Z1 : force base point (default is middle point)
%              bNoFiltV
%              iFiltV
%
% see also ReadLogGPS, ReadNMEA

if isstruct(P)
	P=P.P;
end

[bSphere]=false;
[bOld]=false;
Z1=[];
[bNoFiltV]=false;
iFiltV=[];	% number of points to filter

Req=6378140;
Rpol=6356760;

if ~isempty(varargin)
	setoptions({'bSphere','Z1','bNoFiltV','iFiltV','Req','Rpol'},varargin{:})
end

if size(P,2)==2
	Lat=P(:,1);		% (phi)
	Long=P(:,2);	% (lambda)
	t=(0:length(Lat)-1)';
else
	t=P(:,1);
	Lat=P(:,2);		% (phi)
	Long=P(:,3);	% (lambda)
end
if abs(mean(Lat)-5.3)<3&&abs(mean(Long)-50.9)<3
	warning('Mean latitude = %4.1f and mean longitude = %4.1f - is this wanted (Belgium is Lat<->Long)'	...
		,mean(Lat),mean(Long))
end
if size(P,2)>3
	H=P(:,4);
else
	H=[];
end
if bSphere
	Rearth=(Req+Rpol)/2;
	if ~isempty(H)
		Rearth=Rearth+H(:,[1 1 1]);
	end
	XYZ=[cosd(Lat).*cosd(Long),cosd(Lat).*sind(Long),sind(Lat)].*Rearth;
elseif bOld
	if ~isempty(H)
		Req=Req+H;
		Rpol=Rpol+H;
	end
	XYZ=[Req.*cosd(Lat).*cosd(Long),Req.*cosd(Lat).*sind(Long),Rpol.*sind(Lat)];
else
	XYZ = CalcXYZ(Lat,Long,H);
end

% Project to surface through the middle point
if isempty(Z1)
	if any(isnan(Lat))
		if all(isnan(Lat))
			error('All NaN''s!')
		end
		B=~isnan(Lat);
		Z1=[mean(Lat(B)),mean(Long(B))];
	else
		%Z1=mean(XYZ,1);
		Z1=[mean(Lat),mean(Long)];
	end
end
if length(Z1)==3&&any(abs(Z1)>360)
	XYZ0 = Z1(:)';
	XY0=sqrt(Z1(1)^2+Z1(2)^2);
	if Z1(3)*0.001>XY0	% north pole
		Xe=[0 1 0];
		Xn=[-1 0 0];
	elseif Z1(3)*-0.001>XY0	% south pole
		Xe=[0 1 0];
		Xn=[-1 0 0];
	else
		%(The rest should be able to use this part too!!!)
		Z1=Z1/sqrt(Z1*Z1');
		Xe=[-Z1(2),Z1(1),0];	% orthogonal to Z1 in XY-plane
		rX=sqrt(Xe*Xe');
		Xe=Xe/rX;
		Xn=cross(Z1,Xe);
	end
elseif abs(Z1(1))<89.9
	%!possibly non spherical XYZ-calculation, but projection based on spherical configuration?!
	XYZ0=CalcXYZ(Z1(1),Z1(2),[]);
	sLat=sind(Z1(1));
	sLong=sind(Z1(2));
	cLat=cosd(Z1(1));
	cLong=cosd(Z1(2));
	Xn=[-sLat.*cLong, -sLat.*sLong, cLat];
	Xe=[-sLong,       cLong,        0];
	%N=-sind(Lat).*cosd(Long).*dP(:,1) - sind(Lat).*sind(Long).*dP(:,2) + cosd(Lat).*dP(:,3);	% is this OK???
	%	% shouldn't dP be transformed with fixed vector to (N,E)?
	%E=-sind(Long).*dP(:,1)            + cosd(Long).*dP(:,2);
elseif Z1(1)>0	% north pole
	XYZ0=[Rpol,0,0];
	Xe=[1 0 0];
	Xn=[0 1 0];
else	% south pole
	XYZ0=[-Rpol,0,0];
	Xe=[0 1 0];
	Xn=[-1 0 0];
end
dP=bsxfun(@minus,XYZ,XYZ0);
XY=dP*[Xn' Xe'];	% ? first column north (to be consistent with angle based (on normally used)
%XY=XYZn(:,1:2);

if nargout>1
	dXY=diff(XY);
	dt=diff(t);
	if t(1)>7e5&&t(1)<8e5	% probably "matlab time" --> days
		dt=dt*86400;
	end
	if any(dt<=0)
		if ~all(dt==0)
			warning('Non-strictly positive dt''s!')
		end
		dt(dt<=0) = 1;
	end
	mdt=median(dt);
	V=sqrt(sum(dXY.^2,2))./dt;	% vehicle speed
	if ~bNoFiltV&&(length(iFiltV)>1||mdt<0.5)
		if isempty(iFiltV)
			iFiltV=round(1/mdt);
		end
		V=conv(V,ones(iFiltV,1)/iFiltV);
		i1=ceil(iFiltV/2);
		V=V(i1:i1+length(t)-2);	% keep same length as unfiltered V
	end
end

function XYZ = CalcXYZ(Lat,Long,H)
a=6378137.0;
f=1/298.257223563;

% excentricity e (squared) 
e2 = 2*f - f^2;

N = a ./ sqrt(1 - e2 .* sind(Lat).^2);
if ~isempty(H)
	N=N+H;
end
R=N.*cosd(Lat);
XYZ = [R.*cosd(Long), R.*sind(Long), (N-e2.*N).*sind(Lat)];
