function Pshadow=CalcShadows(C,T,varargin)
%CalcShadows - Calculate shadows from points to surface(s)
%   Pshadow=CalcShadows(C,T)
%
%   C: configuration
%       surf: corners of surface (nx3 array)
%          pts must go counter clockwise ("sun's view")
%       Pts: points (in 3D coordinates) from which shadows should be calculated
%   T: time (julian days)
%
% axis orientation:
%       X: west
%       Y: south
%       Z: up (zenith)

bPlot=nargout==0;
if ~isempty(varargin)
	setoptions({'bPlot'},varargin{:})
end

Vs1=C.surf(2,:)-C.surf(1,:);
Vs2=C.surf(3,:)-C.surf(1,:);

Vs1=Vs1/norm(Vs1);
Vs2=Vs2/norm(Vs2);
Snormal = cross(Vs1,Vs2);
Snormal=Snormal/norm(Snormal);
Soffset=C.surf*Snormal(:);
if max(Soffset)-min(Soffset)>1e-5
	error('Sorry, but currently this only works for flat surfaces!!!!')
end
Soffset=mean(Soffset);

Pshadow = nan([size(C.Pts),length(T)]);

Psun = calcposhemel([],T);
Xsun = [cos(Psun(:,2)).*[sin(Psun(:,1)),cos(Psun(:,1))],sin(Psun(:,2))];
Ssun = Xsun*Snormal(:);
for i=1:length(T)
	if Psun(i,2)>0&&Ssun(i)>0	% sun above horizon and sun above surface
		% calculate crossing between line and surface
		p = (Soffset-C.Pts*Snormal')/(Xsun(i,:)*Snormal');
		Q = C.Pts+p*Xsun(i,:);
		Pshadow(:,:,i) = Q;
	end
end

if bPlot
	Plot(C,Pshadow,T)
end
if nargout==0
	clear Pshadow
end

function Plot(CONF,Pshadow,T)
f=getmakefig('SHADOWplot');

plot(Pshadow(:,1,1),Pshadow(:,2,1));grid
hold on
for i=2:size(Pshadow,3)
	plot(Pshadow(:,1,i),Pshadow(:,2,i))
end
hold off

l=line(0,0);
set(l,'linewidth',4)

setappdata(f,'CONF',CONF)
setappdata(f,'line',l)
set(f,'KeyPressFcn',@KeyPressed)

Update(l,T(1))

function Update(h,t)
f=ancestor(h,'figure');
CONF=getappdata(f,'CONF');
l=getappdata(f,'line');
S=CalcShadows(CONF,t);
set(l,'xdata',S(:,1),'ydata',S(:,2))
set(get(ancestor(l,'axes'),'title'),'String',calccaldate(t,[],true))
setappdata(f,'t',t);

function KeyPressed(f,ev)
t=getappdata(f,'t');
b=false;
switch ev.Key
	case 'leftarrow'
		b=true;
		t=t-1/24;
	case 'rightarrow'
		b=true;
		t=t+1/24;
	case 'downarrow'
		b=true;
		t=t-1;
	case 'uparrow'
		b=true;
		t=t+1;
	case 'pageup'
		b=true;
		t=t+7;
	case 'pagedown'
		b=true;
		t=t-7;
end
if b
	Update(f,t)
end
