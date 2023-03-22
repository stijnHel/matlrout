function S=readxml(fname,bFlat,bSimplify,bStruct,varargin)
%readxml  - Reads an xml-like format
%    S=readxml(fname[,bFlat[,bSimplify,bStruct]])
%    S=readxml({<text>}[,bFlat])
%         bFlat: flatten structure - default true(!)
%         bSimplify: Remove data added for reading (default true)
%         bStruct: replace structure with children, by direct struct-fields
%    S=readxml(Sflat[,bSimplify])

blankChars=false(1,255);
cBrackCharsOpen='([{';
cBrackCharsClose=')]}';
brackChars={cBrackCharsOpen,cBrackCharsClose;blankChars,blankChars};
blankChars([9 10 13 32])=true;
tagChars=false(1,255);
tagChars([abs('a'):abs('z') abs('A'):abs('Z') abs('0'):abs('9') abs(':_-')])=true;
for i=1:2
	brackChars{2,i}(abs(brackChars{1,i}))=true;
end
bBrackCharsOpen=brackChars{2,1};
shortTags={};
bWarning = true;

if nargin>1 && ischar(bFlat)	% (better to work with all varargin's!)
	if nargin==2
		options = {bFlat};
	elseif nargin==3
		options = {bFlat,bSimplify};
	elseif nargin>=4
		options = [{bFlat,bSimplify,bStruct},varargin];
	end
	bFlat = [];
	bSimplify = [];
	bStruct = [];
	setoptions({'bFlat','bSimplify','bStruct','bWarning'},options{:})
	if isempty(bFlat) && (bSimplify || bStruct)
		bFlat = false;
	end
elseif nargin<4
	bStruct=[];
	if nargin<3
		bSimplify=[];
		if nargin<2
			bFlat=[];
		end
	end
end
if isempty(bStruct)
	bStruct = false;
end
if isempty(bSimplify)
	bSimplify = true;
end
if isempty(bFlat)
	bFlat = true;
end
if iscell(fname)
	if length(fname)>1
		x=sprintf('%s\n',fname{:});
	else
		x=fname{1};
	end
	fname='direct-input';
elseif isstruct(fname)&&isfield(fname,'type')
	S=Structure(fname,bFlat,bStruct);
	return
else
	fid=fopen(fFullPath(fname),'r');
	if fid<3
		error('Can''t open the file')
	end
	
	x=fread(fid,[1 1e8],'*char');
	if ~feof(fid)
		fseek(fid,0,'eof');
		warning('Only start of file read!!! (%d / %d bytes)',length(x),ftell(fid))
	end
	fclose(fid);
end
if any(x==0)
	warning('READXML:zeroChars','!!??''zero chars'' in the file??')
	x(x==0)=[];
end

S=struct('type',0,'tag',cell(1,500),'from',0,'fields',[],'data',[],'closed',[]);
[sTxtType,nBytes]=GetTextType(x);
% (!!) do something with sTxtType!
i=1+nBytes;
ilast=i;
nS=1;
S(1).tag='root';
S(1).from=fname;
currentS=1;
Shier=ones(1,100);
nHier=1;
while i<length(x)	% ('<' - at least two characters have to be read)
	if x(i)=='<'
		s=getdata(x,ilast,i);
		if ~isempty(s)
			if isempty(S(currentS).data)
				S(currentS).data={s};
			else
				S(currentS).data{end+1}=s;
			end
		end
		if x(i+1)=='?'
			[tag,fields,I,i]=readtag(x,i+1);
			if isempty(I.last)||I.last~='?'
				if bWarning
					warning('READXML:badClose','!no good closing of ''<?''-tag')
				end
			end
			nS=nS+1;
			S(nS).type=1;
			S(nS).tag=tag;
			S(nS).from=currentS;
			S(nS).fields=fields;
		elseif x(i+1)=='!'
			if strcmpi(x(i:i+8),'<![CDATA[')
				[s,i]=ReadCData(x,i);
				nS=nS+1;
				S(nS).type=3;
				S(nS).tag='CDATA';
				S(nS).from=currentS;
				S(nS).data=s;
			elseif strcmpi(x(i:i+8),'<!DOCTYPE')
				[tag,fields,~,i]=readtag(x,i+2);
				nS=nS+1;
				S(nS).type=1;
				S(nS).tag=tag;
				S(nS).from=currentS;
				S(nS).fields=fields;
			elseif strcmp(x(i:i+3),'<!--')&&i+5<length(x)
				j=i+2;
				b=false;
				while ~b&&j<length(x)-2
					j=j+1;
					b=strcmp(x(j:j+2),'-->');
				end
				if b
					nS=nS+1;
					S(nS).type=1;
					S(nS).tag='comment';
					S(nS).from=currentS;
					S(nS).fields={'text',x(i+4:j-1)};
					i=j+2;
				else
					if bWarning
						warning('READXML:nonClosedComment','Comment block not closed! - reading stopped')
					end
					break;
				end
			else
				warning('READXML:nonCDATA','Is this possible? (%s)',x(i:i+8))
				[tag,fields,~,i]=readtag(x,i+2);
				nS=nS+1;
				S(nS).type=1;
				S(nS).tag=tag;
				S(nS).from=currentS;
				S(nS).fields=fields;
			end
		elseif x(i+1)=='/'	% end tag
			[tag,fields,~,i]=readtag(x,i+2);
			if ~isempty(fields)
				if bWarning
					warning('READXML:ClosingTagField','no fields expected in a closing tag')
				end
			end
			b=true;
			bOK=true;
			nHierLast=nHier;
			while ~strcmpi(tag,S(currentS).tag)
				b=false;
				if bWarning
					warning('READXML:NoCloseTag','(#%4d-%2d)?no closing tag (%s)?',nS,nHier,S(currentS).tag)
				end
				nHier=nHier-1;
				currentS=Shier(nHier);
				if currentS<2
					if bWarning
						warning('READXML:NoClosingTag','??couldn''t find closing tag (%s) - stopped reading file!! - or tried to continue....',tag)
					end
					nHier=nHierLast;
					currentS=Shier(nHier);
					bOK=false;
					break
				end
			end
			if currentS<2
				break
			end
			if b
				S(currentS).closed=nS;
			end
			if bOK
				nHier=nHier-1;
				currentS=Shier(nHier);
			end
		else
			[tag,fields,I,i]=readtag(x,i+1);
			if strcmpi(tag,'html')
				shortTags={'meta','hr','img'};
			elseif nHier>1&&false	% wanted a test for optionally closing tags
				%...&&any(strcmpi(shortTags,S(currentS).tag))
				% close tag automatically
				nHier=nHier-1;
				currentS=Shier(nHier);
			end
			nS=nS+1;
			if nS>length(S)
				S(nS+100).tag=0;	% increase size of S
			end
			S(nS).type=2;
			S(nS).tag=tag;
			S(nS).from=currentS;
			S(nS).fields=fields;
			b=true;
			if isempty(I.last)
				if ~isempty(shortTags)&&any(strcmpi(shortTags,tag))
					b=false;
				end
			else
				if I.last=='/'
					b=false;
				end
			end
			if b	% starting tag
				nHier=nHier+1;
				Shier(nHier)=nS;
				currentS=nS;
			end
		end	% readtag
		ilast=i+1;
	end
	i=i+1;
end
S=S(1:nS);
if ~bFlat
	S=Structure(S,bSimplify,bStruct);
end

	function s=getdata(x,ilast,i)
		while ilast<i&&x(ilast)<256&&blankChars(abs(x(ilast)))
			% test on <256 because of non-8-bit data
			ilast=ilast+1;
		end
		if ilast<i
			i=i-1;
			while x(i)<256&&blankChars(abs(x(i)))
				i=i-1;
			end
			s=x(ilast:i);
		else
			s='';
		end
	end		% getdata

	function [tag,fields,I,i]=readtag(x,i)
		if x(i)=='?'
			endChar='?';
			i=i+1;
		else
			endChar=0;
		end
		lastChar=0;
		tag='';
		fields=cell(0,2);
		I=[];
		while x(i)~='>'||(endChar~=0&&endChar~=lastChar)
			if tagChars(abs(x(i)))||bBrackCharsOpen(abs(x(i)))
				i1=i;
				while tagChars(abs(x(i)))||bBrackCharsOpen(abs(x(i)))
					if bBrackCharsOpen(abs(x(i)))
						[~,i]=ReadBracket(x,i);
					end
					i=i+1;
					if i>length(x)
						break	%!!!!
					end
				end
				i2=i-1;
				if i>length(x)
					break	%!!!!!
				end
				if isempty(tag)
					tag=x(i1:i2);
					if endChar=='?'
						bNoProcessing=false;
						switch lower(tag)
							case 'xml'
							case 'php'
								bNoProcessing=true;
							otherwise
								warning('Unknown "?tag" (%s)',tag)
						end
						if bNoProcessing
							while x(i)~='?'||x(i+1)~='>'
								if x(i)=='/'&&x(i+1)=='/'	% comment
									while x(i)~=10&&x(i)~=13
										i=i+1;
									end
									if x(i)==13&&x(i+1)==10
										i=i+2;
									else
										i=i+1;
									end
								elseif x(i)=='/'&&x(i+1)=='*'	% long comment
									i=i+2;
									while x(i)~='*'||x(i+1)~='/'
										i=i+1;
									end
									i=i+2;
								elseif x(i)=='''' || x(i)=='"'
									[~,i]=ReadString(x,i);
								else
									i=i+1;
								end
							end		% while in tag
							fields={tag,strtrim(x(i2+1:i-1))};
							i=i+1;
							lastChar=endChar;
							break
						end
					end
				elseif x(i)=='='
					i=i+1;
					while x(i)==' '||x(i)==9
						i=i+1;
					end
					fields{end+1,1}=x(i1:i2); %#ok<AGROW>
					[i1,i]=ReadField(x,i);
					fields{end,2}=x(i1:i-1);
					if x(i)~='>'
						i=i+1;
					end
				end
			else
				lastChar=x(i);
				i=i+1;
			end
			if i>length(x)
				%((this check is not done everywhere!!!))
				warning('READXML:FileEndInTag','file ended inside a tag?')
				return
			end
		end		% while not end of tag
		if i1==0
			warning('READXML:EmptyTag','??empty tag??)')
		end
		if i2==0
			i2=i-1;	%!!!not used?
		end
		I=struct('last',lastChar);
	end		% readtag

	function [s,i]=ReadBracket(x,i)
		iStart=i;
		bB=cBrackCharsOpen==x(i);
		if ~any(bB)
			error('Wrong use of this function!')
		end
		cB=cBrackCharsClose(bB);
		xLast=0;
		i=i+1;
		while x(i)~=cB
			if i>length(x)
				error('file stops within a bracket!')
			elseif bBrackCharsOpen(abs(x(i)))
				[~,i]=ReadBracket(x,i);
				xLast=0;
			elseif x(i)=='"'
				[~,i]=ReadField(x,i);
				i=i+1;
				xLast=0;
			elseif x(i)==''''&&(xLast==' '||xLast=='=')
				[~,i]=ReadField(x,i);
				i=i+1;
				xLast=0;
			else
				xLast=x(i);
				i=i+1;
			end
			if i>length(x)
				warning('Reading bracketted data out of range?!')
				i = i-1;
				break
			end
		end
		s=x(iStart:i);
	end		% ReadBracket
end		% readxml

function [s,i]=ReadCData(x,iS)
i=iS+9;
while x(i)~=']'||x(i+1)~=']'||x(i+2)~='>'
	i=i+1;
end
s=x(iS+9:i-1);
i=i+2;
end		% ReadCData

function S=RemoveFields(S,fRemove)
%RemoveFields - Remove fields specific to reading the data, not related to
%    the data in the XML-file itself
if nargin<2
	fRemove={'from','closed','ID'};
end
for i=1:length(fRemove)
	S=rmfield(S,fRemove{i});
end
end		% RemoveFields

function S=Simplify(S)
if ~isempty(S.children)
	S.children=RemoveFields(S.children);
	for i=1:length(S.children)
		S.children(i)=Simplify(S.children(i));
	end
end
end		% Simplify

function [s,i]=ReadString(x,i)
if x(i)==''''||x(i)=='"'
	sep=x(i);
	i=i+1;
else
	error('No start of string?!');
end
i1=i;
while x(i)~=sep
	if x(i)=='\'
		i=i+1;
	end
	i=i+1;
end
s=x(i1:i-1);
i=i+1;
end		% ReadString

function [i1,i]=ReadField(x,i)
if x(i)==''''||x(i)=='"'
	sep=x(i);
	i=i+1;
else
	sep=' ';
end
i1=i;
while x(i)~=sep&&(sep~=' '||x(i)~='>')
	if x(i)=='\'
		i=i+1;
	end
	i=i+1;
end
end		% ReadField

function S=Structure(S,bSimplify,bStruct)
nS=length(S);
ids=num2cell(1:nS);
[S.ID]=deal(ids{:});
S(1).children=[];
F=[0 cat(2,S(2:nS).from)];
B=F>0;	% list of unused data-blocks
while sum(B)>0
	ii=unique(F(B));
	bCheck=false;	% normally not needed
	Fii=F(ii);
	for i=1:length(ii)
		if ~any(Fii==ii(i))
			jj=find(F==ii(i));
			B(jj)=false;
			S(ii(i)).children=S(jj);
			bCheck=true;
		end		% if "lieves"
	end		% for
	if ~bCheck
		warning('READXML:flattening','!!something went wrong with flattening!!')
		break
	end
end		% while
S=S(1);
if bSimplify
	fRemove={'fields','closed','ID'};
	S=RemoveFields(S,fRemove);
	S=Simplify(S);
end
if bStruct
	S=MakeDirectStruct(S);
end
end		% Structure

function Sd=MakeDirectStruct(S)
%MakeDirectStruct - from  struct with children, go to struct with fields
%                   rather than children
%   Recursive call
Sd=struct();
bFields=isfield(S,'fields')&&~isempty(S.fields);
if bFields
	Sd.fields_=S.fields;	%?make struct?
end
bData=isfield(S,'data')&&~isempty(S.data);
if bData
	Sd.data_=S.data;
end
if isempty(S.children)
	if ~bFields&&bData
		Sd=S.data;
		if iscell(Sd)&&isscalar(Sd)
			Sd=Sd{1};
		end
	elseif bFields&&~bData
		Sd=S.fields;
	end
else
	for i=1:length(S.children)
		tag=S.children(i).tag;
		Si=MakeDirectStruct(S.children(i));
		if isfield(Sd,tag)
			Sdtag=Sd.(tag);
			if isstruct(Sdtag)
				try
					Sd.(tag)(1,end+1)=Si;
				catch
					if isscalar(Sdtag)
						Sd.(tag)={Sdtag};
					else
						Sd.(tag)=num2cell(Sdtag);
					end
					Sd.(tag){1,end+1}=Si;
				end
			elseif iscell(Sdtag)
				Sd.(tag){1,end+1}=Si;
			else
				Sd.(tag)={Sdtag,Si};
			end
		else
			Sd.(tag)=Si;
		end
	end		% for i (all children)
end		% with children
end		% MakeDirectStruct
