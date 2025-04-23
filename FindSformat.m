function [Dspec,t,nrs] = FindSformat(s,S)
%FindSformat - Find "string format" of string
%     Main goal: Find the format of filenames with date/time and nrs
%     Different types for date/time formats are allowed:
%          Only numerical (no names of months)
%          Only "logical order" is allowed (year - month - ... - seconds)
%          Fixed lengths of numbers (2 - 4 for year)
%          with/without delimiters between numbers
%          dates must always have year and month and day
%
%    [Dspec,t,nrs] = FindSformat(s)
%    [t,nrs] = FindSformat(Dspec,S)	% S string / cell-array

[bCombineEquals] = true;

if isstruct(s)
	if isfield(s,'sSpec')	% assumed to be unique enough...
		Dspec = s;
		if isnumeric(S)	% "nrs" ---> make string
			s = sprintf([s.sSpec,'\n'],S);
				% this will not always work if "generic nrs" are originally 0-filled!
			Dspec = regexp(s(1:end-1),newline,'split');
			return
		elseif ischar(S) || isstring(S)
			[T,NRs] = ExtractData(Dspec,S);
		else
			if isDirStruct(S)
				S = {S.name};
			end
			sz = size(S);
			T = zeros(sz);
			if any(sz==1) && any(sz>1)
				sz(sz==1) = [];
			end
			NRs = zeros([Dspec.nVal,sz]);
			for i=1:numel(S)
				[T(i),nrs] = ExtractData(Dspec,S{i});
				if length(nrs)~=Dspec.nVal
					T = T(1:i-1);
					NRs = NRs(:,1:i-1);
					warning('Different type! (%d/%d: %s) --- stopped',i,numel(S),S{i})
					break
				else
					NRs(:,i) = nrs;
				end
			end
		end
		% format to standard output argument names
		Dspec = T;
		t = NRs;
		return
	elseif isDirStruct(s)
		if isscalar(s)
			s = s.name;
		elseif isempty(s)
			error('Sorry, I can''t work with empty dir-structs')
		else
			s = {s.name};
		end
	else
		error('Sorry, with this type of struct I can''t work.')
	end
end
if iscell(s)
	[Dspec,t,nrs] = FindSformat(s{1});
	nrs = nrs(:);
	Dspeci = Dspec;
	i = 1;
	while i<numel(s)
		i = i+1;
		[t_i,nrs_i] = FindSformat(Dspeci,s(i:end));
		if ~isempty(t_i)
			t(end+1:end+length(t_i)) = t_i;
			if isvector(nrs_i)
				nrs_i = nrs_i(:);
			end
			if iscell(nrs)
				nrs{end} = [nrs{end},nrs_i];
			else
				nrs = [nrs,nrs_i]; %#ok<AGROW> 
			end
			i = i+length(t_i);
		end
		if i<numel(s)
			[Dspeci,t_i,nrs_i] = FindSformat(s{i});
			Dspec(1,end+1) = Dspeci; %#ok<AGROW> 
			t(1,end+1) = t_i; %#ok<AGROW> 
			if iscell(nrs)
				nrs{1,end+1} = nrs_i(:); %#ok<AGROW> 
			else
				nrs = {nrs,nrs_i(:)}; %#ok<AGROW> 
			end
		end
	end
	if bCombineEquals	% (!) looses connection to orignal order!
		B = false(size(Dspec));
		T = cell(size(Dspec));	% recalc time!
		for i=1:length(Dspec)
			if iscell(nrs)
				nrs_i = nrs{i};
			else
				nrs_i = nrs;
			end
			if ~isempty(Dspec(i).sSpec)
				B(i) = true;
				ii = find(strcmp({Dspec(i+1:end).sSpec},Dspec(i).sSpec));
				if ~isempty(ii)
					% (are specs always equal when sSpec's are equal?)
					ii = [i i+ii];
					%t = [t{ii}]; !!!!
					nrs_i = [nrs{ii}];
					nrs{i} = nrs_i;
					[Dspec(ii(2:end)).sSpec] = deal([]);
				end		% equals found
				T{i} = datenum(nrs_i(Dspec(i).IdtIdx,:)');
			end		% not yet handled
		end		% for i
		if ~all(B)
			Dspec = Dspec(B);
			nrs = nrs(B);
			T = T(B);
		end
		t = T;
	end		% if bCombineEquals
	return
end
if isstring(s)
	s = char(s);
end

Bnr = s>='0' & s<='9';
B = [false,Bnr,false];
InrStart = find(B(2:end) & ~B(1:end-1));
InrEnd = find(B(1:end-1) & ~B(2:end))-1;
Lnr = InrEnd-InrStart+1;
nrs = zeros(size(InrStart));
for i=1:length(InrStart)
	nrs(i) = sscanf(s(InrStart(i):InrEnd(i)),'%ld');
end
iiYear = find(Lnr(1:end-2)==4 & Lnr(2:end-1)==2 & Lnr(3:end)==2);		% (don't allow year as the last 2 numbers)
IdtIdx = zeros(1,7);
Lnrs = [4 2 2 2 2 2 3 8 12 14];	% lengths of numbers of number types
	%  1 : year
	%  2 : month
	%  3 : day
	%  4 : hour
	%  5 : minute
	%  6 : second
	%  7 : fractional second
	%  8 : YYYYMMDD
	%  9 : YYYYMMDDhhmm
	% 10 : YYYYMMDDhhmmss
NrType = zeros(size(InrStart));
if ~isempty(iiYear)
	if length(iiYear)>1
		warning('Multiple dates specified? Only the first is choosen - just based on number lengths!!!')
		iiYear = iiYear(1);
	end
	IdtIdx(1:3) = iiYear:iiYear+2;
	NrType(iiYear:iiYear+2) = 1:3;
end
iVal = 0;
for i=1:length(InrStart)
	iVal = iVal+1;
	if NrType(i)==0	% not yet identified
		if Lnr(i)==2
			if ~isempty(iiYear) && i-iiYear==3 && length(InrStart)-i>0 && Lnr(i+1)==2
				IdtIdx(4:5) = iVal:iVal+1;
				NrType(i:i+1) = 4:5;
				if length(InrStart)-i>1 && Lnr(i+2)==2
					IdtIdx(6) = iVal+2;
					NrType(i+2) = 6;
				end
			end
		elseif isempty(iiYear) && Lnr(i)==8 && nrs(i)>2000e4 && nrs(i)<2200e4	% date (possibly)
			% better test on next numbers
			iiYear = i;
			IdtIdx(1:3) = iVal:iVal+2;
			NrType(i) = 8;
			iVal = iVal+2;
		elseif isempty(iiYear) && Lnr(i)==12 && nrs(i)>2000e8 && nrs(i)<2200e8	% date+HHMM (possibly)
			iiYear = i;
			IdtIdx(1:5) = iVal:iVal+4;
			NrType(i) = 9;
			iVal = iVal+4;
		elseif isempty(iiYear) && Lnr(i)==14 && nrs(i)>2000e10 && nrs(i)<2200e10	% date+HHMMSS (possibly)
			iiYear = i;
			IdtIdx(1:6) = iVal:iVal+5;
			NrType(i) = 10;
			iVal = iVal+5;
		end
		%!!!! sub-seconds!!!
	end		% not yet handled
end
Insrs = NrType==0;

% create "format spec string"
Cformat = cell(1,length(InrStart)*2+1);
Cformat{1} = s(1:InrStart(1)-1);
InrStart(end+1) = length(s)+1;
for i=1:length(InrEnd)
	if NrType(i) && NrType(i)<8	% use fixed length
		Cformat{i*2} = sprintf('%%0%dd',Lnrs(NrType(i)));
		% ((!!) is subseconds with '.' are allowed, this must be changed!
	elseif NrType(i)==8	% YYYYMMDD
		Cformat{i*2} = '%04d%02d%02d';
	elseif NrType(i)==9	% YYYYMMDDhhmm
		Cformat{i*2} = '%04d%02d%02d%02d%02d';
	elseif NrType(i)==10	% YYYYMMDDhhmmss
		Cformat{i*2} = '%04d%02d%02d%02d%02d%02d';
	else	% use free length
		Cformat{i*2} = '%d';
	end
	Cformat{i*2+1} = s(InrEnd(i)+1:InrStart(i+1)-1);
end
%!!!!!!!!!!!!!!!watch out for '%' in format !!!!
sSpec = [Cformat{:}];
IdtIdx = IdtIdx(IdtIdx>0);	% necessary to check all available in "logical order"?
nVal = iVal;
Dspec = var2struct(sSpec,nVal,NrType,IdtIdx,Insrs);

if nargout>1
	[t,nrs] = ExtractData(Dspec,s);
end

function [t,nrs] = ExtractData(Dspec,s)
nrs = sscanf(s,Dspec.sSpec,[1 Dspec.nVal]);
if length(nrs)<Dspec.nVal
	t = 0;
	warning('Different type?!')
elseif isempty(Dspec.IdtIdx)
	t = [];
else
	nrsT = nrs(Dspec.IdtIdx);
	if length(nrsT)>3 && length(nrsT)<6
		nrsT(end+1:6) = 0;
	end
	%(!!!) fractional seconds!!
	t = datenum(nrsT);
end
