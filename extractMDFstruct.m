function [D,P,F,MDFversion,xID]=extractMDFstruct(f,bPrint,varargin)
% extractMDFstruct - Extracts the structure of an MDF file
%    for finding the structure of version 4-files
%        [D,P,F]=extractMDFstruct(f,bPrint,...)
%                 f: filename
%                 bPrint: print hierarchical structrure
%                 ...: cellarray or separate types to be extracted inF

F_TP={};
if nargin>2
	if iscell(varargin{1})
		if length(varargin)>1
			error('Too many inputs! (if cell as input 3 only 3 arguments are expected)')
		end
		F_TP=varargin{1};
	else
		F_TP=varargin;
	end
end

fevent=fopen(fFullPath(f),'r');
if fevent<0
	error('file niet gevonden');
end
xID=fread(fevent,[1 64],'*char');
if ~strcmp(xID(1:8),'MDF     ')
	fclose(fevent);
	error('Onverwacht begin');
end
sMDFversion=xID(9:16);
MDFversion=sscanf(sMDFversion,'%d.%d.%d',[1 3]);

Pread=zeros(2,5000);
nPread=1;	% include '0'
[D,err,F]=RecursiveRead(fevent,0);
fclose(fevent);
if ~isempty(err)
	warning('Stopped by an error!')
	DispErr(err)
end
if nargout>1
	P=Pread(:,1:nPread);
end

if nargin>1&&bPrint
	PrintMDFstruct(D,0,0)
end

	function [D,err,F]=RecursiveRead(fevent,pos)
		
		err=[];
		F={};
		try
			[TP,x,I]=leesblok(fevent,pos);
		catch err
			D=struct('error',err,'filepos',pos);
			return
		end
		if ~isempty(F_TP)&&any(strcmpi(TP,F_TP))
			F{1,end+1}=x;
		end
		D=struct('TP',TP,'pos',pos,'len',length(x),'x',x,'nTotal',length(I)	...
			,'nOK',0,'I',I,'D',{cell(1,length(I))});
		for i=1:length(I)
			if I(i)
				[D.D{i},err,F1]=RecursiveRead(fevent,I(i));
				if ~isempty(F1)
					F=[F,F1];
				end
				if ~isempty(err)
					D.iError=i;
					return
				end
				D.nOK=D.nOK+1;
			end
		end
	end		% RecursiveRead

	function [tp,b,LINK]=leesblok(f,ind)
		iConvert8=cumprod([1 256 256 256 256 256 256 256]);
		if exist('ind','var')&&ind
			if any(Pread(1,1:nPread)==ind)
				b=Pread(1,1:nPread)==ind;
				Pread(2,b)=Pread(2,b)+1;
				tp='loop!';
				b=[];
				LINK=[];
				return
			end
			nPread=nPread+1;
			Pread(1,nPread)=ind;
			fseek(f,ind,-1);
		end
		tp=fread(f,[1,2],'*char');
		if ~all(tp==35)
			error('No normal block found!')
		end
		tp=deblank(fread(f,[1,6],'*char'));
		l=iConvert8*fread(f,8);
		n=iConvert8*fread(f,8);
		if n>0
			x=fread(f,[8 n]);
			if isequal(size(x),[8 n])
				LINK=iConvert8*x;
				if any(rem(LINK,8))
					warning('Links should be multiples of 8!')
				end
				b=fread(f,[1 l-16-8-8*n],'*uint8');
			else
				warning('Something goes wrong reading data!')
				LINK=x;
				b=[];
			end
		else
			b=fread(f,[1 l-16-8],'*uint8');
			LINK=[];
		end
	end		% leesblok

	function PrintMDFstruct(D,level,nr)
		if level>0
			c=' ';
			fprintf('%s',c(1,ones(1,level*2)))
		end
		if nr>0
			fprintf('%3d: ',nr)
		end
		fprintf('%-3s %5d (%3d) - %8d',D.TP,D.len,D.nTotal,D.pos)
		nP=Pread(2,Pread(1,1:nPread)==D.pos);
		if nP
			fprintf(' (!)x%d',nP)
		end
		fprintf('\n')
		for i=1:D.nTotal
			if ~isempty(D.D{i})
				PrintMDFstruct(D.D{i},level+1,i)
			end
		end
	end		% PrintMDFstruct
end		% extractMDFstruct
