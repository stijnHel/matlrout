function [mxD,D,tD,dT]=CalcMaxDiff(t1,X1,t2,X2,varargin)
%CalcMaxDiff - Calculate maximum difference between signals
%
%   The difference between signals with (possibly) differently sampled
%   signals is calculated based on interpolation.
%
%   [mxD,D]=CalcMaxDiff(t1,X1,t2,X2,<options>)
%          t1,t2: time (strictly increasing)
%          X1,X2: signals (the same number of channels)
%          options: currently only one option
%                 'mInterp': interpolation method
%                 (see interp1)
%   Only points with common times are regarded.
%
% (It must be clear that "t" doesn't need to be time.)

mInterp='spline';	% method for interpolation

if ~isempty(varargin)
	setoptions({'mInterp'},varargin{:})
end

B1=t1>=t2(1)&t1<=t2(end);
B2=t2>=t1(1)&t2<=t1(end);

tD=union(t1(B1),t2(B2));
	% (to avoid difficulties with B1, iA and iB are not used here in further processing)
Y1=interp1(t1,X1,tD,mInterp);
Y2=interp1(t2,X2,tD,mInterp);

% calculate differences between points in tD and sampling points
dT=zeros(length(tD),4);	% [dT1 dT2 Dt1 Dt2]
	% with dT<i> shortest distance to sampling point
	%      Dt<i> difference between sampoing points
i1=1;
while t1(i1+1)<=tD(1)
	i1=i1+1;
end
i2=1;
while t2(i2+1)<=tD(1)
	i2=i2+1;
end
t1N=t1(i1+1);
t2N=t2(i2+1);
dt1=t1N-t1(i1);
dt2=t2N-t2(i2);
for i=1:length(tD)
	if t1N<=tD(i)
		i1=i1+1;
		if i1<length(t1)
			t1N=t1(i1+1);
			dt1=t1N-t1(i1);
		end
	end
	if t2(i2+1)<=tD(i)
		i2=i2+1;
		if i2<length(t2)
			t2N=t2(i2+1);
			dt2=t2N-t2(i2);
		end
	end
	dT(i)=min(tD(i)-t1(i1),t1N-tD(i));
	dT(i,2)=min(tD(i)-t2(i2),t2N-tD(i));
	dT(i,3)=dt1;
	dT(i,4)=dt2;
end

D=Y2-Y1;
mxD=max(abs(D));

% the idea is to extend this calculation to take distance between sampling
% points into account (points sampled at the same times should have more
% weight than points where one signal is sampled far from the tested time.
% The interpolation method will have impact tool.
% Time differences of sampling points are calculated, but not used.  The
% user can do this by using the fourth output argument.
