function C=WPfilter(t,x,nLevels)
%WPfilter - Calculate wavelet package filter (own calc)
%    C=WPfilter(t,x,nLevels)
%    C=WPfilter([filter_L;filter_H],x,nLevels)
%
% C : cell array with all coefficients up to level <nLevels>

if isa(t,'wptree')
	filtL=get(t,'Lo_D');
	filtH=get(t,'Hi_D');
else
	filtL=t(1,:);
	filtH=t(2,:);
end

%%%%%%!no edge improvement work!!!!
C=cell(1,nLevels+1);
C{1}=x;
nX=length(x);
nC=1;
for iLevel=1:nLevels
	nCnew=nC*2;
	nXnew=floor((nX+length(filtL)-1)/2);
	C{iLevel+1}=zeros(nXnew,nCnew);
	for iC=1:nC
		x=conv(C{iLevel}(:,iC),filtL);
		C{iLevel+1}(:,iC*2-1)=x(2:2:end);
		x=conv(C{iLevel}(:,iC),filtH);
		C{iLevel+1}(:,iC*2)=x(2:2:end);
	end
	nC=nCnew;
	nX=nXnew;
end
