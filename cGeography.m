classdef cGeography < handle
	%cGeography - object handling geography data
	%     c = cGeography(...)
	%
	% see also CreateGeography (easy method to keep only one instance of this object)

	% NE --> P --> NE geeft niet het oorspronkelijke resultaat!
	%   bij Long==0 ==> geen (belangrijke) fout
	%   Bij long~=0 ==> fout op N (100 km --> 2.6 m)
	%   nog geen fout gevonden

	properties (Constant)
		a = 6378137.0			% earths equatorial radius (of ellipsoid approximation)
		f = 1/298.257223563		% earths flattening
	end		% constant properties

	properties	% settings
		bStoreCoors = false
		dPosDeg = 0.05
	end		% properties (settings)

	properties
		borderPath
		countryTable
		Countries
	end

	properties
		lastZ1
		lastXYZ0
		lastXe
		lastXn
	end

	methods
		function c = cGeography(varargin)
			if isempty(c.Countries)
				pth = FindFolder('borders',0,'-bAppend');
				if ~exist(pth,'dir')
					error('Can''t find necessary data! (borders)')
				end
				c.borderPath = pth;
				c.countryTable = ReadTransTable(fullfile(pth,'countries.txt'),true);
				c.Countries = struct();
			end
			if nargin
				c.Update(varargin{:})
			end
		end		% cGeography

		function Update(c,varargin)
			if nargin==1
				return
			end
			iIn = 1;
			cntry = [];
			switch lower(varargin{iIn})
				case 'country'
					cntry = varargin{iIn+1};
					iIn = iIn+2;
			end
			if iIn<=length(varargin)
				setoptions(c,varargin{iIn:end});	% not safe! (not all properties are free changeable!)
			end
			if ~isempty(cntry)	% after setoptions to use possible settings changes
				if ischar(cntry)
					cntry = {cntry};
				end
				for i=1:length(cntry)
					c.GetCountry(cntry{i})
				end
			end
		end		% Handle all inputs of object creation

		function [com,cntry,coor,border] = FindCommunity(c,pt,cntry)
			if nargin<=2 || isempty(cntry)	% search in all (known) countries
				COUNTRIES = fieldnames(c.Countries);
			elseif ischar(cntry)	% search in a specific country
				c.GetCountry(cntry);
				COUNTRIES = {cntry};
			else
				c.GetCountry(cntry{1});
				COUNTRIES = cntry;
			end
			com = '';
			coor = [];
			border = [];
			% (This method can go wrong for communities near the border!)
			%	maybe check first if in the country?
			for i=1:length(COUNTRIES)
				cntry = COUNTRIES{i};
				C = c.Countries.(cntry);
				Dpos = sum((C.Coor-pt([2 1])).^2,2);
				[dPos1,iMin] = min(Dpos);
				if dPos1<c.dPosDeg
					if isfield(C,'Z')
						border = C.Z{iMin};
						if ~IsInArea(border,pt([2 1]))	% "look around" if not in area
							bFound = false;
							while dPos1<c.dPosDeg
								Dpos(iMin) = Inf;	% skip this commune
								[dPos1,iMin] = min(Dpos);
								border = C.Z{iMin};
								if IsInArea(border,pt([2 1]))	% "look around" if not in area
									bFound = true;
									break
								end
							end		% while looking around
							if ~bFound
								iMin = [];
							end
						end		% first guess was not right
					end		% border coordinates are available
					if ~isempty(iMin)
						com = C.Names{iMin};
						coor = C.Coor(iMin,[2 1]);
					end
				end		% close enough
				if ~isempty(com)
					break
				end
			end		% loop through COUNTRIES
			if nargout>3 && ~isempty(border)
				border = border(:,[2 1]);	% no standard which coordinate first(!?!)
			end
		end		% FindCommunity

		function Cout = GetCountry(c,cntry,bAddBorders)
			if nargin<3 || isempty(bAddBorders)
				bAddBorders = c.bStoreCoors;
			end
			bOK = false;
			for iC = 1:size(c.countryTable,1)
				if any(startsWith(c.countryTable{iC,2},cntry,'IgnoreCase',true))
					bOK = true;
					countryPath = c.countryTable{iC};
					countryName = c.countryTable{iC,2};
					if iscell(countryName)
						countryName = countryName{1};
					end
					country = countryName;
					if bAddBorders && isfield(c.Countries,country)	...
							&& ~isfield(c.Countries.(country),'Z')
						c.Countries = rmfield(c.Countries,country);
							% force recreated country-data
					end
					if isfield(c.Countries,country)
						C = c.Countries.(country);
					else
						X = ReadESRI(fullfile(c.borderPath,countryPath));
						[Z,~,Nc]=ReadESRI(X,'getCoor','all');
						Pp = zeros(length(Z),2);
						Bdouble = false(size(Nc));
						for i=1:length(Z)
							if i>1 && any(strcmp(Nc(1:i-1),Nc{i}))
								Bdouble(i) = true;
							end
							Zi = Z{i};
							if iscell(Zi)
								Zi = cat(1,Zi{:});
							end
							Pp(i,:) = mean(Zi(~isnan(Zi(:,1)),:),1);
						end
						if any(Bdouble)
							warning('Some doubles!')
							printstr(Nc(Bdouble))
						end
						C = struct('Names',{Nc},'Coor',Pp);
						if bAddBorders
							C.Z = Z;
						end
						c.Countries.(country) = C;
					end
					break
				end
			end		% for iC
			if ~bOK
				error('Error reading country!!!')
			end
			if nargout
				Cout = C;
			end
		end		% GetCountry

		function [Names,Coor,Z] = GetCountryData(c,cntry,bAddBorders)
			if nargin<3 || isempty(bAddBorders)
				bAddBorders = c.bStoreCoors || nargout>2;
			end
			X = c.GetCountry(cntry,bAddBorders);
			Names = X.Names;
			Coor = X.Coor;
			if nargout>2
				Z = X.Z;
			end
		end		%GetCountryData

		function [P,Pborder] = GetCommunity(c,cntry,com)
			X = c.GetCountry(cntry,nargout>1);
			[~,i] = FindName(X.Names,com);
			if isempty(i)
				error('Not found!')
			end
			P = X.Coor(i,:);
			if length(i)>1
				warning('Multiple communities found!')
			end
			if nargout>1
				Pborder = X.Z{i};
			end
		end		% GetCommunity

		function bInCom = PtInCommunity(c,cntry,com,pt)
			[~,P] = c.GetCommunity(cntry,com);
			P = (P-pt)*[1;1i];
			ii = find(isnan(P));
			if isempty(ii)
				bInCom = abs(sum(mod(diff(angle(P))+pi,2*pi)-pi))>1;
			else
				ii = [0;ii;length(P)+1];
				bInCom = false;
				for i=1:length(ii)-1
					if abs(sum(mod(diff(angle(P(ii(i)+1:ii(+1)-1)))+pi,2*pi)-pi))>1
						bInCom = true;
						break
					end
				end
			end
		end		% PtInCommunity

		function C = GetCountries(c)
			C = c.Countries;
		end		%GetCountries

		function [XYZ,y,z] = CalcXYZ(c,Lat,Long,H)
			%cGeography/CalcXYZ - Cartesian coordinates from angular coordinates
			%     XYZ = c.CalcXYZ(Lat,Long,H)
			%            Lat, Long in degrees, H in meters
			%            XYZ in meters
			%  coordinates taking using the ellipsoidal approximation

			e2 = 2*c.f - c.f^2;	% excentricity e (squared) 
			
			N = c.a ./ sqrt(1 - e2 .* sind(Lat).^2);
			if nargin>3 && ~isempty(H)
				N=N+H;
			end
			R=N.*cosd(Lat);
			x = R.*cosd(Long);
			y = R.*sind(Long);
			z = (1-e2)*N.*sind(Lat);
			if nargout<=1
				XYZ = [x,y,z];
			else
				XYZ = x;
			end
		end		% CalcXYZ

		function [XY,Z,XYZ] = ProjectXY(c,Lat,Long,Z1,H)
			%cGeography/ProjectXY - Project geographical coordinates to a plane
			%    [NE,Z,XYZ] = ProjectXY(c,Lat,Long,Z1,H)
			%    [NE,Z,XYZ] = ProjectXY(c,[Lat,Long],Z1,H)
			%            angles in degrees
			%            Z1 are geographical coordinates ([Lat,Long]) or
			%               cartesian coordintes ([x,y,z])
			%               can be omitted (in that case the last frame is
			%                  used - last frame is stored in object)
			%            NE : [north east] in meters
			%            Z : orthogonal distance between points and surface
			%            XYZ : cartesian (3D) coordinates

			if nargin<5
				H = [];
				if nargin<4
					Z1 = [];
					if nargin<3
						Long = [];
					end
				end
			end
			if nargin<3 || ~isequal(size(Lat),size(Long))	% P(=[Lat,Long])
				H = Z1;
				Z1 = Long;
				Long = Lat(:,2);
				Lat = Lat(:,1);
			end
			if isempty(Z1)
				XYZ0 = c.lastXYZ0;
				Xe = c.lastXe;
				Xn = c.lastXn;
			else
				if length(Z1)==3
					XYZ0 = Z1(:)';
				else
					XYZ0 = c.CalcXYZ(Z1(1),Z1(2));
				end
				c.lastXYZ0 = XYZ0;
				[Xe,Xn] = c.GetRefFrame(Z1);
			end
			XYZ = c.CalcXYZ(Lat(:),Long(:),H);
			
			dP = XYZ-XYZ0;
			XY = dP*[Xn',Xe'];	% ? first column north (to be consistent with angle based (on normally used)
			if nargout>1
				Z = dP*cross(Xe,Xn)';
			end
		end		% ProjectXY

		function [P,H] = InverseProj(c,NE,Z1)
			%InverseProj - From projected points to geographical coordinates
			%     [P,H] = c.InverseProj(NE,Z1)
			%          NE: ["north" , "east"]
			%          Z1: reference point (if not given last coordinates)
			%          P: [Latitude, Longitude]
			%          H: (not really useful) zeros (height)
			%
			%   (not completely correct!)

			% not correct calculation (spherical, not ellipsoidal)
			if nargin<3 || isempty(Z1)
				XYZ0 = c.lastXYZ0;
				Xe = c.lastXe;
				Xn = c.lastXn;
			else
				if length(Z1)==3
					XYZ0 = Z1(:)';
				else
					XYZ0 = c.CalcXYZ(Z1(1),Z1(2));
				end
				c.lastXYZ0 = XYZ0;
				[Xe,Xn] = c.GetRefFrame(Z1);
			end
			XYZ = XYZ0+NE*[Xn;Xe];
			% Force on the ellipsoid
			XYZ = ProjPtsEllipsoid(XYZ,c.a,c.f,XYZ0);
			Long = atan2d(XYZ(:,2),XYZ(:,1));
			Lat = atan2d(XYZ(:,3)/(1-c.f)^2,sqrt(sum(XYZ(:,1:2).^2,2)));
				% (1-c.f)^2 to calculate geographical coordinates
			P = [Lat,Long];
			H = zeros(size(Lat));
		end		% InverseProj

		function [Xe,Xn] = GetRefFrame(c,Z1)
			%cGeography/GetRefFrame - Returns frame for 2D projection
			%    [Xe,Xn] = GetRefFrame(Z1)
			%    [Xe,Xn] = GetRefFrame(XYZ0)

			if length(Z1)==3&&any(abs(Z1)>360)	% 3D coordinates as reference point
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
			elseif abs(Z1(1))<89.9	% normal case (long/lat & not on the poles)
				%!possibly non spherical XYZ-calculation, but projection based on spherical configuration?!
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
				%XYZ0=[0,0,c.a*(1-c.f)];
				Xe=[1 0 0];
				Xn=[0 1 0];
			else	% south pole
				%XYZ0=[0,0,c.a*(c.f-1)];
				Xe=[0 1 0];
				Xn=[-1 0 0];
			end
			c.lastZ1 = Z1;
			c.lastXe = Xe;
			c.lastXn = Xn;
		end		% GetRefFrame
		end		% methods
end		% cGeography


function [B,i,B0] = FindName(list,name)
B = startsWith(list,name,'IgnoreCase',true);
B0 = B;
if sum(B)>1
	B = strcmpi(list,name);
	nB = sum(B);
	if nB~=1
		if nB
			B0(:) = B;
		end
		B = startsWith(list,name);
		nB2 = sum(B);
		if nB2>1
			if nB2<nB
				B0(:) = B;
			end
			B = strcmp(list,name);
		end
	end
end
if nargout>1
	i = find(B);
end
end		% FindName

function bIn = IsInArea(P,pt)
if iscell(P)
	bIn = false;
	for i = 1:length(P)
		bIn = IsInArea(P{i},pt);
		if bIn
			break
		end
	end
else
	P = (P-pt)*[1;1i];
	ii = find(isnan(P));
	if isempty(ii)
		bIn = abs(sum(mod(diff(angle(P))+pi,2*pi)-pi))>1;
	else
		ii = [0;ii;length(P)+1];
		bIn = false;
		for i=1:length(ii)-1
			if abs(sum(mod(diff(angle(P(ii(i)+1:ii(+1)-1)))+pi,2*pi)-pi))>1
				bIn = true;
				break
			end
		end
	end
end
end		% IsInArea

function XYZ = ProjPtsEllipsoid(Pts,a,f,XYZ0)
%     goal: for InverseProjection, project from plane to ellipsoid
%     idea: * "scale" to sphere (enlarge Z)
%           * take normals of points
%           * find r=a
%           * "scale" back to ellipsoid

% This is not completely right! (of toch?)
%   the "unprojected" points before scaling back are not ortogonal to
%      oringal points after scaling! - of toch?

% Scale to sphere (points and reference surface)
XYZ = Pts;
XYZ(:,3) = XYZ(:,3)/(1-f);
xyz0 = XYZ0;
xyz0(3) = xyz0(3)/(1-f);	% becomes the normal to the sphere (should be...)
xyz0 = xyz0/sqrt(xyz0*xyz0');	% make unit vector

% Take normals to points and find radius(Pt + x.XYZ0) == a
B = XYZ*xyz0';	% (half of the) linear coefficient of the polynome
XYZ = XYZ+(sqrt(B.^2-(sum(XYZ.^2,2)-a^2))-B)*xyz0;
	% the solution of the quadratical formula

% Rescale to ellipsoid
XYZ(:,3) = XYZ(:,3)*(1-f);

end		% ProjPtsEllipsoid
