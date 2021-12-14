function [Bsel,B,r0,c0]=BlobSelect3D(B,r0,c0,h0,bDiag,varargin)
%BlobSelect3D - Find a blob or all blobs in a 3D "image"
%        Bsel=BlobSelect3D(B,r0,c0,h0,bDiag)
%            B: 3D boolean array
%            r0,c0,h0: coordinates to start
%            bDiag: also include diagonal neighbours (default false)
%            
%            Bsel: boolean array with selection
%
%        BLOBs=BlobSelect3D(X,col,'all')	% find blobs (number and starting point)
%            X: 3D array
%            col: colour to choose
%
%            Bsel: struct-vector with blob-data
%                 position, min/max position and height/width

% better work with sentinel-bounday?

%!!!!!!!!!!!!!!!!!
% - Extended from BlobSelect2D, but only for non-diag-option (default)!!
% - Really necessary to have a different method (almost the same) for "all"
%   and a single blob search?
%!!!!!!!!!!!!!!!!!

if nargin<5||isempty(bDiag)
	bDiag=false;
end
if bDiag
	warning('diag not yet done for 3D-images')
	bDiag=false;
end

if nargin>=3&&ischar(c0)
	if ~strcmpi(c0,'all')
		error('Only "all" expected in this case!')
	end
	% Find all blobs
	
	BB=struct('n',cell(1,min([sum(B(:)),ceil(numel(B)/80),100000])),'r',[],'c',[],'h',[]	...
		,'Rmax',[],'Rmin',[],'Cmax',[],'Cmin',[],'Hmax',[],'Hmin',[]	...
		,'dR',[],'dC',[],'dH',[]);
	if ~r0
		B=~B;
	end
	[nr,nc,nh]=size(B);
	iB=0;
	nEl=numel(B);
	nB=0;
	R=zeros(1,max([nc,nr,nh])*min(min([nr,nc,nh]),10));
	C=R;
	H=R;
	while true
		iB=iB+1;
		b=B(nEl);
		B(nEl)=true;	% make sure it stops at the end (in place of testing iB<=nEl)
		while ~B(iB)
			iB=iB+1;
		end
		B(nEl)=b;
		if iB>=nEl	% discard very last point
			break
		end
		[r0,c0,h0]=ind2sub([nr,nc,nh],iB);
		nS=1;
		R(1)=r0;
		C(1)=c0;
		H(1)=h0;

		n=0;
		SR=0;
		SC=0;
		SH=0;
		Rmax=r0;
		Rmin=r0;
		Cmax=c0;
		Cmin=c0;
		Hmax=h0;
		Hmin=h0;

		while nS
			r=R(nS);
			c=C(nS);
			h=H(nS);
			nS=nS-1;
			if B(r,c,h)
				n=n+1;
				B(r,c,h)=false;
				SR=SR+r;
				SC=SC+c;
				SH=SH+h;
				Rmax=max(Rmax,r);
				Rmin=min(Rmin,r);
				Cmax=max(Cmax,c);
				Cmin=min(Cmin,c);
				Hmax=max(Hmax,h);
				Hmin=min(Hmin,h);
				AddStack2(r-1,c  ,h)
				AddStack2(r  ,c-1,h)
				AddStack2(r+1,c  ,h)
				AddStack2(r  ,c+1,h)
				AddStack2(r  ,c  ,h-1)
				AddStack2(r  ,c  ,h+1)
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
		BB(nB).h=SH/n;
		BB(nB).Rmax=Rmax;
		BB(nB).Rmin=Rmin;
		BB(nB).Cmax=Cmax;
		BB(nB).Cmin=Cmin;
		BB(nB).Hmax=Hmax;
		BB(nB).Hmin=Hmin;
		BB(nB).dR=Rmax-Rmin+1;
		BB(nB).dC=Cmax-Cmin+1;
		BB(nB).dH=Hmax-Hmin+1;
	end		% while true (find next blob iteration)
	Bsel=BB(1:nB);
	return
end

if isempty(c0)
	c0=1;
end
if isempty(r0)
	r0=1;
end
if isempty(h0)
	h0=1;
end

[nr,nc,nh]=size(B);
R=zeros(1,max(nc,nr,nh)*min(min(nr,nc,nh),10));
C=R;
H=R;
nS=1;
R(1)=r0;
C(1)=c0;
H(1)=h0;

Bsel=false(size(B));

while nS
	r=R(nS);
	c=C(nS);
	h=H(nS);
	nS=nS-1;
	if ~Bsel(r,c,h)
		Bsel(r,c,h)=true;
		AddStack(r-1,c  ,h)
		AddStack(r  ,c-1,h)
		AddStack(r+1,c  ,h)
		AddStack(r  ,c+1,h)
		AddStack(r  ,c  ,h-1)
		AddStack(r  ,c  ,h+1)
		if bDiag
			AddStack(r+1,c+1)
			AddStack(r+1,c-1)
			AddStack(r-1,c+1)
			AddStack(r-1,c-1)
		end
	end
end

	function AddStack(r,c,h)
		if r>0&&r<=nr&&c>0&&c<=nc&&h>0&&h<=nh&&B(r,c,h)&&~Bsel(r,c,h)
			nS=nS+1;
			R(nS)=r;
			C(nS)=c;
			H(nS)=h;
		end
	end		% AddStack

	function AddStack2(r,c,h)
		if r>0&&r<=nr&&c>0&&c<=nc&&h>0&&h<=nh&&B(r,c,h)
			nS=nS+1;
			R(nS)=r;
			C(nS)=c;
			H(nS)=h;
		end
	end		% AddStack2

end		% BlobSelect3D
