function [A,B]=readTextCells(fName,varargin)
%readTextCells - Read text - similar to e.g. textscan, but working for me...
%    [A,B]=readTextCells(fName[,options])
%        options:
%             - cColDelim : delimiter between columns
%                 character - default "automatic" (tab / ';' / ',' / '|' )
%                             just by maximum occurrence (in first part)
%             - cDecPoint: decimal point (',' / '.')
%                 default: automatic
%             - wordTranslateFcn: function reference to translate words
%                (cell-data) to number (for non-standard numbers, like data
%                formats)
%        A: cell array with cell data
%        B: numeric matrix with NaN if no value
%
% (!!!) mex-version exist - check if this is not called replacing this function!!!

cColDelim=[];	% automatic
cDecPoint=[];	% automatic
wordTranslateFcn=[];
bReplaceZeros=false;
bTrim = false;	% this was an idea - after seeing result of mex-version...

if nargin>1
	setoptions({'cColDelim','cDecPoint','wordTranslateFcn','bReplaceZeros','bTrim'},varargin{:})
	if ~isempty(wordTranslateFcn)
		if ~isa(wordTranslateFcn,'function_handle')
			error('Wrong value for "wordTranslateFcn"')
		end
	end
end

cFile=cBufTextFile(fName);

L=fgetlN(cFile,10000);

if isempty(cColDelim)||isempty(cDecPoint)
	C=[L{:}];
	if isempty(cColDelim)
		posDelim=[char(9) ';,'];
		nD=zeros(size(posDelim));
		for i=1:length(posDelim)
			nD(i)=sum(C==posDelim(i));
		end
		[~,iMax]=max(nD);
		cColDelim=posDelim(iMax);
	end
	if isempty(cDecPoint)
		if cColDelim==','
			cDecPoint='.';
		else
			bDig=C>='0'|C<='9';	%!!!!!!!!!!!!!!!!!! is dit OK???????????????
			bDig(1)=[];
			nP=sum(C(bDig)=='.');
			nC=sum(C(bDig)==',');
			if nC>nP
				cDecPoint=',';
			else
				cDecPoint='.';
			end
		end
	end
end
nLines=length(L);
if ~feof(cFile)	% didn't this work
	nLines=ceil(cFile.lFile/cFile.iFile*length(L))+length(L);
end
mxN=0;
for i=1:length(L)
	l=deblank(L{i});
	L{i}=l;
	mxN=max(mxN,sum(l==cColDelim));
end
mxN=mxN+1;
A=cell(nLines,mxN);
if nargout>1
	B=nan(nLines,mxN);
end


iL=1;
lNr=0;
bDigit=false(1,255);
bDigit(abs('0123456789'))=true;
bNumberStart=bDigit;
bNumberStart(abs(cDecPoint))=true;
bNumberStart(abs('+-'))=true;
bNumber=bNumberStart;
bNumber(abs('Ee'))=true;
bBlank=false(1,255);
bBlank([9,32])=true;

mxN = 0;
while iL<=length(L)
	lNr=lNr+1;
	l=deblank(L{iL});
	if bReplaceZeros&&any(l==0)
		l(l==0)=' ';
	end
	if isempty(l)
	elseif any(l<1)
		warning('READTEXTCELLS:zeroChar','Lines with "zero-characters" are omitted')
	else
		% find delimiters (outside strings)
		Bd = false(size(l));
		bInString = false;
		cString = '''';
		bStart=true;
		for i=1:length(l)
			if bInString
				if l(i)==cString
					bInString=false;
				end
			elseif bStart&&(l(i)==''''||l(i)=='"')
				bInString=true;
				cString=l(i);
				bStart=false;
			elseif ~bBlank(abs(l(i)))
				bStart=l(i)==cColDelim;
				Bd(i)=bStart;
			end
		end
		iD=[0 find(Bd) length(l)+1];
		mxN = max(mxN,length(iD)-1);
		for i=1:length(iD)-1
			w=strtrim(l(iD(i)+1:iD(i+1)-1));
			if length(w)>1
				wse=w([1 end]);
				if all(wse=='''')||all(wse=='"')
					w=w(2:end-1);
				end
			end
			A{lNr,i}=w;
			if ~isempty(w)&&nargout>1
				if bNumberStart(abs(w(1)))&&all(bNumber(abs(w)))
					if cDecPoint~='.'
						w(w==cDecPoint)='.';
					end
					%B(lNr,i)=str2double(w);
					B(lNr,i)=sscanf(w,'%g');
				elseif ~isempty(wordTranslateFcn)
					try
						B(lNr,i)=wordTranslateFcn(w);
					end
				end
			end
		end
	end
	
	iL=iL+1;
	if iL>length(L)
		if ~feof(cFile)
			L=fgetlN(cFile,10000);
			iL=1;
		end
	end
end
if mxN<size(A,2)
	A=A(:,1:mxN);
	B=B(:,1:mxN);
end
if size(A,1)>lNr
	A=A(1:lNr,:);
	if nargout>1
		B=B(1:lNr,:);
	end
end
