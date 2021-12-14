function [D,Dinfo]=ReadTXTwithDate(fname,varargin)
%ReadTXTwithDate - Read text file with date column(1)
%    D=ReadTXTwithDate(fname,varargin)

bAutoConf=false;
bTranslateComma=false;
cDelim=char(9);
nSkip=0;
iDateFields=1;
iTextFields=[];
%sDateFormat='dd/mm/yyyy HH:MM:SS';
sDateFormat='dd.mm.yyyy HH:MM:SS';
nBlock=1000;

if nargin>1
	setoptions({'bAutoConf','bTranslateComma','cDelim','nSkip'	...
			,'iTextFields','sDateFormat'}	...
		,varargin{:})
end
if ~exist(fname,'file')
	fname=zetev([],fname);
	if ~exist(fname,'file')
		error('Can''t open the file')
	end
end
oFile=cBufTextFile(fname);
L=fgetlN(oFile,nBlock);
if isempty(L)
	error('Can''t read from file!')
end
Head={};
Fields=[];
if nSkip
	Head=L(1:nSkip); %#ok<UNRCH>
	L(1:nSkip)=[];
end

l=L{min(end,10)};	% !!! 10th line (after "nSkip") as a reference!
iL=0;
if bAutoConf
	if any(l==9) %#ok<UNRCH>
		cDelim=char(9);
		if any(l==',')
			bTranslateComma=true;
		end
	elseif any(l==';')
		cDelim=';';
		if any(l==',')
			bTranslateComma=true;
		end
	else
		cDelim=',';	% !!!!
	end
	iDelim=[0 strfind(l,cDelim) length(l)+1];	% strfind appears to be faster than find(l==cDelim)!
	Bdate=false(1,length(iDelim)-1);
	Btext=Bdate;
	for iCol=1:length(Bdate)
		s=GetField(l,iDelim,iCol);
		if isempty(s)
		else
			try
				d=datenum(s,sDateFormat);
				Bdate(iCol)=true;
			catch
				d=str2double(s);
				if isnan(d)
					Btext(iCol)=true;
				end
			end
		end
	end
	nCols=sum(l==cDelim)+1;
	iDateFields=find(Bdate);
	iTextFields=find(Btext);
	Bhead=false(1,9);
	Dref=GetLineData(L{10},cDelim,nCols,Bdate,Btext,sDateFormat,bTranslateComma);
	nNaN=sum(isnan(Dref));
	for iL=1:length(Bhead)
		D1=GetLineData(L{iL},cDelim,nCols,Bdate,Btext,sDateFormat,bTranslateComma);
		if ~isempty(D1)
			if sum(isnan(D1))==nNaN
				if iL>1
					l=L{iL-1};
					if sum(l==cDelim)+1==nCols
						iDelim=[0 strfind(l,cDelim) length(l)+1];	% strfind appears to be faster than find(l==cDelim)!
						Fields=cell(1,nCols);
						for iCol=1:nCols
							Fields{iCol}=GetField(l,iDelim,iCol);
						end
					end
				end
				break
			end
		end
	end
	iL=iL-1;
	if iL>0
		Head=L(1:iL);
	end
	% other configurations use default values...
	%   !!!!sDateFormat
end

nCols=sum(l==cDelim)+1;
Bdate=false(1,nCols);
Btext=Bdate;
Bdate(iDateFields)=true;
Btext(iTextFields)=true;

DC=cell(1,10000);
nDC=0;
D=zeros(length(L),nCols);
bStat=~oFile.eof;
if bStat
	status('Reading textfile',0)
end
BOK=false(1,nBlock);	% ???
while true
	iL=iL+1;
	if iL>length(L)
		if bStat
			status(oFile.iFile/oFile.lFile)
		end
		nDC=nDC+1;
		DC{nDC}=D(BOK,:);
		L=fgetlN(oFile,nBlock);
		if isempty(L)
			break
		end
		iL=1;
		BOK(:)=false;
	end
	l=L{iL};
	D1=GetLineData(l,cDelim,nCols,Bdate,Btext,sDateFormat,bTranslateComma);
	if isempty(D1)
		% do something if not the end of the file?
		% (now empty lines are not visible in result)
	else
		D(iL,:)=D1;
		BOK(iL)=true;
	end
end
if bStat
	status
end
D=cat(1,DC{1:nDC});
if nargout>1
	Dinfo=struct('Head',{Head},'Fields',{Fields});
end

function s=GetField(l,iDelim,iCol)
s=l(iDelim(iCol)+1:iDelim(iCol+1)-1);
if isempty(s)
	% nothing? NaN?
elseif length(s)>1&&s(1)=='"'&&s(end)=='"'
	s=s(2:end-1);
end

function D=GetLineData(l,cDelim,nCols,Bdate,Btext,sDateFormat,bTranslateComma)
iDelim=[0 strfind(l,cDelim) length(l)+1];	% strfind appears to be faster than find(l==cDelim)!
if length(iDelim)-1<nCols
	if isempty(l)
		D=[];
		return
	end
	l(end+1:nCols+1)=cDelim;
	iDelim=[0 strfind(l,cDelim) length(l)+1];
elseif length(iDelim)-1>nCols
	% give warning?
	iDelim=iDelim(1:nCols+1);
end
D=zeros(1,nCols);
if bTranslateComma
	l(l==',')='.';
end
for iCol=1:min(length(iDelim)-1,nCols)
	s=GetField(l,iDelim,iCol);
	if isempty(s)
		D(iCol)=NaN;
	elseif Bdate(iCol)
		try %#ok<TRYNC>
			D(iCol)=datenum(s,sDateFormat);
		end
	elseif Btext(iCol)
		% ?
		%   "library" with index
	else
		D(iCol)=str2double(s);
	end
end
if iCol<nCols
	D(iCol+1:nCols)=NaN;
end
