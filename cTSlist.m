classdef cTSlist < handle
	%cTSlist - class handling a list of timeseries (for easy navigating)
	%   to be used with cnavmsrs
	properties
		DATA
		DATAtype
		bForceVector = true
	end		% properties
	
	methods
		function c=cTSlist(X)
			if isstruct(X)
				if length(X)>1&&isfield(X,'t')&&isfield(X,'data')&&isfield(X,'signal')
					c.DATAtype=1;
				else
					error('Unknown data-type')
				end
				c.DATA=X;
			elseif isa(X,'timeseries')
				c.DATA=X;
				c.DATAtype=2;
			else
				error('Wrong input')
			end
		end		% cTSlist - constructor
		
		function IDX=IDX(c)
			%cTSlist/IDX - Create index-list (for cnavmsrs)
			IDX=reshape(sprintf('%05d',1:length(c.DATA)),5,[])';
		end		% IDX
		
		function n=length(c)
			n=length(c.DATA);
		end
		
		function [e,ne]=get(c,f)
			if ischar(f)
				fnr=sscanf(f,'%d');
			else
				fnr=f;
			end
			switch c.DATAtype
				case 1	% struct with data
					t = c.DATA(fnr).t;
					D = c.DATA(fnr).data;
					ne={'t',c.DATA(fnr).signal};
				case 2	% timeseries
					t = c.DATA(fnr).Time;
					D = c.DATA(fnr).Data;
					ne={'t',c.DATA(fnr).Name};
				otherwise
					error('Not implemented data-type!')
			end
			if c.bForceVector
				sz = size(D);
				if sum(sz>1)>1
					warning('Only first column taken from data!!!')
					iT = find(sz==length(t),1);
					I = repmat({1},1,length(sz));
					I{iT} = ':';
					D = D(I{:});
				end
			end
			e = [t,double(D(:))];	% (convert D to double because of otherwise conflict with t
		end		% cTSlist/get
	end		% methods
end		% cTSlist
