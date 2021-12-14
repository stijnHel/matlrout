function e=ontpiek1(e,N1,fS,varargin)
%ontpiek1 - Onptieker op basis van afwijkingen van gemiddelde
%    e=ontpiek1(e[,N1,fS[,opties]])
%
%   N1 lengte waarover gemiddelde genomen wordt (default 25)
%   fS factor (bij std) om pieken te detecteren (default 3)
%  opties
%   N2 lengte van aanpassend deel (default round(N1/2)
%   NmaxPiek maximum aantal pieken (default max(2,N1/10))
%   NmaxSucc maximum aantal opeenvolgende punten als piek
%                                (default 2)

if nargin<2||isempty(N1)
	N1=25;
end
if nargin<3||isempty(fS)
	fS=3;
end
N2=[];
NmaxPiek=[];
NmaxSucc=2;
bDetrend=false;

if ~isempty(varargin)
	setoptions({'N2','NmaxPiek','NmaxSucc','bDetrend'},varargin{:})
end

if isempty(N2)
	N2=round(N1/2);
elseif N2>N1
	error('N2 kan niet groter zijn dan N1')
end
if isempty(NmaxPiek)
	NmaxPiek=max(2,floor(N1/10));
end

iP1=floor((N1-N2)/2);
iPart=iP1+1:iP1+N2;

bTransp=false;
if size(e,1)<size(e,2)
	e=e';
	bTransp=true;
end

[nE,nc]=size(e);
if nc>1
	for i=1:nc
		e(:,i)=ontpiek1(e(:,i),N1,fS	...
			,'N2',N2,'NmaxPiek',NmaxPiek		...
			,'NmaxSucc',NmaxSucc,'bDetrend',bDetrend);
	end
	return
end
iE=0;
while iE+N1<=nE
	e1=e(iE+1:iE+N1,:);
	if bDetrend
		e1=detrend(e1);
	end
	mE=mean(e1);
	sE=std(e1);
	bP=abs(e1(iPart)-mE)>sE*fS;
	if any(bP)
		if sum(bP)>NmaxPiek
			ii=iE;	% breakpoint position
			%do nothing?
		else
			iP=find(bP);
			iP(end+1)=1e20;
			i=1;
			while i<length(iP)
				j=i+1;
				while iP(j)==iP(j-1)+1
					j=j+1;
				end
				if j-i<=NmaxSucc
					i1=iPart(iP(i))-1;
					i2=iPart(iP(j-1))+1;
					x1=e(iE+i1);
					x2=e(iE+i2);
					e(iE+i1+1:iE+i2-1)=x1+(x2-x1)*(1:i2-i1-1)'/(i2-i1);
				else
					jj=iE;	% breakpoint position
				end
				i=j;
			end
		end
	end
	iE=iE+N2;
end
if bTransp
	e=e';
end
