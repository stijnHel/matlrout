function XYZout=PlotStruct(X,Ttrans,varargin)
%PlotStruct - Plot data read from Structure-OBJ-file
%      PlotStruct(X)
%
% see also ReadStructOBJ, ReadPLY

[bConnect] = false;
[bLimitLines] = false;	% to limit number of lines - but is not really useful
[bMarker] = true;
[nPartMax] = 10000;
bPlot = nargout==0;

options = varargin;

if nargin<2
	Ttrans = [];
end
if ischar(Ttrans)
	options = [{Ttrans},options];
	Ttrans = [];
end
if ~isempty(options)
	setoptions({'Ttrans','bMarker','bConnect','bLimitLines','nPartMax','bPlot'},options{:})
end

if isfield(X,'Av')
	Xpt = X.Av;
	Lidx = X.Af;
elseif isfield(X,'Dspec')&&isfield(X,'D')
	Xpt = X.D{1}(:,1:3);	%(supposing first points then connections!)
	Lidx = X.D{2}+1;
else
	error('Unknown format')
end
if ~isempty(Ttrans)
	if length(Ttrans)==3
		Xpt = Xpt*Ttrans';
	else
		Xpt = [Xpt,ones(size(Xpt,1),1)]*Ttrans(1:3,:)';
	end
end

if bPlot
	if bMarker
		scatter3(Xpt(:,1),Xpt(:,2),Xpt(:,3))
	else
		plot3(Xpt(1),Xpt(1,2),Xpt(1,3));grid
	end
end

if bConnect
	if bLimitLines
		%!!!!!!!!!!!!! in ontwikkeling
		XYZ = cell(4,10000);
		B = sparse(size(Xpt,1),size(Xpt,1),true);
		[XYZ{1:3,1},B] = ConnectSegments(Xpt,Lidx,B);
		nL = 1;
		while ~isempty(XYZ{1,nL})&&nL<nPartMax
			nL = nL+1;
			[XYZ{1:3,nL},B] = ConnectSegments(Xpt,Lidx,B);
		end

		nL = nL-1;
		XYZ = XYZ(:,1:nL);
		XYZ(4,:) = {NaN};
		if bPlot
			X = cat(1,XYZ{[1,4],:});
			Y = cat(1,XYZ{[2,4],:});
			Z = cat(1,XYZ{ 3:4 ,:});
		end
	else
		XYZ = zeros(5,size(Lidx,1),3);	% [4 pts+NaN, points, {x,y,z}]
		XYZ(5,:,:) = NaN;
		XYZ(1,:,:) = Xpt(Lidx(:,1),:);
		XYZ(2,:,:) = Xpt(Lidx(:,2),:);
		XYZ(3,:,:) = Xpt(Lidx(:,3),:);
		XYZ(4,:,:) = Xpt(Lidx(:,1),:);
		if bPlot
			X = XYZ(:,:,1);
			Y = XYZ(:,:,2);
			Z = XYZ(:,:,3);
		end
	end
	if bPlot
		line(X(:),Y(:),Z(:))
	end
	if nargout
		XYZout = XYZ;
	end
end
if bPlot
	axis equal
end

function [X,Y,Z,B] = ConnectSegments(Xpt,Lidx,B)
nTr = size(Lidx,1);
Ipt = zeros(1,10000);	%!!!??? size
b = true;
i_t = 0;
while b && i_t<nTr
	i_t = i_t+1;
	if SegmentAvailable(B,Lidx(i_t,1),Lidx(i_t,2))
		b = false;
		i_p = 1;
	elseif SegmentAvailable(B,Lidx(i_t,2),Lidx(i_t,3))
		b = false;
		i_p = 2;
	elseif SegmentAvailable(B,Lidx(i_t,3),Lidx(i_t,1))
		b = false;
		i_p = 3;
	end
end
if b
	X = [];
	Y = [];
	Z = [];
	return
end
Ipt(1) = Lidx(i_t,i_p);
ni = 1;
while true
	i_pn = rem(i_p,3)+1;
	ni = ni+1;
	Ipt(ni) = Lidx(i_t,i_pn);
	B = AvoidSegments(B,Lidx(i_t,i_p),Lidx(i_t,i_pn));
	i_pnn = rem(i_pn,3)+1;
	if SegmentAvailable(B,Lidx(i_t,i_pn),Lidx(i_t,i_pnn))	% next segment of same triangle if available
		i_p = i_pn;
	else
		% look for other segment using current point
		iPt = Lidx(i_t,i_pn);
		i_t = 0;
		b = true;
		while b && i_t<nTr
			i_t = i_t+1;
			if Lidx(i_t,1)==iPt && SegmentAvailable(B,Lidx(i_t,1),Lidx(i_t,2))
				b = false;
				i_p = 1;
			elseif Lidx(i_t,2)==iPt && SegmentAvailable(B,Lidx(i_t,2),Lidx(i_t,3))
				b = false;
				i_p = 2;
			elseif Lidx(i_t,3)==iPt && SegmentAvailable(B,Lidx(i_t,3),Lidx(i_t,1))
				b = false;
				i_p = 3;
			end
		end
		if b
			break
		end
	end
end
Ipt = Ipt(1:ni);
X = Xpt(Ipt,1);
Y = Xpt(Ipt,2);
Z = Xpt(Ipt,3);

function B = AvoidSegments(B,p1,p2)
if p1>p2
	B(p2,p1) = true;
else
	B(p1,p2) = true;
end

function b = SegmentAvailable(B,p1,p2)
if p1>p2
	b = ~B(p2,p1);
else
	b = ~B(p1,p2);
end
