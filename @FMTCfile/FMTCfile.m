%FMTCfile - class definition file for a FMTC-measurement file
% This class is made to show the possibility of using large measurement
%    files with easy access without having the need for full load in
%    memory.
%    file is left open as long as the object exists.
%
% When creating the object, no data is read.
%     a = FMTCfile(filename);	% filename should point to a FMTC-xml-file
% To retrieve data:\
%     B=a(i1:i2);	% for all channels
%     B=a(i1:i2,[chan1 chan2 ...]);	% for some channels
%
% other functions
%     length(a) - gives number of data points
%     size(a) - gives number of data points and number of channels
%     plot(a,ix,iy,iData) - plot channels (iy) as a function of channel ix
%           with ix=0, time is used as X-data, iData are the indices of the
%           points
%           extra arguments to plot are forwarded to the matlab-plot function
% the following data can be retrieved from the object:
%               fName             - filename
%               dataFile          - file
%               NumberOfSamples   - number of samples
%               length            - number of samples (same as previous)
%               nChans            - number of channels (!)without t
%               channels          - names of channels (!)including t
%               fSampling         - sampling frequency (1/s)
%               dt                - sampling time (s)
%               info              - file info

% known issues:
%   file are held open (by default) - some checking (and re-opening) is
%      done, but problems can occur, especially if file is overridden

classdef FMTCfile < handle
	properties	% all fields are automatically private, since subsref is overridden
		fName
		dataFile
		nChans
		channels
		fSampling
		NumberOfSamples
		BlockSize
		info
	end
	properties (GetAccess = private)
		iX
		write=false;
		leaveOpen;
		X=[];
		fid=0;
	end
	
	methods
		function B=subsref(A,S)
			if length(S)==1&&strcmp(S.type,'.')
				switch S.subs
					case {'fName','dataFile','NumberOfSamples'	...
							,'nChans','channels','BlockSize'	...
							,'fSampling','info'}
						B=A.(S.subs);
					case 'length'
						B=A.NumberOfSamples;
					case 'dt'
						B=1/A.fSampling;
					otherwise
						error('Unavailable field of this class')
				end
				return
			elseif length(S)~=1||~strcmp(S.type,'()')||length(S.subs)<1||length(S.subs)>2
				error('Only simple indexing can be done')
			end
			iPoints=reshape(S.subs{1},1,[]);
			if length(S.subs)==1
				jChan=1:A.nChans;
			else
				jChan=S.subs{2}(:)';
			end
			if length(iPoints)>1&&any(diff(iPoints)~=1)
				if length(iPoints)==2
					if iPoints(2)<iPoints(1)
						B=zeros(0,length(jChan));
						return
					elseif isinf(iPoints(2))
						iPoints=iPoints(1):A.NumberOfSamples;
					elseif iPoints(end)>A.NumberOfSamples
						warning('FMTCfile:highEndPointIndex','More samples requested than available')
						iPoints=iPoints(1):A.NumberOfSamples;
					else
						iPoints=iPoints(1):iPoints(end);
					end
				else
					error('Simple consecutive indexing is needed in this version!')
				end
			end
			if any(iPoints<=0|iPoints>A.NumberOfSamples)||any(jChan>A.nChans)
				error('Index out of range')
			end
			B=zeros(length(iPoints),length(jChan));
			iP=1;
			iB=0;
			while iB<length(iPoints)
				i=iPoints(iP);
				iChan=0;
				for j=jChan
					iChan=iChan+1;
					if j<=0
						if iP==1
							B(:,iChan)=(iPoints'-1)/A.fSampling;
						end
					else
						i1=A.iX(1,j);
						i2=A.iX(2,j);
						if i<i1||i>i2
							iBlock=floor((i-1)/A.BlockSize);
							i1=iBlock*A.BlockSize+1;
							if ~A.leaveOpen||~strcmp(fopen(A.fid),A.dataFile)
								A.fid=fopen(A.dataFile,'r','ieee-be');
							end
							fseek(A.fid,8*((i1-1)*A.nChans+(j-1)*A.BlockSize),'bof');
							A.X(:,j)=fread(A.fid,A.BlockSize,'double');
							if ~A.leaveOpen
								fclose(A.fid);
								A.fid=0;
							end
							A.iX(1,j)=i1;
							i2=i1+A.BlockSize-1;
							A.iX(2,j)=i2;
						end		% if reading is necessary
						n=1+min(i2-i,iPoints(end)-i);	% (only needed once per block!)
						B(iB+1:iB+n,iChan)=A.X(i-i1+1:i-i1+n,j);
					end
				end		% for j
				iB=iB+n;
				iP=iP+n;
			end
		end
		function n=length(A)
			%FMTCfile/length - Gives the number of samples of a FMTCfile
			%   n=length(A)
			n=A.NumberOfSamples;
		end
		function s=size(A)
			%FMTCfile/size - Gives the size of a FMTCfile [#samples,#channels]
			%    s=size(A)
			s=[A.NumberOfSamples A.nChans];
		end
		function disp(A)
			%FMTCfile/disp - Displays a FMTCfile
			%    disp(F)
			fprintf('FMTCfile - FMTC-measurement file\n   fSampling = %g\n',A.fSampling)
			fprintf('   total number of samples = %g\n',A.NumberOfSamples)
			fprintf('   number of channels = %d\n',A.nChans)
			for i=1:A.nChans
				fprintf('        %2d: %s\n',i,A.channels{i+1});
			end
		end
		function A=subsasgn(A,S,B)
			if ~A.write
				error('Can''t write to this class!')
			else
				error('Assigning FMTCfiles is not implemented!')
			end
		end
		
		function plot(A,ix,iy,iData,varargin)
		%FMTCfile/plot - plots part of data
		%  plot(F,ix,iy,iData[,plotoptions])
		%     ix : index of channel (if 0, unsaved time data is used as X)
		%     iy : indices of channels to plot
		%     iData : indices of points to plot
			if nargin<3
				error('At least 4 inputs must be given: plot(<file>,ix,iy,iData)')
			end
			if length(ix)~=1
				error('Only one x-index can be used!')
			end
			if ix==0
				if length(iData)==2
					iData=iData(1):iData(2);
				end
				X=A.subsref(substruct('()',{iData,iy}));
				plot((iData-1)/A.fSampling,X,varargin{:})
			else
				X=A.subsref(substruct('()',{iData, [ix;iy(:)]}));
				plot(X(:,1),X(:,2:end))
			end
		end
		function F=FMTCfile(name,varargin)
			leaveOpen=true;
			if ~isempty(varargin)
				setoptions({'leaveOpen'},varargin{:})
			end
			try
				[e,ne,de,e2,gegs]=leesFMTClvXMLmeas(name,0,0);
			catch
				error('Error occurred when reading the info-file (%s)',lasterr)
			end
			F.channels=ne;
			F.fSampling=gegs.SamplingRate;
			F.NumberOfSamples=gegs.NumberOfSamples;
			F.BlockSize=gegs.BlockSize;
			F.info=gegs.info;
			F.fName=name;
			F.leaveOpen=leaveOpen;
			F.nChans=gegs.NumberOfSignals;
			F.X=zeros(gegs.BlockSize,length(ne)-1);
			F.iX=zeros(2,gegs.NumberOfSignals);
			F.dataFile=gegs.fullDataFile;
			if leaveOpen
				F.fid=fopen(gegs.fullDataFile,'r','ieee-be');
			else
				F.fid=0;
			end
		end
		function delete(F)
			if F.fid>0&&strcmp(fopen(F.fid),F.dataFile)
				fclose(F.fid);
			end
		end
	end
end
