%cStatus  - status class - to make sure that status level is reduced
%   uses the "standard" status function

%      no further tests related to hierarchy are done (until now)!
%             this is being started!!
classdef cStatus < handle
	properties
		bIsOpen = false;
		hFig
		prc
		bStopRequest = false;
	end		% properties
	
	methods
		function c=cStatus(varargin)
			if nargin==0
				error('Creating a status-window without arguments is not allowed!')
			end
			c.hFig=status(varargin{:});
			c.bIsOpen=true;
			c.prc=status([],'status');
		end
		
		function close(c)
			prcNew=status([],'status');
			if c.bIsOpen
				if isequal(prcNew,c.prc)
					status
				else
					nNew=size(prcNew,1);
					nOld=size(c.prc,1);
					if nNew<nOld
						warning('STATUS:statLevelLow','status level already reduced!')
					elseif nNew==nOld
						warning('STATUS:statDataWrong','Something went wrong with status!')
						status
					elseif isequal(prcNew(end-nOld+1:end,:),c.prc)
						warning('STATUS:statLevelHigh','Not all status levels were removed!')
						for i=nOld:nNew
							status
						end
					else
						warning('STATUS:statLevelDataWrong','Something went wrong with status!')
					end
				end
				c.bIsOpen=false;
			else
				error('Re-close status?!')
			end
		end
		
		function SetCloseFcn(c,stopQuestion,stopAnalysis)
			if nargin<3
				if nargin<2
					stopQuestion=[];
				end
				stopAnalysis=@(f) c.SetStop(f);
			end
			status([],'condclose',stopQuestion,stopAnalysis)
		end		% SetCloseFcn
		
		function SetStop(c,f)
			c.bStopRequest=true;
		end
		
		function bStop=status(c,f)
			status(f)
			if nargout>0
				bStop=c.bStopRequest;
				c.bStopRequest=false;
			end
		end
		
		function SetText(c,txt)
			status([],txt)
		end		% SetText
		
		function delete(c)
			if c.bIsOpen
				c.close();
			end
		end
	end		% methods
end		% classdef
