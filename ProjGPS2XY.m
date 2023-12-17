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

persistent GEOG

if isempty(GEOG)
	GEOG = CreateGeography();
end

if isstruct(P)
	P=P.P;
end

[bSphere]=false;
Z1=[];
[bNoFiltV]=false;
iFiltV=[];	% number of points to filter
[bInverse] = false;	% for inverse calculation (XY-->coor)

Req=6378140;	% Currently only used for calculating average radius!!
Rpol=6356760;

if ~isempty(varargin)
	setoptions({'bSphere','Z1','bNoFiltV','iFiltV','Req','Rpol','bInverse'},varargin{:})
end

if bInverse
	if isempty(Z1)
		error('For inverse calculation, reference coordinates must be supplied!')
	end
	[XY,V] = GEOG.InverseProj(P,Z1);
	return
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
if isempty(Z1)	% Project to surface through the middle point
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
if bSphere
	Rearth=(Req+Rpol)/2;
	if ~isempty(H)
		Rearth=Rearth+H(:,[1 1 1]);
	end
	XYZ0 = [cosd(Z1(1)).*cosd(Z1(2)),cosd(Z1(1)).*sind(Z1(2)),sind(Z1(1))].*Rearth;
	XYZ = [cosd(Lat).*cosd(Long),cosd(Lat).*sind(Long),sind(Lat)].*Rearth;
else
	XYZ0 = GEOG.CalcXYZ(Z1(1),Z1(2),0);
	XYZ = GEOG.CalcXYZ(Lat,Long,H);
end

[Xe,Xn] = GEOG.GetRefFrame(Z1);
dP = XYZ-XYZ0;
XY = dP*[Xn' Xe'];	% ? first column north (to be consistent with angle based (on normally used)
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
