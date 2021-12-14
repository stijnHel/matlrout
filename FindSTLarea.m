function [D,Bv]=FindSTLarea(STL,Bv,varargin)
%FindSTLarea - Extract a (simplified) area of a selection of STL-vertices
%     D=FindSTLarea(STL,Bv)
%        STL: STL-data (see ReadSTL)
%        Bv: boolean array of points to be selected
%           expression like: 'Z=...', 'R>...'
%               or {'<var>','<operator>',<value>}
%               variables: X,Y,Z,R,Rx,Ry,Rz
%           a cell-vector gives multiple conditions (AND)
%           'edges' --> find edges between triangles with a large angle
%              currently operates on the full shape (and must be used alone)
%              the idea is to extend this
%           adaptations:
%                  'pt0=...' (for calculating R)
%                  'tol=...' (for <var>=... translates to abs(<var>-...)<tol)
%                  'edgeAngle=...' for edges
%   example:
%      STL=ReadSTL(<STL-file>);
%      Bv=squeeze(abs(STL.vertex(3,:,:))<1e-5);
%           % squeeze is also done for you...
%      D=FindSTLarea(STL,Bv);
%
%   Currently this only works well with flat areas!  Different ideas exist.
%
%  see also READSTL

[bCreatePolygons]=true;	% was(/is?) an idea, but not worked out
[bFindLines]=[];	% not area but line
[bAllowJunctions]=true;
[bSeparateSections]=false;	% separate sections in case of junctions

if ~isempty(varargin)
	setoptions({'bCreatePolygons','bFindLines','bAllowJunctions','bSeparateSections'}	...
		,varargin{:})
end

if ischar(Bv)||(iscell(Bv)&&ischar(Bv{1})&&length(Bv)==3&&isnumeric(Bv{3}))
	Bv={Bv};
end
Ipt=[];
if iscell(Bv)
	C=Bv;
	R=[];
	Rx=[];
	Ry=[];
	Rz=[];
	Bv=[];
	tol=1e-5;
	edgeAngle=3;	% degrees(!)
	pt0=[];
	if size(C,1)>1&&size(C,2)==3
		nC=size(C,1);
		bCarray=true;
	else
		nC=length(C);
		bCarray=false;
	end
	for i=1:nC
		if bCarray
			c=C(i,:);
		else
			c=C{i};
		end
		if iscell(c)
			[var,c,val]=deal(c{:});
		elseif ischar(c)
			[F,N,O,Otype]=InterpreteFormula(c);
			if ~isscalar(N)
				error('Only simple expressions with one variable are expected!')
			end
			var=N{1};
			if size(Otype,2)>2
				c=Otype{2,3};
				if size(F,2)>3
					[~,bOK,~,v]=InterpreteFormula(F,N,O);
					if size(v,1)~=5
						error('Can''t interpret the formula!')
					end
					val=v{2};
				else
					val=F(5,3);
				end
			else
				c=0;
				val=[];
			end
		else
			error('Wrong condition (%d)',i)
		end
		V=[];
		Bv_1=[];
		switch var
			case 'X'
				V=squeeze(STL.vertex(1,:,:));
			case 'Y'
				V=squeeze(STL.vertex(2,:,:));
			case 'Z'
				V=squeeze(STL.vertex(3,:,:));
			case {'R','Rx','Ry','Rz'}
				if length(var)==1
					R=[];	% calculate every time
				else
					switch var(2)
						case 'x'
							R=Rx;
						case 'y'
							R=Ry;
						case 'z'
							R=Rz;
					end
				end
				if isempty(R)
					V=STL.vertex;
					if ~isempty(pt0)
						V=bsxfun(@minus,V,pt0(:));
					end
					if length(var)==1
						jj=1:3;
					elseif length(var)~=2
						error('Unknown R-type!')
					elseif var(2)=='x'
						jj=[2 3];
					elseif var(2)=='y'
						jj=[1 3];
					elseif var(2)=='z'
						jj=[1 2];
					else
						error('Unknown R-type')
					end
					R=sqrt(squeeze(sum(V(jj,:,:).^2)));
					if length(var)>1
						assignval(var,R)
					end
				end
				V=R;
			case 'tol'
				tol=val;
			case 'pt0'
				pt0=val;
				R=[];
				Rx=[];
				Ry=[];
				Rz=[];
			case 'edgeAngle'
				edgeAngle=val;
			case 'edges'
				[Bv_1,Ipt]=FindEdges(STL,edgeAngle);	%!!independent from Bv
				if isempty(bFindLines)
					bFindLines=true;
				end
			otherwise
				error('Unknown variable (%s)',var)
		end
		if ~isempty(V)
			switch c
				case {'=','=='}
					if tol==0
						fcnTest=@eq;
					else
						V=abs(V-val);
						fcnTest=@lt;
						val=tol;
					end
				case '<'
					fcnTest=@lt;
				case '>'
					fcnTest=@gt;
				case '<='
					fcnTest=@le;
				case '>='
					fcnTest=@ge;
				otherwise
					error('Sorry, this condition is not implemented')
			end
			Bv_1=fcnTest(V,val);
		end		% ~empty(V)
		if ~isempty(Bv_1)
			if isempty(Bv)
				Bv=Bv_1;
			else
				Bv=Bv & Bv_1;
			end
		end
	end		% for i
elseif ~ismatrix(Bv)
	Bv=squeeze(Bv);
	if ~ismatrix(Bv)
		error('Dimension of Bv (or its squeezed form) should be 3xn)!')
	end
end
if min(size(Bv))==1	% related to triangles
	Bv=repmat(Bv(:)',3,1);
end
if size(Bv,1)~=3||size(Bv,2)~=size(STL.vertex,3)
	warning('The size of Bv doesn''t seem to be correct.  I try to work with it.')
end

if isempty(bFindLines)
	bFindLines=~any(all(Bv));
	if bFindLines
		if any(sum(Bv)==2)
			warning('No areas and no lines found!')
		else
			warning('No areas found, but lines found')
		end
	end
elseif ~bFindLines
	if ~any(all(Bv))
		if any(sum(Bv)==2)
			warning('No areas found - switched to finding lines!')
			bFindLines=false;
		end
	end
elseif any(all(Bv))&&isempty(Ipt)
	error('Finding lines when there are areas is not implemented')
end

Zsegments=[];
Ivs=[];
if ~isempty(Ipt)
	% do nothing here
	nIpt=size(Ipt,1);
elseif bFindLines
	% take all segments
	ii=find(sum(Bv)==2);
	nIpt=length(ii);
	Ipt=zeros(nIpt,2);
	for i=1:nIpt
		Ipt(i,:)=STL.Ipt(Bv(:,ii(i)),ii(i));
	end
	
	% keep only unique segments
	Ipt=sort(Ipt,2);
	maxI=max(Ipt(:));
	[~,iU]=unique(Ipt*[maxI+1;1]);
	Ipt=Ipt(iU,:);
	nIpt=length(iU);
else
	Bv=all(Bv);
	Iv=STL.Ipt(:,Bv);
	nTriangle=size(Iv,2);

	%% find edges used by one triangle
	Ivs=sort(Iv);
	Be=true(3,nTriangle);	% unique edges
		% 1: 1-2, 2: 1-3, 3: 2:3

	for i=1:nTriangle-1
		iFurther=i+1:nTriangle;
		% common point 1 (knowing that Ivs is sorted)
		B1=Ivs(1,iFurther)==Ivs(1,i);
		if any(B1)
			ii=i+find(B1);
			B12=Ivs(2,ii)==Ivs(2,i);
			if any(B12)
				Be(1,i)=false;
				Be(1,ii(B12))=false;
			end
			B13=Ivs(3,ii)==Ivs(2,i);
			if any(B13)
				Be(1,i)=false;
				Be(2,ii(B13))=false;
			end
			B12=Ivs(2,ii)==Ivs(3,i);
			if any(B12)
				Be(2,i)=false;
				Be(1,ii(B12))=false;
			end
			B13=Ivs(3,ii)==Ivs(3,i);
			if any(B13)
				Be(2,i)=false;
				Be(2,ii(B13))=false;
			end
		end		% if any(B1)
		% common point 2 (knowing that Ivs is sorted)
		B1=Ivs(2,iFurther)==Ivs(1,i);
		if any(B1)
			ii=i+find(B1);
			B12=Ivs(3,ii)==Ivs(2,i);
			if any(B12)
				Be(1,i)=false;
				Be(3,ii(B12))=false;
			end
			B13=Ivs(3,ii)==Ivs(3,i);
			if any(B13)
				Be(2,i)=false;
				Be(3,ii(B13))=false;
			end
		end		% if any(B1)
		B1=Ivs(1,iFurther)==Ivs(2,i);
		if any(B1)
			ii=i+find(B1);
			B12=Ivs(2,ii)==Ivs(3,i);
			if any(B12)
				Be(3,i)=false;
				Be(1,ii(B12))=false;
			end
			B13=Ivs(3,ii)==Ivs(3,i);
			if any(B13)
				Be(3,i)=false;
				Be(2,ii(B13))=false;
			end
		end		% if any(B1)
		B1=Ivs(2,iFurther)==Ivs(2,i);
		if any(B1)
			ii=i+find(B1);
			B12=Ivs(3,ii)==Ivs(3,i);
			if any(B12)
				Be(3,i)=false;
				Be(3,ii(B12))=false;
			end
		end		% if any(B1)
	end

	%% Make list of points
	Ipt=zeros(sum(Be(:)),2);
	Zsegments=nan(3,3,sum(Be(:)));
	nIpt=0;
	for i=1:numel(Ivs)
		if Be(i)
			k=rem(i-1,3);
			l=floor((i+2)/3);
			nIpt=nIpt+1;
			switch k
				case 0
					Ipt(nIpt,:)=Ivs([1,2],l);
					Zsegments(:,1:2,nIpt)=STL.vertex(:,Ivs([1,2],l));
				case 1
					Ipt(nIpt,:)=Ivs([1,3],l);
					Zsegments(:,1:2,nIpt)=STL.vertex(:,Ivs([1,3],l));
				case 2
					Ipt(nIpt,:)=Ivs([2,3],l);
					Zsegments(:,1:2,nIpt)=STL.vertex(:,Ivs([2,3],l));
			end		% switch point choice
		end		% if Be(i)
	end
end

%% find groups of segments
I=Ipt;
II=zeros(1,nIpt*2);
iB=0;
nII=0;
while any(I(:,1))
	iB=iB+1;
	while I(iB)==0
		iB=iB+1;
	end
	m0=I(iB);
	I(iB)=0;
	nII=nII+1;
	II(nII)=m0;
	j=iB;
	k=2;	% next point is in second row of I
	while I(j,k)	% normally always ~=0
		m=I(j,k);
		nII=nII+1;
		II(nII)=m;
		I(j,k)=0;
		if m==m0	% back to start
			break;
		end
		j=find(I==m);
		if isempty(j)
			if bAllowJunctions	% end of section
				break
			else
				error('Unexpected not to find any point!')
			end
		elseif length(j)>1
			if bAllowJunctions
				if bSeparateSections
					break
				else
					j=j(1);	% just take the first option...
					k=floor((j-1)/nIpt)+1;
					j=rem(j-1,nIpt)+1;
				end
			else
				error('Multiple usage of points is currently not foreseen!')
			end
		else
			k=floor((j-1)/nIpt)+1;
			j=rem(j-1,nIpt)+1;
		end
		I(j,k)=0;
		k=3-k;	% other side
		if m==m0	% back to start
			break;
		end
	end		% while I(j,k)
	nII=nII+1;	% split with a zero
end
nII=nII-1;	% remove last zero
II=II(1:nII);

%% Make coordinate list
Z=nan(nII,3);
Z(II~=0,:)=STL.vertex(:,nonzeros(II))';

%% Other simplification trial: combine triangles to polygons
if bCreatePolygons
	
end


D=var2struct(Ivs,Zsegments,Ipt,II,Z);

function [Bv,Ipt]=FindEdges(STL,edgeAngle)
camax=cosd(edgeAngle);
Bv=false(size(STL.normal));
Ipt=zeros(size(STL.normal,2)*2,2);	% indices of points of selected edges
nIpt=0;
ptMax=max(STL.Ipt(:));
[sIpt,IIpt]=sort(STL.Ipt);
V=[ptMax 1 0;0 ptMax 1;ptMax 0 1]*sIpt;	% combine to one value per edge
%(!!!) similar to "Be-determination", but implemented differently
for i=1:size(Bv,2)-1
	for j=1:3
		v=V(j,i);
		if v
			V(j,i)=0;
			k=find(V==v);
			if ~isscalar(k)
				error('Unexpected - single edge or more than double used edge?')
			end
			V(k)=0;
			n=floor((k+2)/3);
			ca=STL.normal(:,i)'*STL.normal(:,n);
			if ca<camax
				%m=rem(k-1,3);
				nIpt=nIpt+1;
				switch j
					case 1	% V1-V2
						Bv(IIpt(1:2,i),i)=true;
						Ipt(nIpt,:)=sIpt(1:2,i);
					case 2	% V2-V3
						Bv(IIpt(2:3,i),i)=true;
						Ipt(nIpt,:)=sIpt(2:3,i);
					otherwise	% V1-V3
						Bv(IIpt([1 3],i),i)=true;
						Ipt(nIpt,:)=sIpt([1 3],i);
				end
			end		% edge
		end		% if v
	end		% for j
end		% for i
Ipt=Ipt(1:nIpt,:);
