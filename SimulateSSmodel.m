function [T,X,Y]=SimulateSSmodel(A,B,C,D,t1,t2,U,X0,U0)
%SimulateSSmodel - Simulate model using state space description
%     [X,Y,T]=SimulateSSmodel(A,B,C,D,t1,t2,U,X0,U0)

global SStLast SSiLast SSnCall SSnOut SStStart SStMAX

if ~exist('X0','var')||isempty(X0)
	X0=zeros(size(A,1),1);
end
if isempty(U)
	TU=[];
	DU=[];
else
	TU=U(:,1);
	DU=U(:,2:end);
	if exist('U0','var')&&~isempty(U0)
		DU=bsxfun(@minus,DU,reshape(U0,1,[]));
	end
end
SS_A=A;
SS_B=B;
SS_T=TU;
SS_U=DU;
SS_Ttot=t2;
if isempty(SStMAX)
	SStMAX=10/1440;	% 10min
end
%SSode('set',A,B,TU,DU)
%SSode('setTtot',t2)
SSopt=odeset('OutputFcn',@SSout);
SSiLast=1;
SSnCall=0;
SSnOut=0;
SStStart=now;
Ucurrent=DU(1,:)';
[T,X]=ode45(@SSode,[t1 t2],X0,SSopt);
Y=zeros(length(T),size(C,1));
UU=interp1(U(:,1),U(:,2:end),T);
for i=1:length(T)
	y=C*X(i,:)';
	if ~isempty(D)
		ui=UU(i,:)';
		y=y+D*ui;
	end
	Y(i,:)=y;
end

	function dXdt=SSode(t,X)
		%SSode    - ODE-definition function using state space description
		%     dXdt=SSode(t,X) - Calculate state derivative at time t, state X
		%
		%   see also SimulateSSmodel
		
		SSnCall=SSnCall+1;
		
		%u=interp1(SS_T,SS_U,t)'; % too slow!!
		dXdt=SS_A*X+SS_B*Ucurrent;
		SStLast=t;
	end		% SSode

	function bStop=SSout(t,~,flag)
		%fprintf('%d in, %d out\n',nargin,nargout)
		bStop=false;
		if ~isempty(flag)
			switch flag
				case 'init'
					status('Simulating SS-model using SSode',0)
				case 'done'
					status
				otherwise
					warning('Unknown flag! (%s)',flag)
			end
			return
		end
		if now-SStStart>SStMAX
			DT=(now-SStStart)*86400;
			warning('Too long simulation! (%d calls in %gs - %g#/s)',SSnCall	...
				,DT,SSnCall/DT)
			bStop=true;
		end
		t_e=t(end);
		while SSiLast<length(SS_T)&&SS_T(SSiLast+1)<=t_e
			SSiLast=SSiLast+1;
		end
		t_1=SS_T(SSiLast);
		if t_e<=t_1||SSiLast>=length(SS_T)
			Ucurrent=SS_U(SSiLast,:)';
		else
			t_2=SS_T(SSiLast+1);
			Ucurrent=(SS_U(SSiLast,:)+(t_e-t_1)/(t_2-t_1)*(SS_U(SSiLast+1,:)-SS_U(SSiLast,:)))';
		end
		SSnOut=SSnOut+1;
		if SS_Ttot>0
			status(t_e/SS_Ttot)
		end
	end		% SSout

end		% SimulateSSmodel
