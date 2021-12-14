function [X,Yout,F,Xh] = RemoveHarmonics(X,varargin)
%RemoveHarmonics - Remove harmonics from a signal or spectrum
%      X = RemoveHarmonics(X,f,'dt',<sample-time>);
%              Take X as a time series, returns signal with harmonics of f
%                 from the signal (sines at f = f, f = 2.f, ...)
%      X = RemoveHarmonics([],X,f,'fR',<frequency resolution>);
%              Take X as a freqency spectrum and returns spectrum
%
%  possitilities for sample time input:
%        dt: sample time (can also be used for spectrum input)
%        fs: sample frequency
%        fR: resolution of spectrum
%      exactly 1 of these must be given
%
%  If dt or fs is given for spectrum input, it is assumed that the full
%  spectrum is given (not half!), meaning that fs would be the next point
%  after the last given spectrum-point.

if isempty(X)	% spectrum input
	bTimeInput = false;
	Y = varargin{1};
	f = varargin{2};
	options = varargin(3:end);
else	% time input
	bTimeInput = true;
	f = varargin{1};
	options = varargin(2:end);
end
if isempty(options)
	error('Sorry, not enough inputs!!!')
end

dt = [];
fs = [];
fR = [];
Nharmonics = [];	% maximum number of harmonics (fRemoved = [fR, 2*fR,..., Nharmonics*fR])
Rharmonics = [];	% range harmonics to be removed
nRemove = 1;	% used for putting frequency points to zero
[bUnwindow] = false;	% try to "undo" windowing
setoptions({'dt','fs','fR','Nharmonics','Rharmonics','nRemove','bUnwindow'}	...
	,options{:})

if bTimeInput
	dX = mean(X);
	W = hanning(length(X));
	Y = fft((X(:)-dX).*W);
end

if ~isempty(dt)
	fs = 1/dt;
	fR = fs/length(Y);
elseif ~isempty(fs)
	fR = fs/length(Y);
else
	fs = fR*length(Y);
end

nHarMax = floor(fs/2/f);
if nHarMax*f/fR>length(Y)/2-2	% don't remove too close to middle point (avoid problems keeping symmetric fft)
	nHarMax = nHarMax-1;
end
if isempty(Rharmonics)
	if isempty(Nharmonics)
		Nharmonics = nHarMax;
	else
		Nharmonics = min(nHarMax,Nharmonics);
	end
	Rharmonics = 1:Nharmonics;
else
	Rharmonics(Rharmonics>nHarMax) = [];
end
Y0 = Y;
for h = Rharmonics(:)'
	i = 1+h*f/fR;
	i1 = floor(i);
	i2 = i1+1;
	if abs(Y(i1))>=abs(Y(i2))
		i0 = i1-1;
	else
		i0 = i1;
		i1 = i2;
		i2 = i2+1;
	end
	n = nRemove;
	if abs(abs(Y(i0))-abs(Y(i2)))>abs(Y(i1))-max(abs(Y([i0,i2])))/2	% 2 point peak
		if abs(Y(i0))>abs(Y(i2))
			ii = [i0,i1];
		else
			ii = [i1,i2];
		end
		n = n-2;
	else	% single peak
		ii = i1;
		n = n-1;
	end
	i1 = ii(1)-1;
	i2 = ii(end)+1;
	while n>0
		if abs(Y(i1))>=abs(Y(i2))
			ii(end+1) = i1; %#ok<AGROW>
		else
			ii(end+1) = i2; %#ok<AGROW>
		end
		n = n-1;
	end
	Y(ii) = 0;
	Y(end+2-ii) = 0;
end

if bTimeInput
	i1 = round(length(X)/50);
	ii = i1+1:length(X)-i1;
	X = real(ifft(Y));
	if bUnwindow
		X(ii) = X(ii)./max(1e-3,W(ii));
	end
	X = X+dX;
end
if nargout>1
	Yout = Y;
	if nargout>2
		F = (0:length(Y)-1)'*fR;
		if nargout>3
			dY = Y0-Y;
			Xh = real(ifft(dY));
		end
	end
end
