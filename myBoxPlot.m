function myBoxPlot(x,varargin)
%myBoxPlot - My simple version of a boxplot
%    myBoxPlot(x,...)
% simple replacement for stat/boxplot, not using any stats-functions
%    quartiles are based on quicksort mechanism but only sorting relevant
%    parts.
%    Some starting effort was done in case of equals, but wasn't completed.
%    It's not sure if this function will work in these circumstances.  Even
%    equals to used thresholds might lead to wrong results.

% There were ideas for further increase the efficiency, but these are not
% implemented!

% extensions:
%      cell-input (ipv array)
%      origin-input (zie boxplot)

if numel(x)<=2
	error('Not enough data!')
elseif ~ismatrix(x)
	x=squeeze(x);
	if ~ismatrix(x)
		error('Multidimensionsl arrays are not allowed!')
	end
end
if size(x,1)==1
	x=x';
end

wBox=0.8;
wMax=0.6;

colBox=[0 0 0];
colOutlier=[];
mrkOutlier='x';
lwBox=get(gca,'defaultLineLinewidth');
lwMedian=lwBox*4;
lwMax=lwBox*2;
bMeanStdPlot = false;
wMean = 0.3;
colMean = [];
nSigma = 2;
bClearPlot = [];

if nargin>1
	setoptions({'wBox','wMax','colBox','colOutlier','mrkOutlier','lwBox'	...
			,'lwMedian','lwMax','bMeanStdPlot','wMean','colMean'	...
			,'nSigma','bClearPlot'}	...
		,varargin{:})
end
ccc=get(gcf,'DefaultAxesColorOrder');
if isempty(colOutlier)
	colOutlier=ccc(1,:);
end
if isempty(colMean)
	colMean = ccc(2,:);
end
if isempty(bClearPlot)
	bClearPlot=~strcmp(get(gca,'nextplot'),'add');
end

if bClearPlot
	cla
end

w2=wBox/2;

P=zeros(size(x,2),3);
for iX=1:size(x,2)
	Xi = x(:,iX);
	P(iX,:)=FindQuarts(Xi);
	P1 = P(iX,1);
	P2 = P(iX,2);
	P3 = P(iX,3);
	IQR  = P3-P1; % Interquartile range
	lim1 = P1-1.5*IQR;
	lim2 = P3+1.5*IQR;
	mxX = max(Xi(Xi<=lim2));
	mnX = min(Xi(Xi>=lim1));
	line(iX+[-w2 w2 w2 -w2 -w2]	...	the box
		,[P1 P1 P3 P3 P1]	...
		,'color',colBox	...
		,'linewidth',lwBox	...
		,'Tag','boxPlot'	...
		,'UserData',iX);
	line(iX+[-w2 w2]	... median
		,[P2 P2]	...
		,'color',colBox	...
		,'linewidth',lwMedian	...
		,'Tag','boxPlot'	...
		,'UserData',iX);
	if mxX>P2
		line([iX iX]	... to max
			,[P3 mxX]	...
			,'color',colBox	...
			,'linewidth',lwBox	...
			,'linestyle',':'	...
			,'Tag','boxPlot'	...
			,'UserData',iX);
	end
	if mxX>P2
		line([iX iX]	... to min
			,[P1 mnX]	...
			,'color',colBox	...
			,'linewidth',lwBox	...
			,'linestyle',':'	...
			,'Tag','boxPlot'	...
			,'UserData',iX);
	end
	line(iX+[-wMax wMax]/2	... max
		,[mxX mxX]	...
		,'color',colBox	...
		,'linewidth',lwMax	...
		,'Tag','boxPlot'	...
		,'UserData',iX);
	line(iX+[-wMax wMax]/2	... min
		,[mnX mnX]	...
		,'color',colBox	...
		,'linewidth',lwMax	...
		,'Tag','boxPlot'	...
		,'UserData',iX);
	B=Xi<mnX|Xi>mxX;
	if any(B)
		nB=sum(B);
		line(iX+zeros(nB,1),Xi(B)	... max
			,'color',colOutlier	...
			,'linestyle','none'	...
			,'marker',mrkOutlier	...
			,'Tag','boxPlot'	...
			,'UserData',iX);
	end
	if bMeanStdPlot
		mnX = mean(Xi);
		sX = std(Xi);
		line(iX+[-1 1 1 -1 -1]*wMean/2	...	the box
			,mnX+nSigma*sX*[-1 -1 1 1 -1]	...
			,'color',colMean	...
			,'linewidth',lwBox	...
			,'Tag','boxPlot'	...
			,'UserData',iX);
		line(iX+[-1 1]*wMean/2	... mean
			,[mnX mnX]	...
			,'color',colMean	...
			,'linewidth',lwMedian	...
			,'Tag','boxPlot'	...
			,'UserData',iX);
	end
end
set(gca,'XTick',1:size(x,2))

	function P=FindQuarts(x)
		%partly sorting x to find quartiles (1/4, median, 3/4)
		mn=min(x);
		mx=max(x);
		N=length(x);
		S=zeros(ceil(sqrt(N))+10,8);
		nS=0;
		
		% find median
		s=(mn+mx)/2;
		P2=FindPrctile(0.5,s,1,N,mn,mx);
		
		% find first quartile
		P1=NewPrctile(0.25);
		P3=NewPrctile(0.75);
		
		P=[P1 P2 P3];
		
		function s=FindPrctile(p,s,i1,i2,s1,s2)
			while true
				I1=i1;
				I2=i2;
				n1=0;
				n2=0;
				while i1<i2
					while i1<i2&&x(i1)<=s
						i1=i1+1;
						n1=n1+(x(i1)==s);
					end
					while i1<i2&&x(i2)>=s
						i2=i2-1;
						n2=n2+(x(i2)==s);
					end
					if i1<i2
						%[x(i1),x(i2)]=deal(x(i2),x(i1));	% too slow
						a=x(i1);
						x(i1)=x(i2);
						x(i2)=a;
						i1=i1+1;
						i2=i2-1;
					end
				end		% while i1<i2
				if i1==i2
					if x(i1)<s
						i1=i1+1;
					elseif x(i1)>s
						i2=i2-1;
					end
				else
					ietsdoenxxx=1;
				end
				k1=i1+n1-1;
				k2=N-i2+n2;
				%disp([I1 I2 i1 i2 k1 k2 sum(x<s) sum(x>s)])
				nS=nS+1;
				p1=k1/N;	% combination k1,k2?
				S(nS,1)=s;
				S(nS,2)=i1;
				S(nS,3)=i2;
				S(nS,4)=n1;
				S(nS,5)=n2;
				S(nS,6)=p1;
				S(nS,7)=I1;
				S(nS,8)=I2;
				if nS>size(S,1)
					xxxxxxxxxxxxxxxxxx=0;
				end
				if p1>=p&&1-k2/N<=p||x(I1)>=x(I2)
					break
					%else is almost...
				elseif p1<p
					s1=s;
					s=(s1+s2)/2;	% rather relative to k1/k2 or something?
					i2=I2;
				else
					s2=s;
					s=(s1+s2)/2;	% smarter?
					i1=I1;
				end
			end		% while bLoop1
		end		% function FindPrctile
		
		function s=NewPrctile(p)
			i=findclose(S(1:nS,6),p);
			if S(i,6)>p
				i2=S(i,2);
				s2=S(i);
				p2=S(i,6);
				ii=find(S(1:nS,6)<p);
				if isempty(ii)
					i1=1;
					p1=0;
					s1=mn;
				else
					[p1,imx]=max(S(ii,6));
					i1=ii(imx);
					s1=S(i1);
					i1=S(i1,3);
				end
			else	% ?if S(i,6)==p?
				i1=S(i,3);
				p1=S(i,6);
				s1=S(i);
				ii=find(S(1:nS,6)>p);
				if isempty(ii)
					i2=N;
					p2=1;
					s2=mx;
				else
					[p2,imx]=min(S(ii,6));
					i2=ii(imx);
					s2=S(i2);
					i2=S(i2,2);
				end
			end
			s=FindPrctile(p,(s1+s2)/2,i1,i2,s1,s2);
		end		% NewPrctile
	end		% function FindQuarts
end		% function myBoxPlot
