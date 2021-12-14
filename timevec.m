function t=timevec(dt,N,t0)
% timevec  - Creates time vector (made for plotting)
%
%      t=timevec(dt,N);
%      t=timevec(dt,e); (looks to number of rows)
%      t=timevec(gegs[,N]); (with gegs from e.g. leesTDMS)
%             N>0 ---> number of points
%             N<0 ---> number of parts
%      t=timevec(dt,N,t0)	% offset
%      t=timevec(gegs,N,true) % uses offset in gegs

t=[];
D=[];
if isnumeric(dt)
	if isscalar(N)
		% default use
	elseif isnumeric(N)||islogical(N)
		N=size(N);
		N=N(N>1);
		if isempty(N)
			error('Can''t find the requested number of time-points')
		end
		N=N(1);
	else
		error('unknown use - (second argument?)')
	end
elseif isstruct(dt)
	D=dt;
	nN=[];
	if nargin==1
		N=[];
	elseif ~isscalar(N)
		N=size(N);
		N=N(N>1);
		if isempty(N)
			error('Can''t find the requested number of time-points')
		end
		N=N(1);
	elseif N<0
		nN=-N;
		N=[];
	end
	if isfield(D,'dt')
		dt=D.dt;
	elseif isfield(D,'SamplingRate')
		dt=1/D.SamplingRate;
	else
		error('Unknown use (no sampling time found')
	end
	if isempty(N)
		if isfield(D,'chanInfo')
			N=D.chanInfo(1).props2.wf_samples;
			if isempty(nN)
				nN=length(D.tBlocks)/length(D.chanInfo);
			end
			N=N*nN;
		else
			error('Wrong input for "N"')
		end
	end
end
if isempty(t)
	t=(0:N-1)'*dt;
end
if nargin>2&&~isempty(t0)
	if islogical(t0)
		if ~t0
			t0=0;
		elseif ~isstruct(D)
			error('This usage of %s requires a structure as first argument!'	...
				,mfilename)
		elseif isfield(D,'t0')
			t0=D.t0;
		else
			t0=0;	% give a warning?
		end
		if isa(t0,'lvtime')
			t=t/86400;	% seconds --> days
		end
	end
	t=double(t0)+t;
end
