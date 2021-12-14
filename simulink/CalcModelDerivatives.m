function [dX,dXlist]=CalcModelDerivatives(model,t,x,u,bTerminate,nMulti)
%CalcModelDerivatives - Calculates the derivatives of the states in a model
%       dX=CalcModelDerivatives(model,t,x,u)

if nargin<5
	bTerminate=[];
end
if nargin<6		% trial to test if multiple calls give different results
	nMulti=[];
end

modStat=get_param(model,'SimulationStatus');
switch modStat
	case 'stopped'
		bCompile=true;
	case {'compiled','paused'}
		bCompile=false;
		if isempty(bTerminate)	% leave model in the same state
			bTerminate=false;
		end
	case {'updating','initializing','running','terminating'}
		error('Don''t use this function on running models!')
	otherwise
		error('The model is in a state where "I" don''t know what to do!')
end

if bCompile
	feval(model,[],[],[],'compile')	% compile model (needed for further calls)
end
try
	if ~isempty(nMulti)&&nMulti>1
		dXlist=cell(1,nMulti);
		for i=1:nMulti
			feval(model,t,x,u,'outputs');	% set state to the right values
			dX=feval(model,t,x,u,'derivs');
			dXlist{i}=dX;
		end
	else
		feval(model,t,x,u,'outputs');	% set state to the right values
		dX=feval(model,t,x,u,'derivs');
	end
catch err
	DispErr(err)
	warning('Error! Geen afgeleide kon bepaald worden!')
	dX=[];
end

if isempty(bTerminate)||bTerminate
	% terminate the use of the model
	feval(model,[],[],[],'term')
end
