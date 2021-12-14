function out=writexml(X,fName,varargin)
%writexml  - Write XML file of an "XML-compatible struct"
%     writexml(X,fName)
%     Sxml=writexml(X)
%        X: struct similar to output of readxml

bString=nargout||nargin<2;
bFile=nargin>1&&~isempty(fName);
bStructured=true;
nSpaceIndent=0;	% if 0 ==> tab, else n spaces
bMultiLine=true;
if ~isempty(varargin)
	setoptions({'bStructured','bMultiLine','nSpaceIndent'},varargin{:})
end

if bFile
	fid = 0;	% declare
	C = [];
	nC = 0;
else
	C = cell(1,10000);
	nC = 0;
end
if isfield(X,'tag')&&isfield(X,'data')&&isfield(X,'from')&&isfield(X,'closed')&&~isfield(X,'children')
	X=readxml(X,false);	% make it hierarchical
end
if isfield(X,'children')&&isfield(X,'tag')&&isfield(X,'data')
	if bString
		Sxml=HierXML(X,false);
	else
		HierXML(X,bFile);
		bFile=false;	% if true - then it's already saved
	end
else
	error('Wrong input?')
end
if bFile
	fid = OpenFile(fName,'w');
	fwrite(fid,Sxml,'char');
	fclose(fid);
end

if nargout
	out=Sxml;
end

	function out=HierXML(X,bFile)
		if bFile
			OpenFile(fName);
		end
		WriteHierXMLelement(X.children,0);
		if bFile
			fclose(fid);
		elseif bMultiLine
			out=sprintf('%s\n',C{1:nC});
		else
			out=sprintf('%s ',C{1:nC});
		end
	end		% HierXML

	function WriteHierXMLelement(X,level)
		Lstart=GetLineStart(level);
		LstartInd=GetLineStart(level+1);
		for i=1:length(X)
			n=size(X(i).fields,1);
			C1=cell(1,n+2);
			bClosingTag=true;
			switch X(i).type
				case 2	% normal
					C1{1}=sprintf('<%s',X(i).tag);
				case 1	% (!!!!only OK for "<?xml"!)
					bClosingTag=false;
					C1{1}=sprintf('<?%s',X(i).tag);
				otherwise
					C1{1}=sprintf('<%s',X(i).tag);
					warning('Not implemented')
			end
			for j=1:n
				C1{j+1}=sprintf(' %s="%s"',X(i).fields{j},X(i).fields{j,2});
			end
			switch X(i).type
				case 1
					C1{n+2}=' ?>';
				otherwise
					C1{n+2}='>';
			end
			Print([Lstart,C1{:}]);
			for j=1:length(X(i).data)
				Print([LstartInd,X(i).data{j}]);
			end
			for j=1:length(X(i).children)
				WriteHierXMLelement(X(i).children(j),level+1);
			end
			if bClosingTag
				Print([Lstart,sprintf('</%s>',X(i).tag)]);
			end
		end
	end		% WriteHierXMLelement

	function OpenFile(fName)
		fid = fopen(fName,'wt');
		if fid<3
			error('Problem opening the file?!')
		end
	end		% OpenFile

	function Print(s)
		if iscell(C)
			nC=nC+1;
			C{nC}=s;
		else
			fprintf(C,'%s',s);
			if bMultiLine
				fprintf(C,'\n');
			end
		end
	end		% Print

	function Lstart=GetLineStart(level)
		if level==0||~bStructured
			Lstart='';
		elseif nSpaceIndent==0
			c=char(9);
			Lstart=c(1,ones(1,level));
		else
			c=' ';
			Lstart=c(1,ones(1,level*nSpaceIndent));
		end
	end		% GetLineStart

end		% writexml
