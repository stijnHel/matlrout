function D=fitMultiSine(t,x,n,varargin)
%fitMultiSine - Fits multiple sines through signal
%       D=fitMultiSine(t,x,n[,options])
%       D=fitMultiSine(t,x[,options])
% Fits multiple sines by fitting a sine wave, subtracting the fitted sine
% from the original and starts again.
%
% It's a trial, without begin really succesful.
%
% see also fitsine

if nargin<3
	n=[];
	options={};
elseif isnumeric(n)
	options=varargin;
elseif iscell(n)
	if nargin>3
		error('Wrong input')
	end
	options=n;
	n=[];
else
	options=[{n} varargin];
	n=[];
end

tolStop=[];
relTolStop=[];
nMax=10;

if ~isempty(options)
	%!!!not yet implemented to split fitsin
	setoptions({'tolStop','nMax','relTolStop'},options{:})
end
if isempty(tolStop)&&isempty(n)
	if isempty(relTolStop)
		relTolStop=.01;
	end
	tolStop=(max(x)-min(x))/2*relTolStop;
end
if isempty(n)
	n=nMax;
end

D=[];
while true
	D1=fitsine(t,x,options);
	if isempty(D)
		D=D1;
	else
		D(end+1)=D1;
	end
	x=x-D1.y;
	if ~isempty(tolStop)&&max(abs(x))/2<tolStop
		break
	end
	if ~isempty(n)&&length(D)>=n
		break
	end
end
