function tracks = FindGPStrack(Pts,maxD,varargin)
%FindGPStrack - Find GPS track
%     tracks = FindGPStrack(Pts,maxD,varargin)
%            Pts: points (coordinates [latitude,longitude] or names)
%                 coordinates in degrees
%            maxD: max tolerance (in (approximately) meters)
%
%            tracks: dir-struct of files of found tracks
%
%  Distance to logged points are used (not distances to lines between points)

% Add minimum distance found (and index?)
%    and maybe some extra ("summarizing data")?

d = [];
dPath = [];
fTyp = '.fit';
fRead = [];

options = varargin;
if nargin<2
	maxD = [];
elseif ischar(maxD)
	options = [{maxD},options];
	maxD = [];
end
if isempty(maxD)
	maxD = 5000;
end

if ~isempty(options)
	setoptions({'d','fTyp','fRead','maxD'},options{:})
end

if isempty(d)
	if isempty(dPath)
		d = direv(['*',fTyp],'sortd');
	else
		d = dir(fullfile(dPath,['*',fTyp]));
	end
end
if iscell(Pts)
	for i=1:length(Pts)
		if ischar(Pts{i})
			p = geogcoor(Pts{i});
			Pts{i} = p([2 1])*(180/pi);
		end
	end		% for i
	Pts = cat(1,Pts{:});
end		% if iscell(Pts)

maxAdif = maxD/40e6*360;	% "approximate distance" to "approximate degrees"

B = false(1,length(d));
fR = fRead;
cStat = cStatus(sprintf('Scanning all files (#%d)',length(d)),0);
for i=1:length(d)
	if iscell(d)
		f = d{i};
	else
		f = d(i);
	end
	fPth = fFullPath(f);
	if isempty(fRead)
		fR = beprout(fPth);
	end
	try
		X = fR(fPth);
	catch err
		DispErr(err)
		warning('Error when reading file #%d - %s',i,fPth)
		continue
	end
	if isempty(X)
		continue	% skip file
	elseif isnumeric(X)
		C = X(:,2:3);
	else
		error('Incompatible output of reading file ("%s")',func2str(fR))
	end
	bOK = false;
	for j=1:size(Pts,1)
		dC = C-Pts(j,:);
		Dist = sqrt(sum(dC.^2,2));
		if isscalar(maxD)
			bOK = any(Dist<=maxAdif);
		else
			bOK = any(Dist<maxAdif(j));
		end
		if ~bOK
			break
		end
	end		% for j
	B(i) = bOK;
	cStat.status(i/length(d))
end
cStat.close()

tracks = d(B);
