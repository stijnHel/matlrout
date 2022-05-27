function [Xworld,varargout] = ReadWorld(X,varargin)
%ReadWorld - Read world borders
%       Xworld = ReadWorld()
%
%   extra's:
%      [Pbox,CountryNames,Coordinates,SegmentList] = ReadWorld(Xworld,'pos');
%      [Coordinates,CountryNames,SegmentList] = ReadWorld(Xworld,'border');
%      [Populations,CountryNames,Coordinates,SegmentList] = ReadWorld(Xworld,'pop');

if nargin
	if isstruct(X)
		if nargin==1
			error('I don''t know what you want me to do?!')
		end
		country = varargin{1};
		if ~ischar(country)
			error('Wrong use of this function!')
		end
		if nargin>2
			quest = varargin{2};
			if isempty(quest)
				quest = 'pos';
			end
		else
			quest = 'pos';
		end
		B = startsWith(X.Xattr.X(:,X.iCname),country,'IgnoreCase',true);
		if any(B)
			if sum(B)>1
				C = X.Xattr.X(B,X.iCname)';
				if all(strcmp(C,C{1}))
					warning('Multiple parts are found - the largest is taken!')
					ii = find(B);
					S = zeros(1,length(ii));
					for i=1:length(ii)
						b = X.Records(ii(i)).Box;
						S(i) = abs((b(3)-b(1))*(b(4)-b(2)));	% very simple size calculation!
					end
					[~,i] = max(S);
					B(ii) = false;
					B(ii(i)) = true;
				else
					fprintf('      %s\n',C{:})
					error('Sorry, multiple possibilities')
				end
			end
			switch lower(quest)
				case 'pos'
					b = X.Records(B).Box;
					Xworld = b*[0.5 0;0 0.5;0.5 0;0 0.5];
					varargout = {X.Xattr.X{B,X.iCname},X.Records(B).points,X.Records(B).parts};
				case 'border'
					Xworld = X.Records(B).points;
					varargout = {X.Xattr.X{B,X.iCname},X.Records(B).parts};
				case 'pop'
					Xworld = X.Xattr.X{B,X.iCpopest};
					varargout = {X.Xattr.X{B,X.iCname},X.Records(B).points,X.Records(B).parts};
				otherwise
					error('Unknown question')
			end
		else
			error('Country not found!')
		end
	else
		error('Wrong input!')
	end
	return
end

fBorders = FindFolder('borders',0,'-bAppend');
Xworld=ReadESRI(fullfile(fBorders,'ne_10m_admin_0_countries\ne_10m_admin_0_countries'));
iCname=find(strcmpi('sovereignt',{Xworld.Xattr.recordDef.name}));
Xworld.iCpopest=find(strcmpi('POP_EST',{Xworld.Xattr.recordDef.name}));
Xworld.iCcontinent=find(strcmpi('CONTINENT',{Xworld.Xattr.recordDef.name}));
Xworld.iCregion_un=find(strcmpi('REGION_UN',{Xworld.Xattr.recordDef.name}));
Xworld.iCsubregion=find(strcmpi('SUBREGION',{Xworld.Xattr.recordDef.name}));
Xworld.iCregion_wb=find(strcmpi('REGION_WB',{Xworld.Xattr.recordDef.name}));
Xworld.iCname=iCname;
% A conversion from UTF-8 to char should be made...
%       this is only made for Sao Tome and Principe....
for i=1:size(Xworld.Xattr.X,1)
	c=Xworld.Xattr.X{i,iCname};
	if any(c>127)
		if c(1)=='S'&&c(2)==195
			Xworld.Xattr.X{i,iCname}='Sao Tome and Principe';	%!!!!
		end
	end
end
