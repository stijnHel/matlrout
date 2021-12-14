%cBufTextFile - class for faster line-by-line file-read
%    c=cBufTextFile(name[,options]);
%       creates the object
%    l=fgetl(F);
%        reads a line - does not go faster(!)
%    L=fgetlN(F,n);
%        reads n lines - does go faster!
%    clear c for deleting the object (and closing the file)
classdef cBufTextFile < handle
	properties
		fName	% filename
		leaveOpen;	% leave the file open (or not)
		X=[];	% current block contents
		fid=0;	% file ID of the file (if open)
		lFile	% length of the file
		lBlock	% length of a block
		iFile	% position in file to read next block
		iLine	% index of next line to be read
		nLines	% number of lines in current block
		iLF		% places in current block of LF's
		iCR		% placec in current block of CR's
		fPos	% file position of start of current block
		fPosNext	% file position of start of next block
		eof		% is file at eof? (can be seen as "last block")
		iFformat=0;	% textfile format (1: unix (LF), 2: old mac (CR), 3: DOX/Windows (CR/LF)
		iFFwarning=false;	% no warnings about CR/LF mismatch
	end
	
	methods
		function n=length(A)
			n=A.lFile;
		end
		function n=size(A)
			n=A.lFile;
		end
		
		function F=cBufTextFile(name,varargin)
			lLeaveOpen=true;
			llBlock=65536;
			if ~isempty(varargin)
				setoptions({'lLeaveOpen','llBlock'},varargin{:})
			end
			F.fid=fopen(fFullPath(name),'r');
			F.fName=fopen(F.fid);	% not the original name, since it can be changed (e.g. ~/)
			F.leaveOpen=lLeaveOpen;
			F.lBlock=llBlock;
			fseek(F.fid,0,'eof');
			F.lFile=ftell(F.fid);
			fseek(F.fid,0,'bof');
			F.X='';
			F.iFile=0;
			F.iLine=0;
			F.nLines=0;
			F.eof=F.lFile==0;
			if ~lLeaveOpen
				fclose(F.fid);
				F.fid=0;
			end
			F.fPosNext=0;
			F.fPos=0;
			ReadBlock(F);
		end
		
		function Reset(F)
			fseek(F.fid,0,'bof');
			F.X='';
			F.iFile=0;
			F.iLine=0;
			F.nLines=0;
			F.eof=F.lFile==0;
			F.fPosNext=0;
			F.fPos=0;
			ReadBlock(F);
		end		% Reset
		
		function ReadBlock(F)
			F.fPos=F.fPosNext;
			if F.eof
				F.X=[];
				return
			end
			if F.iLine>0
				if F.iLine<=length(F.iLF)
					F.X=F.X(F.iLF(F.iLine)+1:end);
					F.fPos=F.fPos-length(F.X);
				else
					F.X='';
				end
			end
			if ~F.leaveOpen||F.fid<3
				F.fid=fopen(F.fName);
				if F.fid<3
					error('Can''t open the file anymore!')
				end
				fseek(F.fid,F.fPos,'bof');
			end
			s=fread(F.fid,[1 F.lBlock],'*char');
			F.fPosNext=ftell(F.fid);
			F.iFile=F.iFile+length(s);
			F.eof=feof(F.fid);
			if ~F.leaveOpen
				fclose(F.fid);
				F.fid=0;
			end
			F.X=[F.X s];
			nF=length(F.X);
			%!!!gebruik F.iFformat
			F.iCR=find(F.X==13);	% ?beter eenmalig bepalen wat het type is?
			F.iLF=find(F.X==10);
			if isempty(F.iCR)
				if isempty(F.iLF)
					%? no real text-file? or blocks too small?
				else	% unix-type
					F.iCR=F.iLF;
					if F.eof
						F.iCR(end+1)=nF+1;
					end
					F.iFformat=1;
				end
			elseif isempty(F.iLF)	% (old) mac-type
				if F.eof
					F.iCR(end+1)=nF+1;
				end
				F.iLF=F.iCR;
				F.iFformat=2;
			else	% DOS/Windows type
				F.iFformat=3;
				if F.iLF(1)==1
					F.iLF(1)=[];
				end
				if F.eof
					F.iCR(end+1)=nF+1;
				end
				if abs(length(F.iLF)-length(F.iCR))>1||	...
						~all(F.X(F.iCR(F.iCR<nF)+1)==10)||	...
						~all(F.X(F.iLF(F.iLF>0)-1)==13)
					% not clear Mac/Unix/DOS type!
					F.iFformat=-1;
					if F.iFFwarning
						warning('CBUFTEXT:MixedOrBadFormat','Mixed (DOS/UNIX/MAC) or bad format! - correction not complete/ready!')
						F.iFFwarning=false;
					end
					ii=find(F.X==13|F.X==10);
					if ii(1)==1
						ii(1)=[];	%!!!!!!
					end
					if ii(end)==nF
						ii(end)=[];	%!!!!!
					end
					F.iLF=ii(F.X(ii)==10|(F.X(ii)==13&F.X(ii+1)~=10));
					F.iCR=ii(F.X(ii)==13|(F.X(ii)==10&F.X(ii-1)~=13));
					%%%%%%!!!!!!first and last line correction!!!!!
				end
				% further checks should/could be done (all CR/LF sets?)!
			end
			F.iLF=[0 F.iLF];
			F.iLine=1;
			F.nLines=length(F.iCR);
		end
		
		function l=fgetl(F)
			if F.iLine>F.nLines
				ReadBlock(F);
				if F.iLine>F.nLines
					l=0;
					return
				end
			end
			l=F.X(F.iLF(F.iLine)+1:F.iCR(F.iLine)-1);
			F.iLine=F.iLine+1;
		end
		
		function L=fgetlN(F,n,varargin)
			if F.nLines==0||(F.iLine>F.nLines&&F.eof)
				L={};
				return
			end
			[bRemoveLastEmpty,bOnlyNonEmpty,bDeblank,bTrim]	...
				= deal(true,false,false,false);
			if nargin>2
				setoptions({'bRemoveLastEmpty','bOnlyNonEmpty','bDeblank','bTrim'},varargin{:})
			end
			L=cell(1,min(n,ceil((F.lFile-F.fPos)/2)));
			i=0;
			lX=F.X;
			liLF=F.iLF;
			liCR=F.iCR;
			while i<n
				if F.iLine<=F.nLines
					for j=F.iLine:min(F.nLines,F.iLine+n-i-1)
						l=lX(liLF(j)+1:liCR(j)-1);
						if bDeblank
							l=deblank(l);
						elseif bTrim
							l=strtrim(l);
						end
						if ~bOnlyNonEmpty||~isempty(l)
							i=i+1;
							L{i}=l;
						end
					end
					F.iLine=j+1;
				end
				if i<n
					if F.eof
						L=L(1:i);
						F.X=[];
						F.nLines=0;
						F.iLine=1;
						F.fPos=F.fPosNext;
						F.iLF=[];
						F.iCR=[];
						break
					end
					ReadBlock(F);
					lX=F.X;
					liLF=F.iLF;
					liCR=F.iCR;
				end
			end		% while i<n
			if bRemoveLastEmpty&&F.eof&&F.iLine>F.nLines&&i>0&&isempty(l)
				L(end)=[];
			end
		end		% function fgetlN
		
		function pos=ftell(F)
			if F.iLine<=length(F.iLF)
				pos=F.fPos+F.iLF(F.iLine);
			else
				pos=F.fPos+length(F.X);
			end
		end
		
		function delete(F)
			if F.fid>0&&strcmp(fopen(F.fid),F.fName)
				fclose(F.fid);
			end
		end
		
		function fclose(F)
			fclose(F.fid);
			F.fid=0;
		end
		
	end
end
