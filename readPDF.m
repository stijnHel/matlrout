function D=readPDF(fName,varargin)
%readPDF  - Read PDF file (to retrieve information from it, not for display)
%   D=readPDF(fName)
%
%       based on PDF32000.book (PDF32000_2008.pdf)
%
%!!!!only in early development!!!!
% based on PDF 32000-1:2008 (PDF32000_2008.pdf)

bTESTEOL=nargout==0;
if nargin>1
	setoptions({'bTESTEOL'},varargin{:})
end

bBlank=false(1,256);
bBlank(1+[9 10 13 32])=true;
bDelim=false(1,256);
bDelim(1+('()<>[]{}/%'))=true;

if isa(fName,'uint8')
	x = char(fName);
else
	fid=fopen(fName);
	if fid<3
		error('Can''t open the file')
	end
	x=char(fread(fid,[1 Inf],'*uint8')); %#ok<FREAD>
	fclose(fid);
end

cEOL=x(end);
bDEOL=cEOL==10&&x(end-1)==13;
if cEOL~=10&&cEOL~=13
	iLF=find(x==10);
	iCR=find(x==13);
	if isempty(iCR)
		if isempty(iLF)
			printhex(x(1:min(32,end)))
			error('No LF or CR in start???')
		end
		cEOL=newline;
	elseif isempty(iLF)
		cEOL=char(13);
	else
		if iLF(1)~=iCR(1)+1
			warning('READPDF:strangeLRCR','Strange LF/CR combination')
			bDEOL=-1;	% unknown
		else
			bDEOL=true;
		end
		cEOL=newline;
	end
end
BEOL=x==cEOL;

if bTESTEOL
	%%%%%%%!!!!TEST!!!!%%%%%%%
	BEOL=x==10|x==13;
	for i_x=1:length(x)-1
		if x(i_x)==13&&x(i_x+1)==10
			BEOL(i_x+1)=false;
		end
	end
	bDEOL=-1;
	%%%%%%%!!!!TEST!!!!%%%%%%%
end
iEOL=find(BEOL);
if x(end)~=cEOL
	iEOL(end+1)=length(x)+1;
	if bDEOL>0
		iEOL(end)=iEOL(end)+1;
	end
end
nLines=length(iEOL);

l=GetLine(1);
if ~strncmp(l,'%PDF-',5)
	error('Bad head of PDF-file')
end
if ~strcmp(GetLine(nLines),'%%EOF')
	error('Bad end of file')
end
[PDFver,n]=sscanf(l(6:end),'%d.%d',[1 2]);
if n<2
	error('Bad head of PDF-file (version couldn''t be extracted)')
end
bBinData=any(GetLine(2)>127);
trailer=readTRAILER;
XREF=readXREF(trailer.iStartxref);
Dtrailer=MakeStruct(trailer.T);
bPrevious=isfield(Dtrailer,'Prev');
if bPrevious
	XREF0=XREF;
	XREF=readXREF(Dtrailer.Prev);
end
Nodes=GetNodes();
trailerTypes=[trailer.T{4,:}];

iNodes=find(XREF.typ=='n');
NNr=cat(1,Nodes(iNodes).objNr);
iStart=Dtrailer.Root;
iNstart=FindNode(iStart);
Dcatalog=MakeStruct(Nodes(iNstart).O);
Npages=Dcatalog.Pages;
iPages=FindNode(Npages);
sPages=MakeStruct(Nodes(iPages).O);
NPages=sPages.Kids;
nPages=size(NPages,2);	% should be equal to sPages.Count (denk ik toch...)
Pages=cell(3,nPages);
cStat=cStatus(sprintf('Reading %d pages',nPages),0);
for iPage=1:nPages
	try
		nP=MakeStruct(Nodes(FindNode(NPages{1,iPage})).O);
		A=Nodes(FindNode(nP.Contents)).O;
		Pages{2,iPage}=A.S;
		if isfield(A,'err')&&~isempty(A.err)
			warning('Page %d not read - because of decoding error',iPage)
		else
			[STxt,TXT]=ReadContents(A.S);
			Pages{1,iPage}=STxt;
			Pages{3,iPage}=TXT;
		end
	catch err1
		DispErr(err1)
		warning('Problem reading page %d!',iPage)
	end
	cStat.status(iPage/nPages)
end
cStat.close()

D=var2struct(PDFver,bBinData,Dtrailer,trailerTypes,XREF,Nodes	...
	,Dcatalog,sPages,Pages);
if bPrevious
	D.PrevXREF=XREF0;
end

	function l=GetLine(iL)
		if iL==1
			i1=0;
		else
			i1=iEOL(iL-1);
			if false&&bDEOL<0&&x(i1+1)==10	%!!!!test
				i1=i1+1;
			end
		end
		ilEnd=iEOL(iL)-1;
		if bDEOL>0
			ilEnd=ilEnd-1;
		elseif bDEOL<0
			if x(ilEnd)==13
				ilEnd=ilEnd-1;
			end
		end
		l=x(i1+1:ilEnd);
	end

	function XREF=readXREF(iStart)
		loop=true;
		ix=iStart;
		[sXref,~,~,iNxt]=sscanf(x(ix:ix+20),'%s\n',1);
		if ~strcmp(sXref,'xref')
			error('Bad XREF');
		end
		ix=ix+iNxt-1;
		SS=struct('offset',cell(1,20),'genNumber',[],'typ',[]);	% !!!
		nSubS=0;
		while loop
			loop=false;	% !!!?
			nSubS=nSubS+1;
			[subsection,~,~,iNxt]=sscanf(x(ix:ix+20),'%d %d',2);
			ix=ix+iNxt;
			while bBlank(1+(x(ix)))
				ix=ix+1;
			end
			S=reshape(x(ix:ix+subsection(2)*20-1),20,subsection(2));
			SS(nSubS).offset=sscanf(reshape(S(1:11,:),1,[]),'%d')';
			SS(nSubS).genNumber=sscanf(reshape(S(11:16,:),1,[]),'%d')';
			SS(nSubS).typ=S(18,:);
		end
		XREF=SS(1:nSubS);
		
	end

	function TRAILER=readTRAILER()
		sStartxref=GetLine(nLines-2);
		if isempty(strfind(sStartxref,'startxref'))
			error('No startxref on the right place?')
		end
		iStartxref=str2double(GetLine(nLines-1));
		iLineStart=nLines-3;
		while ~strcmp(GetLine(iLineStart),'trailer')
			iLineStart=iLineStart-1;
			if iLineStart<5
				error('Problem when searching for trailer start')
			end
		end
		T=ReadObject(x(iEOL(iLineStart)+1:end));
		TRAILER=var2struct(T,iStartxref);
	end

	function N=GetNode(i)
		i1=XREF.offset(i);
		i2=XREF.offset(XREF.offset>i1&XREF.typ=='n');
		if isempty(i2)
			i2=trailer.iStartxref;
		end
		s=x(i1+1:min(i2)-1-bDEOL);
		[objNr,nNr,~,iNxt]=sscanf(s,'%d %d ',2);
		if nNr<2
			warning('READPDF:NoObjNrs','No object numbers - something will go wrong!!')
		end
		s=s(iNxt:end);
		[sTst,~,~,iNxt]=sscanf(s,'%s',1);
		if strcmp(sTst,'obj')
			while bBlank(1+(s(iNxt)))
				iNxt=iNxt+1;
			end
			s=s(iNxt:end);
		else
			warning('READPDF:NoObjStart','Not the right start for an object?')
		end
		[O,typ,ns]=ReadObject(s);
		sRest=s(ns:end);
		[s1,~,~,ns1]=sscanf(sRest,'%s',1);
		if strcmp(s1,'stream')
			if typ~=7
				error('Stream must start with dictionary object!!')
			end
			typ=8;
			C=O;
			[O,ns]=ReadStream(sRest,C);
			D1=MakeStruct(C);
			if isfield(D1,'Filter')
				switch D1.Filter
					case 'FlateDecode'
						try
							O.S=char(zuncompr(uint8(O.S)));
						catch err
							O.err=err;
							DispErr(err)
							warning('Error during decompression!')
						end
					case 'DCTDecode'
						try
							fprintf('JPG (%d)\n',length(O.S))
							O.S=cjpeg(uint8(O.S));
						catch err
							DispErr(err)
							warning('Error during cjpeg-interpretation!')
						end
					otherwise
						warning('READPDF:NotImplementedStreamEncoding'	...
							,'Not implemented encoding of the stream (%s)'	...
							,D1.Filter)
				end
			end
			sRest=sRest(ns:end);
			[s1,~,~,ns1]=sscanf(sRest,'%s',1);
		end
		if strcmp(s1,'endobj')
			sRest=sRest(ns1:end);
			% OK
		end
		if ~isempty(sRest)&&~all(bBlank(abs(sRest)+1))
			warning('READPDF:unprocessedData','Unprocessed data? (node %d)',i)
		end
		N=struct('objNr',objNr','O',{O},'typ',typ);
	end

	function NN=GetNodes()
		NN=[];
		% read them in this order? or start with "start object"?
		for i=1:length(XREF.typ)
			if XREF.typ(i)=='n'
				N=GetNode(i);
				if isempty(NN)
					N0=N;
					f=fieldnames(N);
					for j=1:length(f)
						N0.(f{j})=[];
					end
					NN=N0;
					NN(1,length(XREF.typ))=N0;
				end
				NN(i)=N; %#ok<AGROW>
			end
		end
	end

	function [O,typ,ns]=ReadObject(s)
		[s1,~,~,ns]=sscanf(s,'%s',1);
		b=bDelim(1+(s1(2:end)));
		if length(s1)>1&&any(b)
			i=find(b,1);
			ns=ns-length(s1)+i;
			s1=s1(1:i);
		end
		typ=0;
		if isempty(s1)	% possible?
			O=[];
			ns=0;
			warning('READPDF:EmptyS','Empty string for object reading?')
			return
		elseif strcmp(s1,'true')
			typ=2;
			O=true;
			ns=5;
		elseif strcmp(s1,'false')
			typ=2;
			O=false;
			ns=6;
		else
			iS1=ns-length(s1);
			switch s1(1)
				case '%'	% comment
					typ=-1;
					ns=iS1+1;
					while ns<=length(s)&&s(ns)~=10&&s(ns)~=13
						ns=ns+1;
					end
					O=s(iS1+1:ns-1);
					while ns<=length(s)&&(s(ns)==10||s(ns)==13)
						ns=ns+1;
					end
				case '('	% string
					typ=42;
					nbrack=1;
					ns=iS1+1;
					b=false(1,length(s));
					while nbrack>0
						if ns>length(s)
							error('end of string not found')
						end
						if s(ns)=='('
							nbrack=nbrack+1;
							b(ns)=true;
						elseif s(ns)==')'
							nbrack=nbrack-1;
							b(ns)=true;
						elseif s(ns)=='\'
							if s(ns+1)>='0'&&s(ns+1)<='7'
								s(ns)=char(sscanf(s(ns+1:ns+3),'%o'));
								b(ns)=true;
								ns=ns+3;
							elseif s(ns+1)=='n'
								s(ns)=10;
								b(ns)=true;
								ns=ns+1;
							elseif s(ns+1)=='r'
								s(ns)=13;
								b(ns)=true;
								ns=ns+1;
							elseif s(ns+1)=='t'
								s(ns)=9;
								b(ns)=true;
								ns=ns+1;
							elseif s(ns+1)=='b'
								s(ns)=8;
								b(ns)=true;
								ns=ns+1;
							elseif s(ns+1)=='f'
								% ??
							elseif s(ns+1)=='('
								ns=ns+1;
								b(ns)=true;
							elseif s(ns+1)==')'
								ns=ns+1;
								b(ns)=true;
							elseif s(ns+1)=='\'
								ns=ns+1;
								b(ns)=true;
							elseif s(ns+1)==10
								ns=ns+1;
							else
								error('Wrong escape sequence')
							end
						elseif s(ns)==13
							if s(ns+1)==10
								ns=ns+1;
							else
								s(ns)=10;
							end
							b(ns)=true;
						else
							b(ns)=true;
						end
						ns=ns+1;
					end
					b(ns-1)=false;
					O=s(b);
				case '/'	% name object
					typ=5;
					O=s1(2:end);
					%!!!!add special characters (using #)
				case '['	% array object
					typ=6;
					ns=iS1+1;
					nO=0;
					O=cell(2,1000);
					while ns<=length(s)&& s(ns)==' '	% go to first nonblank char
						ns=ns+1;	% to detect empty arrays
					end
					while ns<=length(s)&&s(ns)~=']'
						[O1,typ1,ns1]=ReadObject(s(ns:end));
						ns=ns+ns1-1;
						nO=nO+1;
						if nO>size(O,2)
							O{1,nO+10000}=[];	% increase size
						end
						O{1,nO}=O1;
						O{2,nO}=typ1;
					end
					if ns<=length(s)
						ns=ns+1;
					end
					O=O(:,1:nO);
					uT=unique([O{2,:}]);
					if all(uT==3)	% pure numeric array
						O=[O{1,:}];
					end
				case '<'	% hexadecimal data / dictionary object
					if s(iS1+1)=='<'	% dictionary object or stream
						typ=7;
						ns=iS1+2;
						nO=0;
						O=cell(4,1000);
						while ~strcmp(s(ns:ns+1),'>>')
							[N,typN,ns1]=ReadObject(s(ns:end));	% should be a name object
							ns=ns+ns1-1;
							[O1,typ1,ns1]=ReadObject(s(ns:end));	% should be a name object
							ns=ns+ns1-1;
							nO=nO+1;
							O{1,nO}=N;
							O{2,nO}=typN;
							O{3,nO}=O1;
							O{4,nO}=typ1;
						end
						ns=ns+2;
						O=O(:,1:nO);
					else
						typ=43;	% hexadecimal string
						% direct use of s1?
						%   ?possible problem with:
						%      "broken string"
						%      string directly followed by ... (possible?)
						ns=iS1+1;
						while s(ns)~='>'	% should only be HEX or '>'!!
							ns=ns+1;
						end
						O=s(iS1+1:ns-1);
						if rem(length(O),2)
							O(1,end+1)='0';
						end
						O=char(sscanf(O,'%02x'))';
						ns=ns+1;
					end
				case {'0','1','2','3','4','5','6','7','8','9','.','-','+'}
					[oNr,nCh,~,i]=sscanf(s,'%d %d %c',3);
					if nCh==3&&oNr(3)=='R'	% indirect object reference
						typ=10;
						ns=i;
						O=oNr(1:2)';
					else
						typ=3;
						[O,nCh,err,ns]=sscanf(s,'%g',1);	% (not with str2double for terminating characters)
						if nCh<1
							error('error translating a number (%s)',err)
						end
					end
				otherwise
					typ=20;
					O=s1;
			end		% switch
		end		% ~empty(s)
		while ns<=length(s)&&bBlank(1+(s(ns)))
			ns=ns+1;
		end
	end		% function ReadObject
	
	function [S,ns]=ReadStream(s,D)
		[s1,~,~,ns]=sscanf(s,'%s',1);
		if ~strcmp(s1,'stream')
			error('Wrong start of stream!!')
		end
		% !!!
		i=strfind(s,'endstream');
		if isempty(i)
			error('Stream not ended!')
		end
		if length(i)>1
			warning('READPDF:MultiStream','Multiple streams within one object!')
		end
		S=struct('D',{D},'S',strtrim(s(ns:i(1)-1)));
		ns=i(1)+9;
	end

	function D=MakeStruct(C)
		if size(C,1)==4
			C=C([1 3],:);
		end
		for i=1:size(C,2)
			if iscell(C{2,i})
				C{2,i}=C(2,i);
			end
		end
		D=struct(C{:});
	end

	function i=FindNode(ii)
		if iscell(ii)	% check if size == [2 1] && ii{2}==[10]?
			if ~isequal(size(ii),[2 1])||~isequal(ii{2},10)
				warning('verkeerd gedacht... (node reference)')
			end
			ii=ii{1};	%	--> reference
		end
		i=find(NNr(:,1)==ii(1)&NNr(:,2)==ii(2));
		if length(i)~=1
			error('Can''t find requested node')
			% !!!! should refer to NULL-object!!
		end
		i=iNodes(i);
	end

	function [STxt,TXT]=ReadContents(Sraw)
		% Table 57 - Graphics State Operators:
		LgraphStOp={'q',0;'Q',0;'cm',6;'w',1;'J',1;'j',1;'M',1;
			'd',2;'ri',1;'i',1;'gs',1};
		% Table 59 - Path Construction Operators:
		LpathConstOp={'m',2;'l',2;'c',6;'v',4;'y',4;'h',0;'re',4};
		% Table 60 ? Path-Painting Operators
		LpathPaintOp={'S',0;'s',0;'f',0;'F',0;'f*',0;'B',0;'B*',0;
			'b',0;'b*',0;'n',0};
		% Table 61 ? Clipping Path Operators
		LclipPathOp={'W',0;'W*',0};
		% Table 74 ? Colour Operators
		LColOp={'CS',1;'cs',1;'SC',-1;'SCN',-1;'sc',-1;'scn',-1;'G',1;
			'g',1;'RG',3;'rg',3;'K',4;'k',4};
		% Table 77 ? Shading Operator
		LshadOp={'sh',1};
		% Table 87 ? XObject Operator
		LXobjOp={'Do',0};
		% Table 92 ? Inline Image Operators
		LinlImgOp={'BI',0;'ID',0;'EI',0};
		% Table 105 ? Text state operators
		LtxtStatOp={'Tc',1;'Tw',1;'Tz',1;'TL',1;'Tf',1;'Tr',1;'Ts',1};
		% Table 107 ? Text object operators
		LtxtObjOp={'BT',0;'ET',0};
		% Table 108 ? Text-positioning operators
		LtxtPosOp={'Td',2;'TD',2;'Tm',6;'T*',0};
		% Table 109 ? Text-showing operators
		LtxtShowOp={'Tj',1;'''',1;'"',3;'TJ',1};
		% Table 113 ? Type 3 font operators
		LtxtTyp3FontOp={'d0',2;'d1',6};
		LOP={LgraphStOp,LpathConstOp,LpathPaintOp,LclipPathOp,LColOp	...
			,LshadOp,LXobjOp,LinlImgOp,LtxtStatOp,LtxtObjOp		...
			,LtxtPosOp,LtxtShowOp,LtxtTyp3FontOp};
		nOP=cumsum(cellfun('size',LOP,1));
		LOP=cat(1,LOP{:});
		if length(unique(LOP(:,1)))~=size(LOP,1)
			error('Dupplicated operands!! - program bug!!!')
		end
		STxt=cell(4,100000);
		nS=0;
		i=1;
		while i<=length(Sraw)
			[O,typ,ns]=ReadObject(Sraw(i:end));
			typ2=[];
			if typ==20
				b=strcmp(LOP(:,1),O);
				if any(b)
					iO=find(b);
					typ=100+find(nOP>=iO,1);
					if typ>101
						typ2=iO-nOP(typ-101);	% item number in sublist
					else
						typ2=typ-100;
					end
					nO=LOP{iO,2};
					if nO>nS
						warning('READPDF:HiNumOp','High number of operands!')
						nO=nS;
					end
					if nO>0
						nS=nS-nO;
						STxt{4,nS+1}=O;
						if nO==1
							O=STxt{1,nS+1};
						else
							O=STxt(1,nS+1:nS+nO);
						end
					end
				end
			end
			nS=nS+1;
			if nS>size(STxt,2)
				STxt{1,nS+10000}=[];
			end
			STxt{1,nS}=O;
			STxt{2,nS}=typ;
			STxt{3,nS}=typ2;
			i=i+ns-1;
		end
		STxt=STxt(:,1:nS);
		tp=[STxt{2,:}];
		iTxt=find(tp==112);	% show text operators
		TXT=cell(2,length(iTxt));
		TXT(2,:)={char(10)};
		for i=1:length(iTxt)
			if ischar(STxt{1,iTxt(i)})
				TXT{1,i}=STxt{1,iTxt(i)};
			else
				TXT{1,i}=[STxt{1,iTxt(i)}{1,1:2:end}];
			end
		end
	end

end
