function [tau,Y,Tres,Ilim]=ident1st2(t,x,y,tlim,t_est)
% IDENT1ST2 - Identificeert een eerste orde systeem op basis van in en out
%   ident1st2(t,x,y,tlim,t_est)

dt=mean(diff(t));
if exist('tlim','var')&&~isempty(tlim)
	iLim=find(t>=tlim(1)&t<=tlim(2));
else
	iLim=1:length(t);
	tlim=[t(1) t(end)];
end
if ~exist('t_est','var')||isempty(t_est)
	t_est=diff(tlim)/20;
end
a=cumprod([2^(1/10)*ones(1,19)])*0.5;
dY=zeros(1,0);
taus=[];
taus1=t_est*[.01 .02 .05 .1 .2 .5 1 2 5 10];
for iLoop=1:2
	yest=calc1storder(x(iLim),taus1,dt);
	dY1=sqrt(mean((yest-y(iLim,ones(1,length(taus1)))).^2));
	taus(1,end+1:end+length(dY1))=taus1;
	dY(1,end+1:end+length(dY1))=dY1;
	[mn,i]=min(dY1);
	if i==1
		tau1=taus1(1);
	elseif i==length(dY1)
		tau1=taus1(end);
	else
		p=polyfit(taus1(i-1:i+1),dY1(i-1:i+1),2);
		tau1=-p(2)/p(1)/2;
	end
	taus1=tau1*a;
end
tau=tau1;
if nargout>1
	Y=calc1storder(x(iLim),tau,dt);
	dY2=sqrt(mean((Y-y(iLim)).^2));
	if dY2>mn
		warning('!!!eerdere schatting was beter dan laatste schatting!!?')
	end
	if nargout>2
		[taus,i]=sort(taus);
		Tres=[taus;dY(i)]';
		if nargout>3
			Ilim=iLim;
		end
	end
end

function y=calc1storder(x,tau,dt)
y=zeros(length(x),length(tau));
y(1,:)=x(1);
%if any(tau<=dt)
%	warning('!!tau is kleiner dan dt!!')
%end
k=exp(-min(1,dt./tau));
for i=2:length(x)
	y(i,:)=k.*y(i-1,:)+(1-k)*x(i);
end
