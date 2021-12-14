function [pks,locs]=zoeklocmax(x,varargin)
%zoeklocmax - Zoekt naar locale maxima (gemaakt voor pieken in FFT-spectrum)
%   [pks,locs]=zoeklocmax(x[,options])
% kan ook gebruikt worden als
%   [pks,locs]=zoeklocmax;
%       "leest" fft-plots
%       locs geeft dan de frequentie
%       enkel eerste helft van plot is gebruikt
% vermits gemaakt voor FFT-spectrum, gemaakt voor signaal >=0
%
% zoekt telkens de grootste piek.  Na het vinden van een piek worden
% elementen rond de piek op 0 gezet.  Dalende delen worden genomen met
% <nLast> elementen om korte stijgingen toe te laten.
%
% options:
%     fStopMax : factor to maximum, used to distinguish peaks
%     xmin : minimum height of peak that will be detected
%     nMax : maximum number peaks that will be detected
%     nLast : number of consecutive elements for removing peak
%     nNeighFracPos : calculates fractional position using neighbours (symmetrical)
%     bRMS : uses RMS-value (in fact root sum squared (only if previous >0)
%     bSortLoc, bSortHeight : sorting

if nargin==0||isempty(x)
	% reads the plot, supposed to be a fftplot
	D=getplotdata;
	if ~iscell(D)
		D={D};
	end
	pks=cell(1,length(D));
	locs=pks;
	for i=1:length(D)
		D{i}=D{i}(1:round(end/2),:);	% half the spectrum
		D1=cell(2,size(D{i},2)-1);
		for j=1:size(D1,2)
			[D1{:,j}]=zoeklocmax(D{i}(:,j+1),varargin{:});
			D1{2,j}=D{i}(D1{2,j});	% frequency (rather than index!)
		end
		if size(D1,2)>1
			pks{i}=D1(1,:);
			locs{i}=D1(2,:);
		else
			pks{i}=D1{1};
			locs{i}=D1{2};
		end
	end
	return
end

fStopMax=0.1;
xmin=0;
nMax=10;
nLast=2;
nNeighFracPos=0;
bRMS=false;
bSortLoc=false;
bSortHeight=false;

if ~isempty(varargin)
	setoptions({'fStopMax','xmin','nMax','nLast','nNeighFracPos','bRMS'	...
			,'bSortLoc','bSortHeight'}	...
		,varargin{:})
end
bRMS=bRMS&&nNeighFracPos>0;

nMax=min(floor(length(x)/2),nMax);
pks=zeros(1,nMax);
locs=pks;
nPeak=0;
xl=zeros(1,nLast);
if nNeighFracPos>0
	x=x(:);
	if bRMS
		x=x.^2;
	end
end
% remove start and end increasing parts
j=1;
mx=x(1);
xl(1)=mx;
xl(2:end)=0;
while j<=length(x)&&any(x(j)<=xl)
	xl=[x(j) xl(1:nLast-1)];
	x(j)=xmin;
	j=j+1;
end
j=length(x);
mx=x(j);
xl(1)=mx;
xl(2:end)=0;
while j>0&&any(x(j)<=xl)
	xl=[x(j) xl(1:nLast-1)];
	x(j)=xmin;
	j=j-1;
end
% find maxima
while nPeak<nMax
	[mx,i]=max(x);
	if mx<=xmin
		break
	end
	nPeak=nPeak+1;
	if nNeighFracPos>0
		jj=(max(1,i-nNeighFracPos):min(length(x),i+nNeighFracPos))';
		pks(nPeak)=sum(x(jj));
		locs(nPeak)=i+sum((jj-i).*x(jj))/pks(nPeak);
	else
		pks(nPeak)=mx;
		locs(nPeak)=i;
	end
	x(i)=xmin;
	j=i+1;
	xl(1)=mx;
	xl(2:end)=0;
	bLoop=true;
	while j<=length(x)&&(bLoop||any(x(j)<=xl))
		xl=[x(j) xl(1:nLast-1)];
		x(j)=xmin;
		j=j+1;
		bLoop=bLoop&&j<=length(x)&&x(j)>=mx*fStopMax;
	end
	j=i-1;
	xl(1)=mx;
	xl(2:end)=0;
	bLoop=true;
	while j>0&&(bLoop||any(x(j)<=xl))
		xl=[x(j) xl(1:nLast-1)];
		x(j)=xmin;
		j=j-1;
		bLoop=bLoop&&j>0&&x(j)>=mx*fStopMax;
	end
end
if nPeak<nMax
	pks=pks(1:nPeak);
	locs=locs(1:nPeak);
end
if bRMS
	pks=sqrt(pks);
end
if bSortLoc
	[locs,ii]=sort(locs);
	pks=pks(ii);
elseif bSortHeight
	% only interesting if nNeighFracPos>0 
	[pks,ii]=sort(pks);
	locs=locs(ii);
end
