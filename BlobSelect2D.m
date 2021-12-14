function [Bsel,B,r0,c0]=BlobSelect2D(B,r0,c0,bDiag,varargin)
%BlobSelect2D - Find a blob or all blobs in a 2D image
%        Bsel=BlobSelect2D(B,r0,c0,bDiag)
%            B: 2D boolean array
%            r0,c0: coordinates to start
%            bDiag: also include diagonal neighbours (default false)
%            
%            Bsel: boolean array with selection
%
%        BLOBs=BlobSelect2D(X,col,'all')	% find blobs (number and starting point)
%            X: 2D array (boolean or other) or 3D array (m x n x 3 for fullcolor)
%            col: colour to choose (can be vector for fullcolor)
%
%            Bsel: struct-vector with blob-data
%                 position, min/max position and height/width

% better work with sentinel-bounday?

% (!)two almost similar parts, one for 'all' and one for one blob find!

if nargin<4||isempty(bDiag)
	bDiag=false;
end

if nargin>=3&&ischar(c0)
	if ~strcmpi(c0,'all')
		error('Only "all" expected in this case!')
	end
	% Find all blobs
	
	BB=struct('n',cell(1,min(ceil(numel(B)/10),100000)),'r',[],'c',[]	...
		,'Rmax',[],'Rmin',[],'Cmax',[],'Cmin',[],'h',[],'w',[]);
	if islogical(B)
		if ~r0
			B=~B;
		end
	else
		X=B;
		col=r0;
		B=X(:,:,1)==col(1);
		for i=2:length(r0)
			B=B&X(:,:,i)==r0(i);
		end
	end
	[nr,nc]=size(B);
	iB=0;
	nEl=numel(B);
	nB=0;
	R=zeros(1,max(nc,nr)*min(min(nr,nc),10));
	C=R;
	while true
		iB=iB+1;
		while iB<=nEl&&~B(iB)
			iB=iB+1;
		end
		if iB>nEl
			break
		end
		r0=rem(iB-1,nr)+1;
		c0=floor((iB-1)/nr)+1;
		nS=1;
		R(1)=r0;
		C(1)=c0;

		n=0;
		SR=0;
		SC=0;
		Rmax=r0;
		Rmin=r0;
		Cmax=c0;
		Cmin=c0;

		while nS
			r=R(nS);
			c=C(nS);
			nS=nS-1;
			if B(r,c)
				n=n+1;
				B(r,c)=false;
				SR=SR+r;
				SC=SC+c;
				Rmax=max(Rmax,r);
				Rmin=min(Rmin,r);
				Cmax=max(Cmax,c);
				Cmin=min(Cmin,c);
				AddStack2(r-1,c)
				AddStack2(r,c-1)
				AddStack2(r+1,c)
				AddStack2(r,c+1)
				if bDiag
					AddStack2(r+1,c+1)
					AddStack2(r+1,c-1)
					AddStack2(r-1,c+1)
					AddStack2(r-1,c-1)
				end
			end		% if B(r,c)
		end		% while nS
		nB=nB+1;
		BB(nB).n=n;
		BB(nB).r=SR/n;
		BB(nB).c=SC/n;
		BB(nB).Rmax=Rmax;
		BB(nB).Rmin=Rmin;
		BB(nB).Cmax=Cmax;
		BB(nB).Cmin=Cmin;
		BB(nB).h=Rmax-Rmin+1;
		BB(nB).w=Cmax-Cmin+1;
	end		% while true (find next blob iteration)
	Bsel=BB(1:nB);
	return
end

bFindColour=false;
if nargin<3
	if nargin<2
		r0=[];
	end
	if length(r0)==size(B,3)	% colour definition
		bFindColour=true;
	else
		c0=[];	% default (will be set to 1)
	end
elseif isempty(c0)&&length(r0)==size(B,3)
	bFindColour=true;
end
if bFindColour
	if islogical(B)
		if ~r0
			B=~B;
		end
	else
		X=B;
		col=r0;
		B=X(:,:,1)==col(1);
		for i=2:length(r0)
			B=B&X(:,:,i)==r0(i);
		end
	end
	[r0,c0]=find(B,1);
	if isempty(r0)
		Bsel=B;
		return
	end
else
	if isempty(c0)
		c0=1;
	end
	if isempty(r0)
		r0=1;
	end
end

if ~ismatrix(B)
	if ndims(B)>3
		error('maximum three dimensions are allowed!')
	end
	X=B;
	B=X(:,:,1)==X(r0,c0);
	for i=2:size(X,3)
		B=B&(X(:,:,i)==X(r0,c0,i));
	end
elseif ~islogical(B)
	B=B(:,:,1)==B(r0,c0);	%(!!)
end

[nr,nc]=size(B);
R=zeros(1,max(nc,nr)*min(min(nr,nc),10));
C=R;
nS=1;
R(1)=r0;
C(1)=c0;

Bsel=false(size(B));

while nS
	r=R(nS);
	c=C(nS);
	nS=nS-1;
	if ~Bsel(r,c)
		Bsel(r,c)=true;
		AddStack(r-1,c)
		AddStack(r,c-1)
		AddStack(r+1,c)
		AddStack(r,c+1)
		if bDiag
			AddStack(r+1,c+1)
			AddStack(r+1,c-1)
			AddStack(r-1,c+1)
			AddStack(r-1,c-1)
		end
	end
end

	function AddStack(r,c)
		if r>0&&r<=nr&&c>0&&c<=nc&&B(r,c)&&~Bsel(r,c)
			nS=nS+1;
			R(nS)=r;
			C(nS)=c;
		end
	end		% AddStack

	function AddStack2(r,c)
		if r>0&&r<=nr&&c>0&&c<=nc&&B(r,c)
			nS=nS+1;
			R(nS)=r;
			C(nS)=c;
		end
	end		% AddStack

end		% BlobSelect2D
