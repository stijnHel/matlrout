classdef cGeography < handle
	%cGeography - object handling geography data
	%     c = cGeography(...)
	%
	% see also CreateGeography (easy method to keep only one instance of this object)

	properties	% settings
		bStoreCoors = false
		dPosDeg = 0.01
	end		% properties (settings)

	properties
		borderPath
		countryTable
		Countries
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
							%!!!!!!!!!!!!!!move borders!!!!
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

		function X = GetCountryData(c,cntry,bAddBorders)
			if nargin<3 || isempty(bAddBorders)
				bAddBorders = c.bStoreCoors;
			end
			X = c.GetCountry(cntry,bAddBorders);
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
