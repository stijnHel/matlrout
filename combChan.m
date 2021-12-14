function [A,t]=combChan(e,ne,dt)
%combChan - Combines channels to a linear block
%   A=combChan(e,ne); (e,ne from lees<xxx> routines)
%   A=combChan(e,nChan);
%
%   [A,t]=combChan(e,nChan,dt);
%   [A,t]=combChan(e,nChan,gegs); (gegs see lees<xxx> routines)
%   [A,t]=combChan(e,gegs); (gegs see lees<xxx> routines)

if nargin<3
	dt=[];
end
if isstruct(ne)
	nChan=length(ne.chanInfo);
	dt=ne;
elseif ischar(ne)
	nChan=size(ne,1);
elseif iscell(ne)
	nChan=length(ne);
else
	nChan=ne;
end

if rem(size(e,2),nChan)
	error('Impossible to combine (wrong number of channels compared to number of columns')
end

nParts=size(e,2)/nChan;
i=repmat((1:nChan:size(e,2))',1,nChan)+repmat(0:nChan-1,nParts,1);

A=e(:,i(:));
A=reshape(A,[],nChan);

if nargout>1
	t=[];
	if isempty(dt)
		warning('COMBCHAN:defaultDT','Default value for dt used!')
		dt=1;
	elseif isstruct(dt)
		if isfield(dt,'dt')
			if isfield(dt,'tBlocks')
				t=repmat((0:size(e,1)-1)'*dt.dt,1,nParts)	...
					+repmat(dt.tBlocks(1:nChan:end)-dt.tBlocks(1),size(e,1),1);
				t=t(:);
			else
				dt=dt.dt;
			end
		elseif isfield(dt,'SamplingRate')
			dt=1/dt.SamplingRate;	%(!)this function is normally not useful for this type of data!
		else
			error('Unknown format of "gegs"!')
		end
	end
	if isempty(t)
		t=(0:size(A,1)-1)'*dt;
	end
end
