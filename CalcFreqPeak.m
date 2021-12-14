function [f,A,iMax,di] = CalcFreqPeak(x,y,nPeaks,varargin)
%CalcFreqPeak - Calc frequency peak ("sub-df resolution")
%
%      [f,A] = CalcFreqPeak(F,Y[,nPeaks[,fRange]])
%      [f,A] = CalcFreqPeak(F,Y,nPeaks,<options>)
%
%                  F: frequency range
%                  Y: absolute values of spectrum
%                  nPeaks: number of peaks to be searched (default 1)
%
%      [f,A,iMax,di] = CalcFreqPeak(...)
%              only for last peak(!)
%                  index of last found peak, "correction" of index
%
% Calculate peak frequency in spectrum (assuming the use of a hanning window).
%
% see also: StoneHann

fMin = [];
fMax = [];

if nargin<3||isempty(nPeaks)
	nPeaks = 1;
end

if ~isempty(varargin)
	options = varargin;
	if isnumeric(options{1})
		if isscalar(options{1})
			fMin = options{1};
			if length(options)>1 && isnumeric(options{2})
				fMax = options{2};
				options(2) = [];
			end
			options(1) = [];
		elseif numel(options{1})~=2
			error('2 elements expected for frequency range!')
			%??? allow also multiple outputs:
			%        [fMin1,fMax1 ; fMin2,fMax2 ; ...]
		else
			fMin = options{1}(1);
			fMax = options{1}(2);
		end
	end
	if ~isempty(options)
		setoptions({'fMin','fMax'},options{:})
	end
end
if ~isempty(fMin)
	B = x<fMin;
	y(B) = -Inf;
end
if ~isempty(fMax)
	B = x>fMax;
	y(B) = -Inf;
end

f=zeros(1,nPeaks);
A=f;
for i=1:nPeaks
	[Xmax,iMax]=max(y);
	if Xmax==0
		f = f(1:i-1);
		A = A(1:i-1);
		break
	elseif iMax==1
		%!!! not really optimal!!!
		f(i)=x(1);
		A(i)=y(1);
		if f(i)==0
			A(i)=A(i)/2;
		end
		y(1:2)=0;
		di = 0;
	elseif iMax==length(x)
		%!!! not really optimal!!!
		f(i)=x(iMax);
		A(i)=y(iMax);
		di = -1;
	else
		Xm_p=y(iMax-1);	% previous
		Xm_n=y(iMax+1);	% next
		s=sign(Xm_n-Xm_p);

		switch s
			case -1	% Xm_n < Xm_p
				r=Xmax/Xm_p;
				p=(r-2)/(r+1);
				i_f=iMax+p;
				A(i)=(1-p^2)/sinc(p)*Xmax;
				di=-1;
			case 0	% Xm_n = Xm_p
				A(i)=Xmax;
				i_f=iMax;
				di = 0;
			case 1	% Xm_n > Xm_p
				r=Xmax/Xm_n;
				p=(2-r)/(r+1);
				i_f=iMax+p;
				A(i)=(1-p^2)/sinc(p)*Xmax;
				di = 0;
		end
		if i<nPeaks
			% put peak to 0 for next peaks
			j = iMax-1;
			yLast = y(iMax);
			while j>1 && y(j)<=yLast && y(j-1)<=y(j)
				yLast = y(j);
				y(j) = 0;
				j = j-1;
			end
			if j<=2
				y(1:j) = 0;
			end
			j = iMax+2;
			yLast = y(iMax+1);
			while j<length(y) && y(j)<=yLast && y(j+1)<=y(j)
				yLast = y(j);
				y(j) = 0;
				j = j+1;
			end
			if j==length(y)
				y(j) = 0;
			end
			y(iMax:iMax+1)=0;
		end

		f(i)=x(1)+(i_f-1)*(x(2)-x(1));
	end
end
A=A*2;
