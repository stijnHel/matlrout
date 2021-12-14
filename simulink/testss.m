function [sys,x0,nx]=testss(t,x,u,flag,p);
% TESTS	is a M-file to read all results in a simulation

global stestvar istestvar bLogRtime
if ~exist('p','var');p=[];end
if flag==0
	eval(['[sys,x0,nx]=' p '(t,x,u,flag);']);
	istestvar=1;
	stestvar=[];
elseif flag<9
	eval(['sys=' p '(t,x,u,flag);']);
	if isempty(bLogRtime)
		bLogRtime=false;
	end
	if bLogRtime
		stokvar=[now flag t u' x' sys'];
	else
		stokvar=[flag t u' x' sys'];
	end
	n1=length(stokvar);
	if isempty(stestvar)
		stestvar=zeros(10000,n1);
	end
	n2=size(stestvar,2);
	if n2<n1
		fprintf('stestvar verlengd %2d --> %2d\n',n2,n1);
		stestvar=[stestvar zeros(size(stestvar,1),n1-n2)];
	elseif n1<n2
		fprintf('stokvar verlengd %2d --> %2d\n',n1,n2);
		stokvar=[stokvar zeros(1,n2-n1)];
	end
	if istestvar>length(stestvar)
		stestvar=[stestvar;zeros(10000,n1)];
	end
	stestvar(istestvar,:)=stokvar;
	istestvar=istestvar+1;
else
	istestvar=istestvar-1;
	stestvar=stestvar(1:istestvar,:);
	eval(['[sys,x0,nx]=' p '(t,x,u,flag);']);
end

