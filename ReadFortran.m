function D = ReadFortran(fName,varargin)
%ReadFortran - Read Fortran code and get structure
%     D = ReadFortran(fName)

bIncludeComments = true;

if nargin>1
	setoptions({'bIncludeComments'},varargin{:})
end

LcombinableWords = {'BLOCK DATA','END INTERFACE','DOUBLE PRECISION'	...
	,'END MODULE','ELSE IF','END PROCEDURE','ELSE WHERE','END PROGRAM'	...
	,'END ASSOCIATE','END SELECT','END BLOCK','END SUBMODULE','END BLOCK DATA'	...
	,'END SUBROUTINE','END CRITICAL','END TYPE','END DO','END WHERE'	...
	,'END ENUM','GO TO','END FILE','IN OUT','END FORALL','SELECT CASE'	...
	,'END FUNCTION','SELECT TYPE','END IF'};
LcombinedWords = LcombinableWords;
for i=1:length(LcombinedWords)
	LcombinedWords{i}(LcombinedWords{i}==' ') = [];
end

c = cBufTextFile(fName);
L = c.fgetlN(10000);	% normally "just al"
iLtot = 0;
iL = 0;

Blocks = struct('label',cell(1,1000),'lines',[]	...
	,'Calls',{{}},'Gotos',[]	...
	,'endgoto',[]);
	% extra: references
	%          goto's
nBlocks = 0;
Struct = struct('type',cell(1,20),'label',[], 'sign',[],'Bstart',0);
nStruct = 1;
Struct(1).type = 'File';
Bcurrent = cell(3,1000);
nBlines = 0;
Labels = zeros(3,1000);
nLabels = 0;
Commons = struct('segment',{},'vars',{{}});
Formats = struct('label',{},'format','');
Program = struct('name',cell(1,0),'iBlockStart',[],'iBlockEnd',[]	...
	,'Labels',[],'Formats',[],'VarsSet',[],'VarsUsed',[]);
Subroutines = struct('name',cell(1,0),'iBlockStart',[],'iBlockEnd',[]	...
	,'Labels',[],'Formats',[],'VarsSet',[],'VarsUsed',[]);
nSubroutines = 0;
Functions = struct('name',cell(1,0),'iBlockStart',[],'iBlockEnd',[]	...
	,'Labels',[],'Formats',[],'VarsSet',[],'VarsUsed',[]);
nFunctions = 0;
Includes = cell(1,20);
nIncludes = 0;
VarsUsed = cell(1,100);
nVarsUsed = 0;
VarsSet = cell(1,100);
nVarsSet = 0;
Calls = cell(1,100);
nCalls = 0;
curBlockLabel = [];

while iL<length(L)
	[l,L,iL] = GetNextLine(c,L,iL,iLtot);
	
% 	while iL<length(L) && length(L{iL+1})>6	&& (...
% 			(startsWith(L{iL+1},'     ') && L{iL+1}(6)~=' ')		...
% 			|| (~isempty(l) && l(end)=='&'))
% 		if ~isempty(l) && l(end)=='&'
% 			l(end) = [];
% 			%(in fact non-empty lines should be used, not just any line!)
% 		end
% 		[lNext,L,iL] = GetNextLine(c,L,iL,iLtot);
% 		l = [l,lNext]; %#ok<AGROW>
% 	end
	
	if isempty(l)
		break
	end
	nBlines = nBlines+1;
	Bcurrent{1,nBlines} = l;
	Bcurrent{2,nBlines} = [];
	Bcurrent{3,nBlines} = [];
	if upper(l(1))=='C' || l(1)=='*'
		if bIncludeComments
			Bcurrent{2,nBlines} = 'C';
		else
			nBlines = nBlines-1;
		end
		continue
	elseif upper(l(1))=='D'	% "debug line"?
		Bcurrent{2,nBlines} = 'D';
		continue
	end
	if any(l(1:6)>='0' & l(1:6)<='9')
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent(:,1) = Bcurrent(:,nBlines);
			nBlines = 1;
		end
		labelNr = sscanf(l(1:6),'%d');
		if ~isscalar(labelNr)
			error('Something wrong with label? (#%d: "%s").\n',iLtot+iL,l)
		end
		curBlockLabel = labelNr;
		nLabels = nLabels+1;
		Labels(1,nLabels) = labelNr;
		Labels(2,nLabels) = nBlocks;
		Labels(3,nLabels) = nBlines;
	end
	W = Interpret(l(7:end));
	if isempty(W)
		continue	%?!!
	end
	Bcurrent{3,nBlines} = W;
	i = 1;
	while i<=size(W,2)
		if strcmp(W{2,i},'word') && ismember(W{1,i},LcombinedWords)
			wCombinable = LcombinableWords{strcmpi(W{1,i},LcombinedWords)};
			Wparts = regexp(wCombinable,' ','split');
			Winfo = cell(2,length(Wparts));
			[Winfo{1,:}] = deal('word');
			[Winfo{2,:}] = deal(W{3,i});
			W = [W(:,1:i-1),[Wparts;Winfo],W(:,i+1:end)];
			i = i+length(Wparts);
		else
			i = i+1;
		end
	end
	cmd = W{1};
	if strcmpi(cmd,'PROGRAM')
		if nStruct>1
			warning('Struct is not OK - PROGRAM in another structure?!')
		elseif ~isempty(Program)
			warning('Multiple program''s in one fortran file is not expected!!!!')
		end
		nStruct = nStruct+1;
		Struct(nStruct).type = upper(cmd);
		Program(1).name = W{1,2};
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent{1} = Bcurrent{1,nBlines};
			Bcurrent{3} = Bcurrent{3,nBlines};
			nBlines = 1;
			curBlockLabel = [];
		end
		Program.iBlockStart = nBlocks+1;
		Bcurrent{2} = 'PROG';
	elseif strcmpi(cmd,'SUBROUTINE')
		if nStruct>1
			warning('Struct is not OK - SUBROUTINE in another structure?!')
		end
		nStruct = nStruct+1;
		Struct(nStruct).type = upper(cmd);
		nSubroutines = nSubroutines+1;
		Subroutines(nSubroutines).name = W{1,2};
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent{1} = Bcurrent{1,nBlines};
			Bcurrent{3} = Bcurrent{3,nBlines};
			nBlines = 1;
			curBlockLabel = [];
		end
		Subroutines(nSubroutines).iBlockStart = nBlocks+1;
		Bcurrent{2} = 'SUB';
	elseif strcmpi(cmd,'FUNCTION')
		if nStruct>1
			warning('Struct is not OK - SUBROUTINE in another structure?!')
		end
		nStruct = nStruct+1;
		Struct(nStruct).type = upper(cmd);
		nFunctions = nFunctions+1;
		Functions(nFunctions).name = W{1,2};
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent{1} = Bcurrent{1,nBlines};
			Bcurrent{3} = Bcurrent{3,nBlines};
			nBlines = 1;
			curBlockLabel = [];
		end
		Functions(nFunctions).iBlockStart = nBlocks+1;
		Bcurrent{2} = 'FUN';
	elseif strcmpi(cmd,'BLOCK')
		%!!!!!!!!!!!!!!!!!not handled!!!!!!!!!!!!!!!!
		if nStruct>1
			warning('Struct is not OK - BLOCK in another structure?!')
		end
		nStruct = nStruct+1;
		Struct(nStruct).type = upper(cmd);
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent{1} = Bcurrent{1,nBlines};
			Bcurrent{3} = Bcurrent{3,nBlines};
			nBlines = 1;
			curBlockLabel = [];
		end
		Blocks(nBlocks).iBlockStart = nBlocks+1;
		Bcurrent{2} = 'BLOCK';
	elseif strcmpi(cmd,'COMMON')
		C = regexp(l,'/','split');
		if length(C)~=3
			warning('error in COMMON?!')
		else
			Commons(end+1).segment = strtrim(C{2}); %#ok<AGROW>
			Commons(end).vars = regexp(strtrim(C{3}),',','split');
			% do more!!!!
		end
	elseif strcmpi(cmd,'INCLUDE')
		nIncludes = nIncludes+1;
		Includes{nIncludes} = W{1,2};
	elseif strcmpi(cmd,'DIMENSION')
	elseif strcmpi(cmd,'CHARACTER')
	elseif strcmpi(cmd,'LOGICAL')
	elseif strcmpi(cmd,'REAL')
	elseif strcmpi(cmd,'PARAMETER')
	elseif strcmpi(cmd,'EQUIVALENCE')
	elseif strcmpi(cmd,'IF')
		i = 2;
		if W{3,2}==0
			warning('Bad IF statement?! (#%d: %s)',iLtot+iL,l)
			continue
		end
		while i<=size(W,2) && W{3,i}>0
			i = i+1;
		end
		vUsed = FindVarsUsed(W(:,2:i-1));
		if ~isempty(vUsed)
			VarsUsed(nVarsUsed+1:nVarsUsed+length(vUsed)) = vUsed;
			nVarsUsed = nVarsUsed+length(vUsed);
		end
		if i>size(W,2)
			warning('Bad IF statement?! (#%d: %s)',iLtot+iL,l)
			continue
		end
		% The following is not really OK
		%      every command is possible(?)!
		if strcmpi(W{1,i},'GO')
			if strcmpi(W{1,i+1},'TO')
				Blocks(nBlocks+1).Gotos(1,end+1) = W{1,i+2};
			else
				warning('"IF () GO" without "TO"? (#%d: %s)',iLtot+iL,l)
			end
		elseif strcmpi(W{1,i},'THEN')
			nStruct = nStruct+1;
			Struct(nStruct).type = 'IF';
			if nBlines>1
				nBlocks = nBlocks+1;
				Blocks(nBlocks).label = curBlockLabel;
				Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
				Bcurrent{1} = Bcurrent{1,nBlines};
				Bcurrent{3} = Bcurrent{3,nBlines};
				nBlines = 1;
				curBlockLabel = [];
			end
			Bcurrent{2} = 'IF';
		elseif ismember('assign',W(2,i:end))
			vSet = W{1,i};
			nVarsSet = nVarsSet+1;
			VarsSet{nVarsSet} = vSet;
			vUsed = FindVarsUsed(W(:,i+1:end));
			if ~isempty(vUsed)
				VarsUsed(nVarsUsed+1:nVarsUsed+length(vUsed)) = vUsed;
				nVarsUsed = nVarsUsed+length(vUsed);
			end
		elseif strcmpi(W{1,i},'WRITE')
		elseif strcmp(W{2,i},'number')
			if size(W,2)-i ~= 2
				warning('Unexpected arithmetic IF! (#%d: %s)',iLtot+iL,l)
			else
				jumpTo = [W{1,i:end}];	%!!!! do something with this!!!
				Blocks(nBlocks+1).Gotos(end+1:end+length(jumpTo)) = jumpTo;
			end
		elseif strcmpi(W{1,i},'CALL')
			Blocks(nBlocks+1).Calls{end+1,1} = W{1,i+1};
			Blocks(nBlocks+1).Calls{end,2} = W(1,i+2:end);
			nCalls = nCalls+1;
			Calls{nCalls} = W{1,i+1};
		else
			warning('Unexpected IF command (#%d: %s)',iLtot+iL,l)
			continue
		end
	elseif strcmpi(cmd,'ELSEIF')
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent(:,1) = Bcurrent(:,nBlines);
			nBlines = 1;
			curBlockLabel = [];
		end
		Bcurrent{2} = 'ELSEIF';
	elseif strcmpi(cmd,'DO')
		if nBlines>1
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines-1);
			Bcurrent(:,1) = Bcurrent(:,nBlines);
			nBlines = 1;
			curBlockLabel = [];
		end
		Bcurrent{2} = 'DO';
	elseif strcmpi(cmd,'END')
		%!!!!??? check "typed end" to current struct?!!!!!!
		nBlocks = nBlocks+1;
		Blocks(nBlocks).label = curBlockLabel;
		Blocks(nBlocks).lines = Bcurrent(:,1:nBlines);
		nBlines = 0;
		
		if nStruct<=1
			warning('END outside structure?!')
		elseif strcmp(Struct(nStruct).type,'PROGRAM')
			Program.iBlockEnd = nBlocks;
			Program.Labels = Labels(:,1:nLabels);
			nLabels = 0;
			Program.VarsSet = unique(VarsSet(:,1:nVarsSet));
			nVarsSet = 0;
			Program.VarsUsed = unique(VarsUsed(:,1:nVarsUsed));
			nVarsUsed = 0;
			Program.Calls = unique(Calls(:,1:nCalls));
			nCalls = 0;
		elseif strcmp(Struct(nStruct).type,'SUBROUTINE')
			Subroutines(nSubroutines).iBlockEnd = nBlocks;
			Subroutines(nSubroutines).Labels = Labels(:,1:nLabels);
			nLabels = 0;
			Subroutines(nSubroutines).VarsSet = unique(VarsSet(:,1:nVarsSet));
			nVarsSet = 0;
			Subroutines(nSubroutines).VarsUsed = unique(VarsUsed(:,1:nVarsUsed));
			nVarsUsed = 0;
			Subroutines(nSubroutines).Calls = unique(Calls(:,1:nCalls));
			nCalls = 0;
		elseif strcmp(Struct(nStruct).type,'FUNCTION')
			Functions(nFunctions).iBlockEnd = nBlocks;
			Functions(nFunctions).Labels = Labels(:,1:nLabels);
			nLabels = 0;
			Functions(nFunctions).VarsSet = unique(VarsSet(:,1:nVarsSet));
			nVarsSet = 0;
			Functions(nFunctions).VarsUsed = unique(VarsUsed(:,1:nVarsUsed));
			nVarsUsed = 0;
			Functions(nFunctions).Calls = unique(Calls(:,1:nCalls));
			nCalls = 0;
		end
		nStruct = nStruct-1;
		curBlockLabel = [];
	elseif strcmpi(cmd,'CALL')
		Blocks(nBlocks+1).Calls{end+1,1} = W{1,2};
		Blocks(nBlocks+1).Calls{end,1} = W(1,3:end);
		nCalls = nCalls+1;
		Calls{nCalls} = W{1,2};
		vUsed = FindVarsUsed(W(:,3:end));
		if ~isempty(vUsed)
			VarsUsed(nVarsUsed+1:nVarsUsed+length(vUsed)) = vUsed;
			nVarsUsed = nVarsUsed+length(vUsed);
		end
	elseif strcmpi(cmd,'FORMAT')
		Formats(end+1).label = curBlockLabel; %#ok<AGROW>
		Formats(end).format = l;	%!!!!!!!!!!!!!!!!
	elseif strcmpi(cmd,'GO')
		if strcmpi(W{1,2},'TO')
			nBlocks = nBlocks+1;
			Blocks(nBlocks).label = curBlockLabel;
			Blocks(nBlocks).lines = Bcurrent(:,1:nBlines);
			if size(W,2)==3
				Blocks(nBlocks).endgoto = W(:,3:end);
			else
				X = W(:,3:end);
				Blocks(nBlocks).endgoto = [X{1,[X{3,:}]==1}];
				vUsed = FindVarsUsed(X(:,[X{3,:}]==0));
				if ~isempty(vUsed)
					VarsUsed(nVarsUsed+1:nVarsUsed+length(vUsed)) = vUsed;
					nVarsUsed = nVarsUsed+length(vUsed);
				end
			end
			nBlines = 0;
			curBlockLabel = [];
		else
			warning('Unknown type of "GO" statement. (#%d: %s)',iLtot+iL,l)
		end
	elseif strcmpi(cmd,'CONTINUE')
	elseif ismember('assign',W(2,:))
		vSet = W{1,1};
		nVarsSet = nVarsSet+1;
		VarsSet{nVarsSet} = vSet;
		vUsed = FindVarsUsed(W(:,2:end));
		if ~isempty(vUsed)
			VarsUsed(nVarsUsed+1:nVarsUsed+length(vUsed)) = vUsed;
			nVarsUsed = nVarsUsed+length(vUsed);
		end
	end
end
if nBlines
	Bcurrent = Bcurrent(:,1:nBlines);
	nBlocks = nBlocks+1;
	Blocks(nBlocks).label = curBlockLabel;
	Blocks(nBlocks).lines = Bcurrent(:,1:nBlines);
end
if nStruct>1
	warning('End within a struct?! (#%d)',nStruct)
	for i=1:nStruct
		fprintf('%2d: %s\n',i,Struct(i).type)
	end
end

D = struct('Blocks',{Blocks(1:nBlocks)}	...
	,'Labels',Labels(:,1:nLabels)	...
	,'Commons',Commons	...
	,'Program',Program	...
	,'Subroutines',Subroutines(1:nSubroutines)	...
	,'Functions',Functions(1:nFunctions)	...
	,'Includes',{Includes(1:nIncludes)}	...
	,'Formats',Formats	...
	);

function [l,L,iL,iLtot] = GetNextLine(c,L,iL,iLtot)
iL = iL+1;
l = L{iL};
if any(l==9)	% "modern Fortran..."
	l = strrep(l,char(9),blanks(6));
end
if iL>=length(L)
	iLtot = iLtot+iL;
	L = c.fgetlN(10000);
	iL = 0;
end
bLoop = isempty(l) || l(1)~='C';
while bLoop
	if isempty(l)
		iL = iL+1;
		if iL<=length(L)
			l = L{iL};
			continue	% skip empty lines
		end
	end
	bLoop = false;
	if iL<length(L)
		lNext = L{iL+1};
		if any(lNext==9)	% "modern Fortran..."
			lNext = strrep(lNext,char(9),blanks(6));
		end
		if sum(lNext~=' ')==0
			iL = iL+1;	% skip line
			bLoop = true;
		elseif upper(lNext(1))=='C'	% check if first line after comment lines should be added
			iLn = iL+2;
			while iLn<length(L)	% (no check for "next block of lines" is done...)
				lNext = L{iLn};
				if any(lNext==9)	% "modern Fortran..."
					lNext = strrep(lNext,char(9),blanks(6));
				end
				if ~isempty(lNext) && upper(lNext(1))~='C'
					% check if continuation
					if length(lNext)>=6 && startsWith(lNext,'     ') && lNext(6)~=' '
						iL = iLn;
						l = [l,lNext(7:end)]; %#ok<AGROW>
						bLoop = true;
					end
					break
				end		% if not comment line
				iLn = iLn+1;
			end		% while
		elseif length(lNext)>=6 && startsWith(lNext,'     ') && lNext(6)~=' '
			iL = iL+1;	% append line
			l = [l,lNext(7:end)]; %#ok<AGROW>
			bLoop = true;
		elseif l(end)=='&' && length(lNext)>6
			if any(lNext(1:min(end,6))~=' ')
				warning('Wrong continuation line? ("%s")',lNext)
			end
			if length(lNext)>6
				l = [l(1:end-1),lNext(7:end)];
			end
			iL = iL+1;	% skip or append line - but look farther
			bLoop = true;
		end
	end
end

function [W,cmt] = Interpret(l)
Bnumber = false(1,255);
Bnumber(abs('01234567890.EeDd+-')) = true;
lCmd = l;
cmt = '';

i = 0;
IB = false(size(lCmd));
W = cell(3,ceil(length(lCmd)/2));
nW = 0;
iLevel = 0;
while i<length(lCmd)
	i = i+1;
	c = lCmd(i);
	IB(i) = iLevel;
	if c=='('
		iLevel = iLevel+1;
	elseif c==')'
		iLevel = iLevel-1;
		if iLevel<0
			error('Error in brackets level?! (%s)',l)
		end
	elseif c==' '
	elseif c==','
	elseif i<length(lCmd) && (c=='''' || c=='"'		... string
			|| (c=='.' && lCmd(i+1)>='A'))			% .AND., ...
		cDelim = c;
		i1 = i+1;
		w = 0;
		while i<length(lCmd)
			i = i+1;
			if lCmd(i)==cDelim
				if i<length(lCmd) && cDelim~='.' && lCmd(i+1)==cDelim
					i = i+1;
				else
					w = lCmd(i1:i-1);
					break
				end
			end
		end
		if isnumeric(w)
			error('Starting string without end?! (%s)',l)
		end
		nW = nW+1;
		if cDelim=='.'
			W{1,nW} = w;
			W{2,nW} = '.string';	% ".EQ.",...,".FALSE.",".TRUE."
		else
			W{1,nW} = w;
			W{2,nW} = 'string';
		end
		W{3,nW} = iLevel;
	elseif c=='!'	% comment
		cmt = lCmd(i+1:end);
		lCmd = lCmd(1:i-1);
	elseif (c>='0' && c<='9') || c=='.'
		i1 = i;
		i = i+1;
		while i<=length(lCmd) && Bnumber(abs(lCmd(i)))
			if lCmd(i)=='-' || lCmd(i)=='+'	% only allowed in exponent
				if all(lCmd(i-1)~='dDeE')
					break
				end
			end
			i = i+1;
		end
		if i<=length(lCmd)
			if lCmd(i-1)=='.' && upper(lCmd(i))>='A' && upper(lCmd(i))<='Z'
				% to handle constructs like "IT.NE.1.AND.I.EQ.2" correctly
				i = i-1;
			end
		end
		v = str2double(lCmd(i1:i-1));
		if isnan(v)
			error('Interpreting a number?! (%s)',l)
		end
		if i<length(lCmd)&&lCmd(i)=='H'	% Holorith constant
			nChar = v;
			if i+nChar>length(lCmd)
				warning('Holorith constant crossing line?!! (%s)',l)
				w = lCmd(i+1:end);
				w(end+1:nChar) = ' ';
			else
				w = lCmd(i+1:i+nChar);
			end
			nW = nW+1;
			W{1,nW} = w;
			W{2,nW} = 'holorith';
			i = i+nChar;
		else
			nW = nW+1;
			W{1,nW} = v;
			W{2,nW} = 'number';
			i = i-1;	% handle character after number
		end
		W{3,nW} = iLevel;
	elseif upper(c)>='A' && upper(c)<='Z'
		i1 = i;
		i = i+1;
		while i<=length(lCmd) && (upper(lCmd(i))>='A' && upper(lCmd(i)<='Z')	...
				|| lCmd(i)=='_' || (lCmd(i)>='0' && lCmd(i)<='9')	...
				|| (lCmd(i)=='.' && lCmd(i-1)>='0' && lCmd(i-1)<='9'	... to allow F12.4 FORMAT
					&& lCmd(i+1)>='0' && lCmd(i+1)<='9')	... (risking end of line error!!!)
				)
			i = i+1;
		end
		i = i-1;
		w = lCmd(i1:i);
		nW = nW+1;
		W{1,nW} = w;
		W{2,nW} = 'word';
		W{3,nW} = iLevel;
	elseif c=='='
		nW = nW+1;
		W{1,nW} = c;
		W{2,nW} = 'assign';
		W{3,nW} = iLevel;
	elseif any(c=='+-*/$')	% ('$' in format)
		nW = nW+1;
		W{1,nW} = c;
		W{2,nW} = 'op';
		W{3,nW} = iLevel;
	elseif c==':'
		nW = nW+1;
		W{1,nW} = c;
		W{2,nW} = 'op';
		W{3,nW} = iLevel;
	elseif c=='%'	% "new" fortran
		nW = nW+1;
		W{1,nW} = c;
		W{2,nW} = 'op';
		W{3,nW} = iLevel;
	else
		fprintf('Not handled char: ''%c'' in "%s"\n',c,l)
	end
end
% (!) -123 is handled as {"-"(op),123(number)}! (to handle '-' easily
%   this can be combined here?
if iLevel>0
	warning('End of line within brackets?! ("%s" - level %d)',l,iLevel)
end
W = W(:,1:nW);

function vUsed = FindVarsUsed(W)
vUsed = W(1,strcmp(W(2,:),'word'));
