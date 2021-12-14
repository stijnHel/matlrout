function [D,Vout,order,opNames]=InterpreteFormula(s,varargin)
%InterpreteFormula - Interprete a formula (C-convention) to operations
%   [D,Names,OpOrder,OpNames]=InterpreteFormula(s)
%       D      : coded parts in formula (numeric [5xn] array)
%                     row 1: start index in s
%                     row 2: operator numbers (see OpNames)
%                     row 3: length in s
%                     row 4: level (in brackets)
%                     row 5: numeric value
%      Names   : list of used names
%      OpOrder : order of operators (in D)
%                     column 1: operator (ref to column in D)
%                     column 2: operator type
%                     column 3: operator number (idx in possibilities of type)
%                     column 4: n arguments
%                     column 4+i: argument i (if positive, ...
%                                           otherwise to OpOrder)
%                          sometimes additional columns (array size)
%      OpNames : operator numbers with their meaning
%
%   [v,bOK,intermV,V]=InterpreteFormula(D,V,order);
%        in:
%           V: variables
%              {Names;
%               values;
%               bValue}
%        out:
%           intermV: Intermediate results for each row in order
%              {bValue;
%              value}
%           V: values are updated, row 4: used, row 5: updated

% - iOpTypeTstart loopt fout: sizeof(float)
% - except vars, functions (as 'labels') add 'type'
%          if (<type>) --> no operation
% - types should be reordered!!
% - '||' and '&&' --> normally only evaluates parts if needed.  Since the
%	order of evaluation is fixed, independent of the result, this is not
%	the case!  ==> add "conditional-evaluation" info, with also default
%	value  ( ...||xxx --> default for xxx false,
%            ...&&xxx --> default for xxx true)
% - meer gebruik maken van Bpos
% - twee manieren om "van rechts naar links" zijn gebruikt in GetOpOrder!

global INTFORMops

if isempty(INTFORMops)
	INTFORMops.opNames=GetOpNames();
	opNames=INTFORMops.opNames;
	INTFORMops.iOpNumber=find(strcmp('number',opNames));
	INTFORMops.iOpVar=find(strcmp('var',opNames));
	INTFORMops.iOpNegate=find(strcmp('negate',opNames));
	INTFORMops.iOpNumber=find(strcmp('number',opNames));
	INTFORMops.iOpPtrRef=find(strcmp('ptrRef',opNames));
	INTFORMops.iOpFunction=find(strcmp('function',opNames));
	INTFORMops.iOpPtr=find(strcmp('ptr',opNames));
	INTFORMops.iOpAssign=find(strcmp('=',opNames));
	INTFORMops.iOpLogNOT=find(strcmp('!',opNames));
	INTFORMops.iOpNOT=find(strcmp('~',opNames));
	INTFORMops.iOpComma=find(strcmp(',',opNames));
	INTFORMops.iOpSemiC=find(strcmp(';',opNames));
	INTFORMops.iOpColSep=find(strcmp('colSep',opNames));
	INTFORMops.iOpSField=find(strcmp('.',opNames));
	INTFORMops.iOpSPfield=find(strcmp('->',opNames));
	INTFORMops.iOpField=find(strcmp('field',opNames));
	INTFORMops.iOpMult=find(strcmp('*',opNames));
	INTFORMops.iOpOpenB=find(strcmp('(',opNames));
	INTFORMops.iOpCloseB=find(strcmp(')',opNames));
	INTFORMops.iOpTypeRef=find(strcmp('typeRef',opNames));
	INTFORMops.iOpTypeTstart=find(strcmp('tS',opNames));
	INTFORMops.iOpTypeTend=find(strcmp('tE',opNames));
	INTFORMops.iOpTypeType=find(strcmp('type',opNames));
	INTFORMops.iOpTranspose = find(strcmp('transpose',opNames));
else
	opNames=INTFORMops.opNames;	% to be removed!
end
if nargin==0
	D=INTFORMops.opNames;
	return
end

if isnumeric(s)
	[D,Vout,order,opNames]=GetFormValue(s,varargin{:});
		% arguments are named to "original" use of this function!
	return
end

[bForceFloat]=true;
[bMatlabForm]=false;	% only some adaptations (no .*,..., only ^)
[charEscape]='\';	% escape character for special characters
sTypes={'const','enum','struct','union','void','bool','int','byte'	...
	,'char','float','double','size_t','unsigned','signed','short','long'};
[extraTypes]=[];
if ~isempty(varargin)
	setoptions({'bForceFloat','bMatlabForm','charEscape','extraTypes'},varargin{:})
	if ~isempty(extraTypes)
		sTypes=[sTypes extraTypes(:)'];	% better use union?
	end
end

bNameCharSt=false(1,255);
bDigChars=bNameCharSt;
bDigChars(abs('0'):abs('9'))=true;
bNameCharSt(abs('a'):abs('z'))=true;
bNameCharSt(abs('A'):abs('Z'))=true;
bNameCharSt(abs('_µ°'))=true;
bNameChars=bNameCharSt|bDigChars;
bNoOp2=false(1,100);
bNoOp2([4 7 10:20 21:29 40:42 50:2:55 60:66 INTFORMops.iOpTypeType INTFORMops.iOpTypeTend 97])=true;

matOps='+-*/';
brackOpen ='([{';
brackClose=')]}';

V=cell(1,30);
nV=0;
nS=length(s);
iS=1;
typLast=0;
iTyp=zeros(4,nS);
Blevel=char(zeros(1,10));
Bpos=zeros(1,10);
nBlevel=0;
iSlast=0;
bAllowString = true;
while iS<=nS
	si=s(iS);
	isi=abs(si);
	jS=iS+1;
	vExtra=0;
	if bNameCharSt(isi)
		while jS<=nS&&bNameChars(abs(s(jS)))
			jS=jS+1;
		end
		sW=s(iS:jS-1);
		[vExtra,V,nV]=FindVar(sW,V,nV);
		if typLast==INTFORMops.iOpTypeType||any(strcmp(sW,sTypes))
			typLast=INTFORMops.iOpTypeType;
		else
			if typLast==INTFORMops.iOpSField||typLast==INTFORMops.iOpSPfield
				typLast=INTFORMops.iOpField;
			else	%variable
				typLast=INTFORMops.iOpVar;
			end
		end		% no type
		bAllowString = false;
	elseif bDigChars(isi)	% number
		% not safe, but "good C-formula's" are assumed
		while jS<=nS
			if s(jS)=='.'
				% stay in loop
			elseif ~bNameChars(abs(s(jS)))
				if (s(jS)=='+'||s(jS)=='-')&&lower(s(jS-1))=='e'
					% stay in loop
				else
					break
				end
			end
			jS=jS+1;
		end
		if s(jS-1)=='U'	% unsigned - but handled the same (discard 'U')
			vExtra=str2double(s(iS:jS-2));
		elseif s(jS-1)=='L'	% long - but handled the same (discard 'L')
			vExtra=str2double(s(iS:jS-2));
		else
			vExtra=str2double(s(iS:jS-1));
		end
		if bForceFloat&&~isnan(vExtra)&&any(s(iS:jS-1)=='.')&&vExtra==round(vExtra)
			% force floating number
			if vExtra==0
				vExtra=1e-300;	% small enough?
			else
				vExtra=vExtra*(1+2^-50);
			end
		end
		if iS>1&&iTyp(1,iS-1)==2
			% negative number, rather than negation operator
			iS=iS-1;
			vExtra=-vExtra;
		end
		typLast=INTFORMops.iOpNumber;
		bAllowString = false;
	elseif si==' '||si==9
		iS=iS+1;
		continue;
	elseif any(si==matOps)
		bMat=false;
		if si=='*'	% can be pointer reference or multiplication
			if typLast==INTFORMops.iOpTypeType
				typLast=INTFORMops.iOpTypeRef;
			elseif typLast==0||bNoOp2(typLast)
				% pointer reference
				typLast=INTFORMops.iOpPtrRef;
			else
				% multiplication (or multiply-assignment)
				bMat=true;	% might be a "typeref" - handled at the end
			end
		elseif si=='+'	% can be sum (or +=) or increment
			if iS<nS
				if s(jS)=='+'
					typLast=21;
					jS=iS+2;
				else
					bMat=true;
				end
			else
				bMat=true;
			end
		elseif si=='-'
			if iS>=nS
				bMat=true;
			elseif s(jS)=='>'
				typLast=41;
				jS=jS+1;
			elseif s(jS)=='-'
				typLast=22;
				jS=iS+2;
			elseif typLast==0||bNoOp2(typLast)
				typLast=INTFORMops.iOpNegate;
			else
				bMat=true;
			end
		else
			bMat=true;
		end
		if bMat
			if iS<nS
				if s(jS)=='='
					typLast=30;
					jS=iS+2;
				else
					typLast=INTFORMops.iOpComma;
					jS=iS+1;
				end
			else
				error('Ending with "%c"?!',si)
			end
			typLast=typLast+find(si==matOps);
		end
		bAllowString = true;
	elseif si=='&'
		if typLast==0||bNoOp2(typLast)
			typLast=INTFORMops.iOpPtr;	% pointer
		elseif s(jS)=='&'
			typLast=18;
			jS=jS+1;
		else
			typLast=17;
		end
		bAllowString = true;
	elseif si=='|'
		if s(jS)=='|'
			typLast=20;
			jS=jS+1;
		else
			typLast=19;
		end
		bAllowString = true;
	elseif si=='^'
		if bMatlabForm
			typLast=26; %#ok<UNRCH>
		else
			typLast=42;
		end
		bAllowString = false;
	elseif si=='='
		if jS<=nS&&s(jS)=='='
			typLast=60;
			jS=jS+1;
		else
			typLast=INTFORMops.iOpAssign;
		end
		bAllowString = true;
	elseif si=='!'
		if typLast==0||bNoOp2(typLast) % NOT
			typLast=INTFORMops.iOpLogNOT;
		elseif s(jS)=='='
			typLast=61;
			jS=jS+1;
		else
			error('unknown use of "!". (%s_%d)',s,iS)
		end
		bAllowString = false;
	elseif si=='<'
		if s(jS)=='='
			typLast=64;
			jS=jS+1;
		elseif s(jS)=='<'
			if jS<nS
				if s(jS+1)=='='
					typLast=35;
					jS=jS+2;
				else
					typLast=15;
					jS=jS+1;
				end
			else
				error('Ending with "<<"!')
			end
		else
			typLast=63;
		end
		bAllowString = true;
	elseif si=='>'
		if s(jS)=='='
			typLast=66;
			jS=jS+1;
		elseif s(jS)=='>'
			if jS<nS
				if s(jS+1)=='='
					typLast=36;
					jS=jS+2;
				else
					typLast=16;
					jS=jS+1;
				end
			else
				error('Ending with "<<"!')
			end
		else
			typLast=65;
		end
		bAllowString = true;
	elseif si=='~'
		if s(jS)=='='
			typLast=62;
			jS=jS+1;
		else
			typLast=INTFORMops.iOpNOT;
		end
		bAllowString = false;
	elseif si==','
		typLast=INTFORMops.iOpComma;
		bAllowString = true;
	elseif si=='.'
		typLast=40;
		if bMatlabForm
			if s(jS)=='*' %#ok<UNRCH>
				typLast=44;
			elseif s(jS)=='/'
				typLast=45;
			elseif s(jS)=='^'
				typLast=46;
			end
		end
		bAllowString = false;
	elseif si=='%'
		typLast=27;
		bAllowString = false;
	elseif si=='?'
		typLast=70;
		bAllowString = true;
	elseif si==':'
		typLast=71;
		bAllowString = true;
	elseif any(si==brackOpen)
		if si=='('&&typLast==INTFORMops.iOpVar
			iTyp(1,iSlast)=INTFORMops.iOpFunction;
		end
		nBlevel=nBlevel+1;
		Blevel(nBlevel)=si;
		Bpos(nBlevel)=iS;
		typLast=48+find(si==brackOpen)*2;
		bAllowString = true;
	elseif any(si==brackClose)
		if nBlevel<=0
			error('Can''t find closing bracket (%c)',si)
		end
		if find(si==brackClose)~=find(Blevel(nBlevel)==brackOpen)
			error('Nonmatching bracket (%s)',si)
		end
		if typLast==INTFORMops.iOpTypeType||typLast==INTFORMops.iOpTypeTend||typLast==INTFORMops.iOpTypeRef
			typLast=INTFORMops.iOpTypeTend;
			iTyp(1,Bpos(nBlevel))=INTFORMops.iOpTypeTstart;
		else
			typLast=49+find(si==brackClose)*2;
		end
		nBlevel=nBlevel-1;
		bAllowString = false;
	elseif si==''''
		if bMatlabForm
			if bAllowString
				% Matlab doesn't have "char" ==> string
				while s(jS)~='''' || (jS<length(s) && s(jS+1)=='''')
					if s(jS)==charEscape
						jS=jS+1;
					end
					jS=jS+1;
				end
				[vExtra,V,nV]=FindVar(s(iS+1:jS-1),V,nV);
				jS=jS+1;
				typLast=29;
			else
				typLast=30;
				bAllowString = true;
			end
		else
			if s(jS)==charEscape
				jS=jS+1;
				vExtra=-abs(s(jS));
			else
				vExtra=abs(s(jS));
			end
			if s(jS+1)~=''''
				error('No closing char constant! (%s_%d)',s,iS)
			end
			jS=jS+2;
			typLast=28;
		end
	elseif si=='"'
		while s(jS)~='"'
			if s(jS)==charEscape
				jS=jS+1;
			end
			jS=jS+1;
		end
		[vExtra,V,nV]=FindVar(s(iS+1:jS-1),V,nV);
		jS=jS+1;
		typLast=29;
	elseif si==';'
		if nBlevel==0
			typLast=98;
		else
			typLast=INTFORMops.iOpSemiC;
		end
		bAllowString = true;
	else
		typLast=99;
		bAllowString = true;
	end
	iTyp(1,iS)=typLast;
	iTyp(2,iS)=jS-iS;
	iTyp(3,iS)=nBlevel;
	iTyp(4,iS)=vExtra;
	iSlast=iS;
	iS=jS;
end
if nBlevel~=0
	error('End of formula within brackets?!')
end
ii=find(iTyp(1,:));
D=[ii;iTyp(:,ii)];
% some multiply operators might be typeRef's
%      !!!!this code should be removed, if possible, since the test for
%      iOpTypeRef is used for the right interpretation of brackets and '&'
B=D(2,1:end-1)==INTFORMops.iOpMult&(D(2,2:end)==INTFORMops.iOpCloseB|D(2,2:end)==INTFORMops.iOpTypeRef);
while any(B)
	D(2,B)=INTFORMops.iOpTypeRef;
	B=D(2,1:end-1)==INTFORMops.iOpMult&(D(2,2:end)==INTFORMops.iOpCloseB|D(2,2:end)==INTFORMops.iOpTypeRef);
end

if nargout>1
	Vout=V(1:nV);
	if nargout>2
		[order,D]=GetOpOrder(D);
		if nargout>3
			uOps=unique(D(2,:));
			opNames=[num2cell(uOps);INTFORMops.opNames(uOps)];
		end
	end
end

	function [order,D]=GetOpOrder(D)
		persistent opOrder
		
		if isempty(opOrder)
			opOrder={
				0,{'number','var','char','string'};	... constants
				2,{'.','->'};			...
				1,{'negate',1;'ptrRef',1;'typeRef',-1;'++',0;'--',0;'++r',0;'--r',0;'transpose',-1}';	... unary operators
				1,{'ptr',1;'!',1;'~',1}';	...
				-2,{'[','{','(','tS'};			... brackets (closing bracket should be handled automatically (by opening bracket)
				-1,{'function'};	... (',' handled here, unless no function exist!)
				2,{'power'};	...
				2,{'*','/','%'};	...
				2,{'+','-'};	...
				2,{'AND','OR','XOR'};	...
				2,{'<<','>>'};	...
				2,{'!=','~=','<','<=','>','>=','=='};	...
				2,{'logAND'};	...
				2,{'logOR'};	...
				3,{'?'};	...
				[2 -1],{'=','+=','-=','*=','/=','<<=','>>='};	... right to left
				2,{','};	... columns / arguments
				2,{';'};	... rows
				};
				% By putting ',' at the end, it's forced to have the ','
				% just before it's used (in brackets).
			for iOT=1:size(opOrder,1)
				if length(opOrder{iOT})<2
					opOrder{iOT,4}=1;
				else
					opOrder{iOT,4}=opOrder{iOT}(2);
					opOrder{iOT}=opOrder{iOT}(1);
				end
				iOpOrder=zeros(1,size(opOrder{iOT,2},2));
				for i=1:length(iOpOrder)
					j=find(strcmp(opOrder{iOT,2}{1,i},INTFORMops.opNames),1);
					if isempty(j)
						error('Bug: opOrder should only contain operators defined in opNames')
					end
					iOpOrder(i)=j;
				end
				opOrder{iOT,3}=iOpOrder;
			end
		end
		O=D(2,:);
		if any(O==99)
			order=[];	% not if an error is found
			return
		end
		if any(O==98)	% end
			D=D(:,find(O==98,1)-1);	% handle up to 'end'
			O=D(2,:);
		end
		order=zeros(length(O),6);
		iOpType=1;
		uO=unique(O);
		iOrder=0;
		Bok=true(1,length(O));	% om te gebruiken voor "wacht-operaties"!!!!
		Bt=Bok;
		iOpMin=1;
		% check for infinite loop?
		while any(uO>0)
			oList=intersect(uO,opOrder{iOpType,3});
			if isempty(oList)
				iOpType=iOpType+1;
				if all(Bok)
					iOpMin=iOpType;
				end
				if iOpType>size(opOrder,1)
					fprintf('operators:');fprintf(' %d(%d)',[find(O>0);O(O>0)]);fprintf('\n')
					warning('IFormula:unusualStop','not all operands used!')
					break
				end
			else
				iOpTypeEff=iOpType;
				Bt(:)=false;
				for i=1:length(oList)
					Bt=Bt|(O==oList(i));
				end
				% handled only one by one to avoid problems with reallowing
				%    deactivated operations.  This is not optimal, but that's not
				%    one of the intentions of this function!
				% search for possible operation
				bOK=false;
				while any(Bt)
					iD=find(Bt);
					iD(D(4,iD)<D(4,iD))=[];	% take "deepest" first
					if length(iD)>1
						if opOrder{iOpType,4}>0	% left to right
							iD=iD(1);
						else
							% Only do right to left if no "lower level operation" in between
							O1=O;
							O1(iD)=0;
							i=find(O1(iD(1):iD(end))>0,1);
							if ~isempty(i)
								O1(i+iD(1)-1:end)=-1;
							end
							iD(O1(iD)<0)=[];
							iD=iD(end);
						end
					end
					iOrder=iOrder+1;
					o=D(2,iD);
					B=opOrder{iOpType,3}==o;
					nArg=opOrder{iOpType};
					order(iOrder,4)=nArg;
					switch nArg
						case -2		% brackets
							% find matching bracket
							jD=iD+1;
							while jD<=length(O)&&O(jD)~=o+1
								jD=jD+1;
							end
							if jD>length(O)
								error('Bracket not closed!')
							end
							bArray=false;
							if O(iD)==INTFORMops.iOpTypeTstart
								iOp1=iD;
								O(iOp1:jD)=-iOrder;
								order(iOrder,4)=0;
								bOK=true;
							elseif all(O(iD+1:jD-1)<=0)	% Delay if not everything is processed
								bGroup=true;
								iOp1=iD;
								if opOrder{iOpType,2}{B}=='['	% indexing
									% (in general) '[' can be indexing but
									%    also grouping (array definition)
									% now only "simple definition".
									if iD==1||O(iD-1)==7
										% if it starts with '[' or after '='
										%   it's not indexing
										bArray=true;
									elseif O(iD-1)<=0
										bGroup=false;
										order(iOrder,4)=2;
										order(iOrder,5)=O(iD-1);
										if iD+1>jD-1
											error('In a formula x[] (empty array) is not allowed')
										end
										order(iOrder,6)=min(O(iD+1:jD-1));
										iOp1=find(O==O(iD-1),1);
										bOK=true;
									end
								end
								if bGroup
									iOpTypeEff=-1;
									if jD-1>iD	%% comma
										% Find the number of elements
										kO=O(iD+1);
										[nCols,nRows]=ExtractSize(-kO,bArray);
										order(iOrder,5)=O(iD+1);
										nEl=1;
									else	% empty
										nRows=0;
										nCols=0;
										nEl=0;
									end
									order(iOrder,4)=nEl;
									order(iOrder,6)=nRows;
									order(iOrder,7)=nCols;
									bOK=true;
								end
								O(iOp1:jD)=-iOrder;
							end
						case -1	% function
							if O(iD+1)<0
								bOK=true;
								order(iOrder,4)=1;
								order(iOrder,5)=O(iD+1);
								iOp2=find(O==O(iD+1),1,'last');
								O(iD:iOp2)=-iOrder;
							end
						case 0
							switch opOrder{iOpType,2}{B}
								case 'var'
									order(iOrder,6)=-1;
								case 'number'
									order(iOrder,6)=-2;
								%..., string? (zie bij maken D?)!!!!!!!!!
							end
							order(iOrder,5)=D(5,iD);
							O(iD)=-iOrder;
							bOK=true;
						case 1
							switch opOrder{iOpType,2}{2,B}
								case -1
									iOp1=iD-1;
									bOK=true;
								case 0
									if iD==1
										iOp1=iD+1;
										bOK=true;
									elseif iD==length(O)
										iOp1=iD-1;
										bOK=true;
									else
										if O(iD-1)<=0	% previous already processed
											iOp1=iD-1;
											bOK=true;
											if O(iD+1)<=0
												warning('IFormula:unknownDirSingleOp'	...
													,'Unknown direction of possible operand!')
											end
										elseif O(iD+1)<=0
											iOp1=iD+1;
											bOK=true;
										end
									end
									if iOp1<iD&&any(D(2,iD)==[21 22])	% ++ or --
										D(2,iD)=D(2,iD)+2;
									end
								case 1
									iOp1=iD+1;
									bOK=true;
								otherwise
									error('Impossible direction of operand')
							end
							if ~bOK
								% do nothing
							elseif O(iOp1)>0
								bOK=false;
							else
								iOp1=find(O==O(iOp1),1);
								iOp2=find(O==O(iOp1),1,'last');
								order(iOrder,5)=O(iOp1);
								O(iOp1:iOp2)=-iOrder;
								O(iD)=-iOrder;
							end
						case 2
							iOp1=iD-1;
							iOp2=iD+1;
							if O(iOp1)<=0
								iOp1=find(O==O(iOp1),1);
								if O(iD)==INTFORMops.iOpSField||O(iD)==INTFORMops.iOpSPfield
									order(iOrder,5)=O(iOp1);
									order(iOrder,6)=iOp2;
									O([iOp1 iD iOp2])=-iOrder;
									bOK=true;
								elseif O(iOp2)<=0
									iOp2=find(O==O(iOp2),1,'last');
									order(iOrder,5)=O(iOp1);
									order(iOrder,6)=O(iOp2);
									O(iOp1:iOp2)=-iOrder;
									bOK=true;
								end
								%!!!!!!!!!! add: iOpTypeEff=0 if comma
							end
						case 3	% only <cond>?<vTrue>:<vFalse>
							iOp1=iD-1;
							iOp2=iD+1;
							iOp3=iOp2+1;
							while iOp3<length(O)&&O(iOp3)~=71
								iOp3=iOp3+1;
							end
							if O(iOp3)~=71
								error('c?v1:v2-structure without '':''-part?')
							end
							iOp3=iOp3+1;
							if all(O([iOp1 iOp2 iOp3])<=0)
								iOp1=find(O==O(iOp1),1);
								iOp2=find(O==O(iOp2),1,'last');
								iOp3=find(O==O(iOp3),1,'last');
								order(iOrder,5)=O(iOp1);
								order(iOrder,6)=O(iOp2);
								order(iOrder,7)=O(iOp3);
								O(iOp1:iOp3)=-iOrder;
								bOK=true;
							end
							
						otherwise
							error('unknown operator type')
					end
					Bt(iD)=false;
					if bOK
						order(iOrder)=iD;
						order(iOrder,2)=iOpTypeEff;
						order(iOrder,3)=find(B);
						if all(Bok)
							iOpMin=iOpType;
						else
							iOpType=iOpMin;
							Bok(:)=true;
						end
						uO=unique(O);
						break;	% always "start again" after processing one operation
					else
						Bok(iD)=false;
						uO=unique(O(Bok));
						iOrder=iOrder-1;	% remove again
					end
				end		% while search operation
			end		% else if ~isempty(oList)
		end		% while ~empty(uO)
		if iOrder<size(order,1)
			order=order(1:iOrder,:);
		end
		
		function [nC,nR]=ExtractSize(kO,bArray)
			if D(2,order(kO,1))==INTFORMops.iOpComma
				if bArray
					D(2,order(kO,1))=INTFORMops.iOpColSep;
				end
				[nC1,nR1]=ExtractSize(-order(kO,5),bArray);
				[nC2,nR2]=ExtractSize(-order(kO,6),bArray);
				if nR1~=nR2
					error('Combining columns must have the same number of rows!')
				end
				nC=nC1+nC2;
				nR=nR1;
			elseif D(2,order(kO,1))==INTFORMops.iOpSemiC
				[nC1,nR1]=ExtractSize(-order(kO,5),bArray);
				[nC2,nR2]=ExtractSize(-order(kO,6),bArray);
				if nC1~=nC2
					error('Combining arrays must have the same number of columns!')
				end
				nC=nC1;
				nR=nR1+nR2;
			else
				nC=1;
				nR=1;
			end
		end		% function ExtractSize
	end		% function GetOpOrder
end		% function InterpreteFormula

function [i,V,nV]=FindVar(v,V,nV)
if nV==0
	nV=1;
	i=1;
	V{1}=v;
	return
end
i=find(strcmp(v,V(1:nV)));
if isempty(i)
	nV=nV+1;
	V{nV}=v;
	i=nV;
end
end		% function FindVar

function [v,bOK,VALs,V]=GetFormValue(D,V,order,varargin)
bOK=true;
if ~isempty(V)
	V=FillV(V,5,0,'bUpdated');
	V=FillV(V,4,0,'bUsed');
	V=FillV(V,3,false,'bVal');
end
idxStart=0;	% not yet used - but thought to be useful as vector/matrix reference
if ~isempty(varargin)
	setoptions({'idxStart'},varargin{:})
end
VALs=[num2cell(false(1,size(order,1)));num2cell(order(:,5)')];
for iOrd=1:size(order,1)
	iD=order(iOrd);
	if iD<1	% disabled
		continue
	end
	bVal=true;
	iUpdated=[];
	iUsed=[];
	v=[];
	op=D(2,iD);
	iOpType=order(iOrd,2);
	nArg=order(iOrd,4);
	Arg=cell(4,max(0,nArg));
	Arg(3,:)=num2cell(false(1,nArg));
	bNumeric=true;
	for i=1:nArg
		iArg=order(iOrd,4+i);
		if iArg>0
			bVal1=true;
			v=D(5,iArg);
		else
			bVal1=VALs{1,-iArg};
			v=VALs{2,-iArg};
		end
		if iscell(v)&&isscalar(v)
			v=v{1};
		end
		bVal=bVal&&bVal1;
		Arg{1,i}=v;
		Arg{2,i}=bVal1;
		if bVal1
			Arg{3,i}=isnumeric(v)||islogical(v);
			bNumeric=bNumeric&&Arg{3,i};
		end
		Arg{4,i}=iArg;
	end
	if iOpType==-1	% bracket
		if bVal
			if nArg==0
				v=[];
			else
				v=Arg{1};
				if IsArrayStruct(v)&&v.bNumeric
					v=v.el;
				end
			end
		end		% if bVal
	elseif iOpType==0
		%normally not needed "action"
		aaaaaaaaaaaaaaaaa=1;
	elseif iOpType<0
		error('Unknown "operator type" (%d)',iOpType)
	else
		switch nArg
			case 0
				switch op
					case 1	% var
						bVal=V{3,D(5,iD)};
						v=V{2,D(5,iD)};
					case 3	% number
						v=VALs{2,iOrd};
					case 28	% char
						v=char(D(5,iD));
					case 29	% string
						v=V{1,D(5,iD)};
					otherwise
						bVal=false;
				end
			case 1
				switch op
					case 2	% negate
						if bNumeric
							v=-v;
						else
							bVal=false;
						end
					case 5	% function
						iD=order(iOrd);
						iV=D(5,iD);
						if V{3,iV}
							fcn=V{2,iV};
							if ~isa(fcn,'function_handle')
								error('Error using a function')
							end
							if V{3,iV}>0
								if Arg{2}
									args=Arg{1};
									if IsArrayStruct(args)
										args=args.el;
									end
									if ~iscell(args)	% 1 argument
										args={args};
									end
									v=fcn(args{:});	% normal case
										%!!! functions without arguments!!
										%  ?also functions with multiple arguments?
								else
									v=[];
									bVal=false;
								end
							else	% special case
								v=fcn(Arg);	% normal case
								bVal=true;	%(!!!)
								bOK=true;%(!!!)
							end
						else
							bVal=false;
						end
					case 8	% !
						if bNumeric
							v=~v;
						else
							bVal=false;
						end
					case 9	% ~
						if bNumeric
							v=bitxor(uint32(v),uint32(2^32-1));
						else
							bVal=false;
						end
					case 21	% ++
						if bNumeric
							v=v+1;
						else
							bVal=false;
						end
						vNew=v;
						iUpdated=1;
						iUsed=1;
					case 22	% --
						if bNumeric
							v=v-1;
						else
							bVal=false;
						end
						vNew=v;
						iUpdated=1;
						iUsed=1;
					case 23	% r++
						vNew=v+1;
						iUpdated=1;
						iUsed=1;
					case 24	% r--
						vNew=v-1;
						iUpdated=1;
						iUsed=1;
					case 30		% transpose
						v = v';
					otherwise
						bVal=false;
				end
			case 2
				v1=Arg{1};
				v2=Arg{1,2};
				bVal=and(Arg{2,:});
				bNumeric=and(Arg{3,:})	...
					&&~isempty(v1)&&~isempty(v2)	...
					&&(all(size(v1)==size(v2))||isscalar(v1)||isscalar(v2));
				v=[];
				switch op
					case 7	% assign
						bVal=Arg{2,2};
						vNew=v2;
						iUpdated=1;
						iUsed=2;
						v=v2;
					case 11
						if bNumeric
							v=v1+v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 12
						if bNumeric
							v=v1-v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 13
						if bNumeric
							v=v1.*v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 14
						if bNumeric
							v=v1./v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 15	% <<
						if bNumeric
							v=v.*2.^v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 16	% >>
						if bNumeric
							v=floor(v./2.^v2);
						else
							bVal=false;
						end
						iUsed=1:2;
					case 17	% AND
						if bNumeric
							v=bitand(v1,v2);
						else
							bVal=false;
						end
						iUsed=1:2;
					case 18	% logAND
						if bNumeric
							v=v1&v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 19	% OR
						if bNumeric
							v=bitor(v1,v2);
						else
							bVal=false;
						end
						iUsed=1:2;
					case 20	% logOR
						if bNumeric
							v=v1||v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 26	% ^ (Matlab)
						if bNumeric
							v=v1^v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 27
						if bNumeric
							v=mod(v1,v2);
						else
							bVal=false;
						end
					case 31	% +=
						if bNumeric
							v=v1+v2;
						else
							bVal=false;
						end
						iUsed=1:2;
						vNew=v;
						iUpdated=1;
					case 32	% -=
						if bNumeric
							v=v1-v2;
						else
							bVal=false;
						end
						iUsed=1:2;
						vNew=v;
						iUpdated=1;
					case 33	% *=
						if bNumeric
							v=v1*v2;
						else
							bVal=false;
						end
						iUsed=1:2;
						vNew=v;
						iUpdated=1;
					case 34	% /=
						if bNumeric
							v=v1/v2;
						else
							bVal=false;
						end
						iUsed=1:2;
						vNew=v;
						iUpdated=1;
					case 35	% <<=
						if bNumeric
							v=v1*2^v2;
						else
							bVal=false;
						end
						iUsed=1:2;
						vNew=v;
						iUpdated=1;
					case 36	% >>=
						if bNumeric
							v=v1/2^v2;
						else
							bVal=false;
						end
						iUsed=1:2;
						vNew=v;
						iUpdated=1;
					case 40	% field reference
						if isstruct(v1)&&isfield(v1,V{1,v2})
							v=v1.(V{1,v2});
							bNumeric=isnumeric(v)||islogical(v);
						else
							bVal=false;
						end
						iUsed=1;
					case 42	% XOR
						if bNumeric
							v=bitxor(v1,v2);
						else
							bVal=false;
						end
						iUsed=1:2;
					case 44 % .*
						if bNumeric
							v=v1.*v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 45 % ./
						if bNumeric
							v=v1./v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 46 % .^
						if bNumeric
							v=v1.^v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 52	% indexing
						if isnumeric(v1)&&~isempty(v1)	...
								&&isnumeric(v2)&&isscalar(v2)
							v2=v2+1-idxStart;
							if v2>=1&&v2<=length(v1)&&v2==floor(v2)
								v=v1(v2);
							else
								bVal=false;
							end
						else
							bVal=false;
						end
						iUsed=1:2;
					case 60	% ==
						if bNumeric
							v=v1==v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 61	% !=
						if bNumeric
							v=v1~=v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 62	% ~=
						if bNumeric
							v=v1~=v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 63	% <
						if bNumeric
							v=v1<v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 64	% <=
						if bNumeric
							v=v1<=v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 65	% >
						if bNumeric
							v=v1>v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 66	% >=
						if bNumeric
							v=v1>=v2;
						else
							bVal=false;
						end
						iUsed=1:2;
					case 10	% ',' (argument list)
						if ~IsArrayStruct(v1)
							v1=struct('type',op,'bVal',bVal	...
								,'bNumeric',bNumeric,'el',{{v1}});
						end
						v1.el{1,end+1}=v2;
						v=v1;
						iUsed=1:2;
					case {96,97}	% ',' / ';'
						% !update bNumeric is nog niet in orde
						bStr1=IsArrayStruct(v1);
						bStr2=IsArrayStruct(v2);
						if bStr1
							if bStr2
								if op==96	% possible?
									if v1.bNumeric&&v2.bNumeric
										v1.el=[v1.el v2.el];
									elseif v1.bNumeric
										v1.el=[{v1.el} v2.el];
									elseif v2.bNumeric
										v1.el=[v1.el {v2.el}];
									else
										v1.el=[v1.el v2.el];
									end
								else	% op==97
									if v1.bNumeric&&v2.bNumeric
										v1.el=[v1.el;v2.el];
									elseif v1.bNumeric
										v1.el=[{v1.el};v2.el];
									elseif v2.bNumeric
										v1.el=[v1.el;{v2.el}];
									else
										v1.el=[v1.el;v2.el];
									end
								end		% if op
							else	% if isstruct(v2)
								if op==96
									if v1.bNumeric
										v1.el=[v1.el v2];
									else
										v1.el=[v1.el {v2}];
									end
								else	% op==97
									if v1.bNumeric
										v1.el=[v1.el;v2];
									else
										v1.el=[v1.el;{v2}];
									end
								end		% if op
							end		% if isstruct(v2)
							v=v1;
						else
							if bNumeric
								if op==96
									el=[v1 v2];
								else
									el=[v1;v2];
								end
							else
								el=Arg(1,:);
								if op==97
									el=el';
								end
							end
							v=struct('type',op,'bVal',bVal	...
								,'bNumeric',bNumeric,'el',{el});
						end
					otherwise
						bVal=false;
				end
			case 3	% only <cond>?<vTrue>:<vFalse>
				v1=Arg{1};
				v2=Arg{1,2};
				v3=Arg{1,3};
				bVal=all([Arg{2,:}]);
				bNumeric=all([Arg{3,:}])	...
					&&~isempty(v1)&&~isempty(v2)&&~isempty(v3)	...
					&&(all(size(v1)==size(v2))||isscalar(v1)||isscalar(v2));
				if bNumeric&&isscalar(v1)
					if v1
						v=v2;
					else
						v=v3;
					end
					bVal=true;
				else
					v=[];
				end
			otherwise
				bVal=false;
		end		% switch nArg
	end		% if iOpType>0
	bOK=bOK&&bVal;
	if bVal
		VALs{1,iOrd}=bVal;
		VALs{2,iOrd}=v;
	end
	for i=iUsed
		iV=GetVarIdx(Arg{4,i},order,D);
		if iV>0
			if V{5,iV}==0	% only assign "used" if not (yet) written
				V{4,iV}=1;
			end
		end
	end
	for i=iUpdated
		iV=GetVarIdx(Arg{4,i},order,D);
		if iV>0
			V{5,iV}=1;
			V{2,iV}=vNew;
			V{3,iV}=bVal;
		end
	end
end		% for iOrd
if isempty(VALs)
	error('What''s hapenning?')
else
	v=VALs{2,end};
end
end		% function GetFormValue

function V=FillV(V,i,vDefault,typ)
if size(V,1)<i
	V(i,:)=num2cell(vDefault(1,ones(1,size(V,2))));
else
	nV=cellfun('length',V(i,:));
	if any(nV~=1)
		if any(nV>1)
			error('Impossible input for V (length(%s)>1)',typ)
		end
		V(i,nV==0)=num2cell(vDefault(1,ones(1,sum(nV==0))));
	end
end
end		% function FillV

function iV=GetVarIdx(iArg,order,D)
if iArg<0
	iArg=-iArg;
	if order(iArg,2)~=1
		iV=-1;
		return
	end
	iArg=order(iArg);
end
if D(2,iArg)==1
	iV=D(5,iArg);
elseif any(D(2,iArg)==[3 28 29])	% constants (number,char,string)
	iV=0;
else
	error('A variable or number is expected! - this shouldn''t happen!')
end
end

function opNames=GetOpNames()
opNames={'var','negate','number','ptrRef','function'	... 1.. 5
	,'ptr','=','!','~',','				...  6..10
	,'+','-','*','/','<<'				... 11..15
	,'>>','AND','logAND','OR','logOR'	... 16..20
	,'++','--','++r','--r','typeRef'	... 21..25
	,'power','%','char','string','transpose' ... 26..30
	,'+=','-=','*=','/=','<<='			... 31..35
	,'>>=','','','','.'					... 36..40
	,'->','XOR','','.*','./'			... 41..45
	,'.^','','','','('					... 46..50
	,')','[',']','{','}'				... 51..55
	,'tS','tE','','','=='				... 56..60
	,'!=','~=','<','<=','>'				... 61..65
	,'>=','','','','?'					... 66..70
	,':','','','',''					... 71..75
	,'','','','',''						... 76..80
	,'','','','',''						... 81..85
	,'','','','',''						... 86..90
	,'field','','','','type'			... 91..95
	,'colSep',';','end','err'			... 96..99
	};
end

function bStr=IsArrayStruct(v)
	bStr=isstruct(v)&&isequal(fieldnames(v)	...
		,{'type';'bVal';'bNumeric';'el'});
end

% types
%     1 : variable
%     2 : negate
%     3 : number
%     4 : pointer reference (*)   (*var)
%     5 : function
%     6 : pointer
%     7 : assign
%     8 : NOT (!)
%     9 : bitwise NOT (~)
%    10 : ','
%    11 : +
%    12 : -
%    13 : *
%    14 : /
%    15 : <<
%    16 : >>
%    17 : AND
%    18 : logical AND
%    19 : OR
%    20 : logical OR
%    21 : increase
%    22 : decrease
%    23 : increaseR
%    24 : decreaseR
%    25 : typeRef (type*)
%    26 : ^ (Matlab)
%    27 : %
%    28 : char
%    29 : string
%    30 : transpose
%    31 : +=
%    32 : -=
%    33 : *=
%    34 : /=
%    35 : <<=
%    36 : >>=
%    37 : 
%    38 :
%    39 :
%    40 : '.'
%    41 : ->
%    42 : XOR
%    43 :
%    44 : .* (Matlab)
%    45 : ./ (Matlab)
%    46 : .^ (Matlab)
%    47 :
%    48 :
%    49 :
%    50 : (
%    51 : )
%    52 : [
%    53 : ]
%    54 : {
%    55 : }
%    56 : typeStart
%    57 : typeEnd
%    58 :
%    59 :
%    60 : ==
%    61 : !=
%    62 : ~=
%    63 : <
%    64 : <=
%    65 : >
%    66 : >=
%    67 :
%    68 :
%    69 :
%    70 : ?
%    71 : :
%    72 :
%    73 :
%    74 :
%    75 :
%    76 :
%    77 :
%    78 :
%    79 :
%    80 :
%    81 :
%    82 :
%    83 :
%    84 :
%    85 :
%    86 :
%    87 :
%    88 :
%    89 :
%    90 :
%    91 : field
%    92 :
%    93 :
%    94 :
%    95 : type
%    96 : , (next column) ---- not implemented!!!!!
%    97 : ; (next row) (added for non-C-programs...)
%    98 : end (;)
%    99 : error
