function [Xmin,Ymin,Xmax,Ymax]=FindOuterArea(Xpts,Ypts	...
	,XstartMin,YstartMin,XstartMax,YstartMax)
%FindOuterArea - Find outer convex area of set of lines
%     [Xmin,Ymin,Xmax,Ymax]=FindOuterArea(Xpts,Ypts);
%     [Xmin,Ymin,Xmax,Ymax]=FindOuterArea(Xpts,Ypts	...
%			,XstartMin,YstartMin,XstartMax,YstartMax);
%   output can also be:
%     [XYmin,XYmax]=....
%     [XYcontour]=...      creates a contour
%
%  This function finds the minimum/maximum points as Y(X), with a lower and
%     upper boundary (separately determined).
%  So, after calling the function, the points [Xpts,Ypts] will all be above
%     or on the line [Xmin,Ymin] and all below [Xmax,Ymax]

if nargin<3
	XstartMin=[min(Xpts),max(Xpts)];
	YstartMin=[min(Ypts(Xpts==XstartMin(1))),min(Ypts(Xpts==XstartMin(2)))];
	XstartMax=XstartMin;
	YstartMax=[max(Ypts(Xpts==XstartMin(1))),max(Ypts(Xpts==XstartMin(2)))];
end
Xmin=XstartMin;
Ymin=YstartMin;
Xmax=XstartMax;
Ymax=YstartMax;

% split parts between NaNa
Bnan=isnan(Xpts);
ii=find(Bnan);
ii(end+1)=length(Xpts)+1;

% find minimum/maximum profile
i1=0;
for i=1:length(ii)
	i2=ii(i);
	if i2-i1>1
		X1=Xpts(i1+1:i2-1);
		Y1=Ypts(i1+1:i2-1);
		Ymin1=interp1(Xmin,Ymin,X1);
		Ymax1=interp1(Xmax,Ymax,X1);
		n=length(X1);
		for j=1:length(X1)
			if Y1(j)<Ymin1(j)
				[Xmin,Ymin]=AddPoint(Xmin,Ymin,X1(j),Y1(j));
				Ymin1(j+1:n)=interp1(Xmin,Ymin,X1(j+1:n));
			elseif Y1(j)>Ymax1(j)
				[Xmax,Ymax]=AddPoint(Xmax,Ymax,X1(j),Y1(j));
				Ymax1(j+1:n)=interp1(Xmax,Ymax,X1(j+1:n));
			end
		end
	end
	i1=i2;
end

% Make convex (replacing "online" point removal)
[Xmax,Ymax]=MakeConvex(Xmax,Ymax,true);
[Xmin,Ymin]=MakeConvex(Xmin,Ymin,false);

if nargout>0&&nargout<3
	% make sure that vectors are column vectors
	Xmin=Xmin(:);
	Xmax=Xmax(:);
	Ymin=Ymin(:);
	Ymax=Ymax(:);
	if nargout==1
		Xmin=[Xmin,Ymin;
			Xmax(end:-1:1),Ymax(end:-1:1);
			];
		if Ymin(1)<Ymax(1)
			Xmin(end+1,:)=[Xmin(1),Ymin(1)];
		end
	else
		Xmin=[Xmin,Ymin];
		Ymin=[Xmax,Ymax];
	end
end

function [Xext,Yext]=AddPoint(Xext,Yext,X1,Y1)
i=find(Xext>=X1,1);
if isempty(i)
	error('This shouldn''t be possible!')
end
if X1==Xext(i)
	Yext(i)=Y1;
else
	Xext=[Xext(1:i-1) X1 Xext(i:end)];
	Yext=[Yext(1:i-1) Y1 Yext(i:end)];
	if any(diff(Xext)<0)
		warning('Iets loopt fout!!!!')
	end
end

function [Xext,Yext]=MakeConvex(Xext,Yext,bMax)
if bMax
	difSign=1;
else
	difSign=-1;
end
g=(Yext(2)-Yext(1))/(Xext(2)-Xext(1));
i=2;
while i<length(Xext)
	g1=(Yext(i+1)-Yext(i))/(Xext(i+1)-Xext(i));
	while (g1-g)*difSign>0
		Xext(i)=[];
		Yext(i)=[];
		if i==2
			break
		end
		i=i-1;
		g =(Yext(i  )-Yext(i-1))/(Xext(i  )-Xext(i-1));
		g1=(Yext(i+1)-Yext(i  ))/(Xext(i+1)-Xext(i  ));
	end
	i=i+1;
	g=g1;
end
% successive constant points (more than 2) may be removed
%    worth checking?
