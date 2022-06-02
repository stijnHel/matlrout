function [TransTable,pth] = ReadTransTable(fName,bAllowSpaces)
%ReadTransTable - Read a translation table from file
%  A translation table is a table with alternative names for a different
%  name.  This can be words in different languages, synonyms, but it can
%  also be used to link a name to an item.
%
%  Example:
%        main_word1		alt1_word1	alt2_word1
%        main_word2		alt1_word1
%
%  No fixed number of alternatives per word.
%  A table can have comments: an empty word (by <tab><tab> is regarded as
%	the end of line
%  The tranlation table is given as a cell array with two columns.  The
%  first column contains the main name, the second contains cells with the
%  alternatives.
%      TransTable = ReadTransTable(fName);
%      [TransTable,pth] = ReadTransTable();	% translation table file is searched

if nargin<2
	bAllowSpaces = [];
end

if nargin<1 || isempty(fName)
	pth = FindFolder('borders',0,'-bAppend');
	if ~exist(pth,'dir')
		error('Sorry, I can''t find the folders with state borders!')
	end
	fName = fullfile(pth,'countries.txt');
	bAllowSpaces = true;
end
if isempty(bAllowSpaces)
	bAllowSpaces = false;
end

[~,~,fExt] = fileparts(fName);
if strncmpi(fExt,'.xls',4)
	[~,TransTable] = xlsread(fName);
	Bok = false(1,size(TransTable,1));
	if size(TransTable,2)<2
		warning('Not a single translation found!')
	else
		for i=1:length(Bok)
			Bempty = cellfun(@isempty,TransTable(i,:));
			if all(Bempty)
				break
			elseif ~Bempty(1)
				j = find(Bempty,1);
				Bok(i) = true;
				if isempty(j)
					TransTable{i,2} = TransTable(i,2:end);
				else
					TransTable{i,2} = TransTable(i,2:j-1);
					Bok(i) = j>2;
				end
				if isscalar(TransTable{i,2})
					TransTable{i,2} = TransTable{i,2}{1};	% more readable
				end
			end		% ~empty line
		end		% for i (all lines)
	end		% no empty TransTable
	TransTable = TransTable(Bok,1:2);
else	% assume text file
	f = cBufTextFile(fName);
	L = f.fgetlN(10000);	% read all
	Bok = false(1,length(L));
	for i=1:length(L)
		l = L{i};
		if isempty(l)	% the end
			break
		elseif l(1)~=' ' && l(1)~=9		% discard line
			W = regexp(l,char(9),'split');
			j = find(cellfun(@isempty,W),1);
			if ~isempty(j)
				W = W(1:j-1);
			end
			Bok(i) = true;
			if length(W)>2
				if ~bAllowSpaces
					CheckSpaces(W)
				end
				W = {W{1},W(2:end)};
			elseif isscalar(W)
				if any(W{1}==' ') && ~bAllowSpaces
					warning('Spaces in signal translation list ("%s")!',W{1})
				end
				Bok(i) = false;	% useless to keep this in the list
			elseif ~bAllowSpaces
				CheckSpaces(W)
			end
			L{i} = W;
		end
	end		% for i
	TransTable = cat(1,L{Bok});
end		% text-file

function CheckSpaces(W)
B = cellfun(@(s) any(s==' '),W);
if any(B)
	fprintf('    ');fprintf('"%s" ',W{B});fprintf('\n')
	warning('Signal translation list contains spaces!')
end		% if any(B)
