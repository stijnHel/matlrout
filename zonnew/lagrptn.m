function [L,DA,ri,D]=lagrptn(alpha)
%lagrptn - Find lagrange points (1-3) by finding zeros in force field(?)
%    [L,DA,ri,Lpts123]=lagrptn(alpha)
%          alpha: relative mass of planet (?)
%  Only L1, L2, L3 regarded - the points on the line between two main
%  masses (like sun & earth / earth & moon)
%       L1: between two masses
%       L2: behind the lowest mass object (seen from the high mass object)
%       L3: other side of the high mass object
%         D: other calculations (sun-earth system)

if ~exist('alpha','var') || isempty(alpha)
	alpha=1/81;	% relative mass of moon
		% relative mass moon: 1/81 (earth)
		% relative mass jupiter: 1/1047 (sun)
		% relative mass earth: 1/332876 (sun)
end

d1=alpha/(1+alpha);	% centre of gravity
d2=1-d1;	% position of planet (compared to centre of gravity)

ri=-2:0.001:2;	% points on radius

da1=1./(d1+ri).^2-alpha./(d2-ri).^2-ri/d1/(d1+d2)^2;
L1=FindZeros(da1,ri);

da2=1./(d1+ri).^2+alpha./(d2-ri).^2-ri/d1/(d1+d2)^2;
L2=FindZeros(da2,ri);

da3=1./(ri-d1).^2+alpha./(ri+d2).^2-ri/d1/(d1+d2)^2;
L3=FindZeros(da3,ri);

DA=[da1;da2;da3];
L={L1,L2,L3};

% energy calculations
GMs = 1.32712440018e20;
GMe = 3.986004418e14;
GMj = 126.687e15;	% (https://nssdc.gsfc.nasa.gov/planetary/factsheet/jupiterfact.html)
Mj = 1.8982e27;
Pj = 4332.59;	% days
Rj = 778.479e9;
AU = 1.495978707e11;
w = 0.5/pi/365.256/86400;
X = repmat(ri*AU,length(ri),1);
Y = X';
Rs = sqrt(X.^2+Y.^2);
Re = sqrt((X-AU).^2+Y.^2);
E = Rs*w.^2 - GMs./Rs - GMe./Re;
%------------ not done....

Lpts123 = IterCalcLgrptn();

D = var2struct(X,Y,E,Lpts123);

function [L,Li,Ld]=FindZeros(da,ri)
ii=find(da(1:end-1)<0&da(2:end)>=0);
limA=1e5;
if isempty(ii)
	Li=[];
else
	ii(abs(da(ii))>limA|abs(da(ii+1))>limA)=[];
	Li=ii;
	for i=1:length(ii)
		k=ii(i)-3:ii(i)+3;
		Li(i)=interp1(da(k),ri(k),0,'spline');
	end
end
id=find(da(1:end-1)>0&da(2:end)<=0);
if isempty(id)
	Ld=[];
else
	id(abs(da(id))>limA|abs(da(id+1))>limA)=[];
	Ld=id;
	for i=1:length(id)
		k=id(i)-3:id(i)+3;
		Ld(i)=interp1(da(k),ri(k),0,'spline');
	end
end
L=[Li Ld];

function Lpts123 = IterCalcLgrptn()
%Iterative calculation based on:
%   https://www.spaceacademy.net.au/library/notes/lagrangp.htm#:~:text=The%20force%20equations%20for%20the%20three%20Lagrange%20points,L2%3A%20Fs%3D%20Fe%2B%20Fc%20L3%3A%20Fs%2B%20Fe%3D%20Fc

GMs = 1.32712440018e20;
GMe = 3.986004418e14;
AU = 1.495978707e11;

% bary centre calculation
R = AU;
Re = R/(1+GMe/GMs);
Rs = R-Re;

if 0
xL1 = 1;
xL2 = 1;
xL3 = 1;

X = zeros(101,3);
X(1,:) = [xL1,xL2,xL3];
for i=2:size(X,2)
	xL1 = sqrt((GMe/GMs)*Re/R^2*(R + xL1)^2 / ((Re + xL1)*(R + xL1)^2 - Re*R^2));
	xL2 = sqrt((GMe/GMs)*Re/R^2*(R - xL2)^2 / ((Re*R^2 - (Re-xL2)*R-xL2)^2));
	xL3 = sqrt((GMe/GMs)*Re/R^2*(R + xL3)^2 / ((Rs + xL3)*(R + xL3)^2 - Rs*R^2));
	X(i,:) = [xL1,xL2,xL3];
end
else
	fx = @(x) GMs./(R+x).^2+GMe./x.^2-GMs*(Re+x)/(Re*R^2);	% (L1, but normally called L2)
	xL1 = solve(fx,1e8,1e8);
	fx = @(x) GMs./(R-x).^2-(GMe./x.^2+GMs*(Re-x)/(Re*R^2));	% L2, but normally calld L1)
	xL2 = solve(fx,1e8,1e8);
	fx = @(x) GMs./x.^2+GMe./(R+x).^2-GMe*(Rs+x)/(Rs*R^2);	% L3
	xL3 = solve(fx,1e8,1e8);
end

Lpts123 = [xL1,xL2,xL3];

function x = solve(f,x0,dx)
x = x0;
while dx>100
	s0 = f(x);
	x = x+dx;
	while f(x)*s0>0
		x = x+dx;
	end
	x = x-dx;
	dx = dx/10;
end
