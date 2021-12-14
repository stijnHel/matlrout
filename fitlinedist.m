function [A,D]=fitlinedist(X,Y,p0,bSVD)
%FITLINEDIST - Fit line in points with minimal squared rectangular distance
%   Recursive function find a "best orientation" in combination with a shift.
%   Not the most optimal procedure!!
%
%     A = fitlinedist(X,Y)
%           A: [a,b,c] - a.x_l + b.y_l = c

% it is better to use a while loop, rather than being recursive?!!!!

% procdure:
%    - make list of orientations of lines(based on third input)
%    - for each orientation take "best fitting offset"
%    

% can this be done with SVD?
if nargin>3&&bSVD
	% see: https://en.wikipedia.org/wiki/Total_least_squares
	% created for multidimensional X and Y but only tested for vectors!!!!
	Z=[X,ones(size(X,1),1),Y];
	[U,S,V]=svd(Z,0);
	n = size(X,2)+1;
	Vxy=V(1:n,n+1:end);
	Vyy=V(n+1:end,n+1:end);
	A = (-Vxy/Vyy)';	% output not like no bSVD!!!!!
	if n~=2||size(Y,2)~=1
		E = Z(:,n+1:end)-Z(:,1:n)*A';
	else
		E = CalcDistPtLine(Z(:,[1 3]),A);
	end
	D = struct('U',U,'S',S,'V',V,'Vxy',Vxy,'Vyy',Vyy,'E',rms(E),'Elist',E);
else
	if ~exist('p0','var')||isempty(p0)
		p0=pi;
		dPi=pi/20;
	elseif length(p0)<2
		dPi=pi/20;
	else
		dPi=diff(p0)/40;
		p0=mean(p0);
	end
	phi=p0-dPi*20:dPi:p0+dPi*20;	% ?is pi niet ver genoeg (ipv 2 pi)
	D=phi;
	for i=1:length(phi)
		a=cos(phi(i));
		b=sin(phi(i));
		axby=a*X+b*Y;
		c=mean(axby);
		D(i)=sum((axby-c).^2);
	end
	[mn,i]=min(D);
	if i==1
		phi1=(-1:1)*dPi;
		D1=D([end 1 2]);
	elseif i==length(phi)
		phi1=(-2:0)*dPi;
		D1=D([end 1 2]);
	else
		phi1=phi(i-1:i+1);
		D1=D(i-1:i+1);
	end
	p=polyfit(phi1,D1,2);
	phimin=p(2)/(-2*p(1));
	if dPi>0.1
		[A,D]=fitlinedist(X,Y,[phimin-dPi,phimin+dPi]);
		return
	end
	a=cos(phimin);
	b=sin(phimin);
	axby=a*X+b*Y;
	c=mean(axby);
	A=[a b c];
	D = struct('phi',phimin,'E',sqrt(max(0,polyval(p,phimin)/length(X))),'p0',p0,'dPi',dPi,'D',D);
end
