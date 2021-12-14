function [SWave,Y]=cumSineFollow(x,Npt,freq,varargin)
%cumSineFollow - estimator of sine amplitude and phase with DC
%   [SWave,Y]=cumSineFollow(x,Npt,freq[,options])
%  freq : sine wave frequency relative to sample frequency
%     remark: freq is double that to give to functions like butter(!)
%
%  first the DC of the signal is determined (this option can be switched off)
%  then amplitude and phase is calcultated by cumulative sums of products
%     the signal (with subtracted DC) with sines and cosines.
%     Since A and phase is calculated for every point, goertzel algorithm
%     is not used.
%
%  SWave : struct with
%           A : amplitude
%           phase : phase (in rad)
%           ix : index to x where A/phase is available
%           dc : DC-part of x
%  Y is giving intermediate results, and the estimated signal from A/phase
%    (without DC)
%         [time DC x(without DC) estimated x(without DC)]
%
% options: (only one)
%      bDCcalc : do DC-extraction (default : true)
%
%  function can also be used to calculate the estimated signal from A/phase
%      Y = cumSineFollow(SWave[,FIRorder,FIRfreq]);
%               FIR.... can be used for applying a FIR-filter before
%                   calculation
%      [Y,A] = ...
%         gives filtered amplitude, phase and DC
%
% remark : for signals with constant DC, DC-extraction is not necessary and
%     can even give some artefacts to the result

if isstruct(x)
	A=x.A;
	ph=x.phase;
	dc=x.dc;
	if nargin>1
		B=fir1(Npt,freq);
		A=filter(B,1,A);
		ph=filter(B,1,unwrap(ph));
		dN=round(Npt/2);
		A=A(min(end,dN+1:dN+end));
		ph=ph(min(end,dN+1:dN+end));
		dc=dc(min(end,dN+1:dN+end));
	end
	dc=dc(x.ix);
	nCols=size(A,2);
	xx=(x.ix-1)*(2*pi*x.freq);
	if nCols>1
		xx=repmat(xx,1,nCols);
	end
	SWave=A.*cos(xx+ph)+dc;
	if nargout>1
		Y=[A rem((ph+pi),2*pi)-pi dc];
	end
	return
end

bDCcalc=true;
bLoop=false;
bIX=[];

if ~isempty(varargin)
	if length(varargin)==1
		options=varargin{1};
	else
		options=varargin;
	end
	setoptions({'bDCcalc','bLoop','bIX'},options{:});
end
if isempty(bIX)
	bIX=~bLoop;
end

nX=size(x,1);
if nX==1
	x=x';
	nX=size(x,1);
end
nCols=size(x,2);
bFastLoop=bLoop&&nCols==1;

if bDCcalc
	cx=conv(x(:,1),ones(Npt,1)/Npt);
	if nCols>1
		cx(1,nCols)=1;
		for i=2:nCols
			cx(:,i)=conv(x(:,i),ones(Npt,1)/Npt);
		end
	end
	Npt2=round(Npt/2);
	if rem(Npt,2)
		iL1=Npt2-1;
		cx=cx([Npt+zeros(1,Npt2) (Npt:end-Npt) end-Npt+zeros(1,Npt2-1)],:);
	else
		iL1=Npt2;
		cx=cx([Npt+zeros(1,Npt2) (Npt:end-Npt) end-Npt+zeros(1,Npt2)],:);
	end
	x=x-cx;
else
	cx=zeros(nX,1);
	Npt2=round(Npt/2);
	iL1=floor(Npt/2);
end

if bFastLoop
	% minimize memory
	xx=(0:nX-1)'*(2*pi*freq);
	Zx=[zeros(1,nCols);cumsum(x.*repmat(sin(xx),1,nCols))];
	Zy=[zeros(1,nCols);cumsum(x.*repmat(cos(xx),1,nCols))];
	f=2/Npt;
	for i=1:length(Zx)-Npt
		Zx1=Zx(i)-Zx(i+Npt);
		Zy1=Zy(i+Npt)-Zy(i);
		Zx(i)=sqrt(Zx1^2+Zy1^2)*f;	% A
		Zy(i)=atan2(Zx1,Zy1);	% phase
	end
	Zx(end-Npt+1:end)=[];
	Zy(end-Npt+1:end)=[];
	SWave=struct('A',Zx,'phase',Zy,'Npt',Npt,'freq',freq);
elseif bLoop
	xx=(0:nX-1)'*(2*pi*freq); %#ok<UNRCH>
	Zx=[zeros(1,nCols);cumsum(x.*repmat(sin(xx),1,nCols))];
	Zy=[zeros(1,nCols);cumsum(x.*repmat(cos(xx),1,nCols))];
	for i=1:length(Zx)-Npt
		Zx(i,:)=Zx(i,:)-Zx(i+Npt,:);
		Zy(i,:)=Zy(i+Npt,:)-Zy(i,:);
	end
	Zx(end-Npt+1:end,:)=[];
	Zy(end-Npt+1:end,:)=[];
	A=sqrt(Zx.^2+Zy.^2)/(Npt/2);
	phase=atan2(Zx,Zy);
	SWave=struct('A',A,'phase',phase,'Npt',Npt,'freq',freq);
else
	xx=(0:nX-1)'*(2*pi*freq);
	Zx=[zeros(1,nCols);cumsum(x.*repmat(sin(xx),1,nCols))];
	Zy=[zeros(1,nCols);cumsum(x.*repmat(cos(xx),1,nCols))];
	Zx=Zx(1:end-Npt,:)-Zx(Npt+1:end,:);
	Zy=Zy(Npt+1:end,:)-Zy(1:end-Npt,:);
	A=sqrt(Zx.^2+Zy.^2)/(Npt/2);
	phase=atan2(Zx,Zy);
	SWave=struct('A',A,'phase',phase,'Npt',Npt,'freq',freq);
end

if bIX
	SWave.ix=(iL1:nX-Npt2)';
end
if bDCcalc
	SWave.dc=cx;
end

if nargout>1
	Y=[xx(SWave.ix,1) cx(SWave.ix) x(SWave.ix) Zx Zy A.*cos(repmat(xx(SWave.ix),1,nCols)+phase)];
end
