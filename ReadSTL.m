function D=ReadSTL(fName,varargin)
%ReadSTL  - Read an STL-file
%      D=ReadSTL(fName,...)
%          option: bPlot
%    see also https://en.wikipedia.org/wiki/STL_(file_format)

bPlot=nargout==0||iscell(fName);
iiPlot=[];
[bForceBin]=[];
[bWireframe]=false;
[bSomeAnalysis]=[];
[tol]=[0 3e-7];	% relatief
if nargin>1
	setoptions({'bPlot','bForceBin','iiPlot','bWireframe','bSomeAnalysis'	...
		,'tol'}	...
		,varargin{:})
end
if isstruct(fName)&&isfield(fName,'name')&&isfield(fName,'date')&&isfield(fName,'bytes')
	fName=fName.name;
end

if iscell(fName)||isstruct(fName)	% Not to read STL but plot it(!)
	D=fName;
	if ~isempty(iiPlot)
		if isstruct(D)
			D.normal=D.normal(:,iiPlot);
			D.vertex=D.vertex(:,:,iiPlot);
			D.lAttr=D.lAttr(iiPlot);
		else
			D=D(iiPlot);
		end
	end
else
	c=cBufTextFile(fName);
	if isempty(bForceBin)
		bForceBin=any(c.X==0);
	end
	iType=0;
	lNr=0;
	level=1;
	DD=cell(1,10);
	bStart=true;
	while true
		l=c.fgetl();
		if ~ischar(l)
			break
		end
		if bStart
			bStart=false;
			if bForceBin
				l=[0 l];
			elseif strcmp(l(1:min(end,6)),'solid ')
				if ~isequal(c.X(1:6),l(1:min(end,6)))	% 16-bit string
					l=[0 l];	% make sure it's not seen as ASCII STL
				end
			end
		end
		if isempty(l)
			break
		end
		lNr=lNr+1;
		[w,n,errmsg,iNxt]=sscanf(l,'%s',1);
		if n==0
			error('error in line #%d "%s" - %s',lNr,l,errmsg)
		end
		switch iType
			case 0	% base
				switch lower(w)
					case 'solid'
						iType=10;
						level=level+1;
						DD{level}={};
					otherwise	% binary (can be STLB, but also anything)
						% STL binary format!
						fseek(c.fid,0,'bof');
						H=fread(c.fid,[1 80],'*char');
						nFacets=fread(c.fid,1,'uint32');
						X=fread(c.fid,[50,nFacets],'*uint8');
						R=reshape(typecast(reshape(X(1:48,:),[],1),'single'),3,4,nFacets);
						lAttr=typecast(reshape(X(49:50,:),[],1),'uint16');
						DD={{struct('H',H,'normal',squeeze(R(:,1,:))	...
							,'vertex',R(:,2:4,:),'lAttr',lAttr)}};
						break
				end
			case 10	% solid
				switch w
					case 'facet'
						% read properties
						[w1,~,~,iNxt2]=sscanf(l(iNxt+1:end),'%s',1);
						x=sscanf(l(iNxt+iNxt2:end),'%g',[1 3]);
						iType=20;
						%DD{level}{1,end+1}={w1,x};
						DD{level}{1,end+1}=struct(w1,x);
						level=level+1;
						DD{level}={};
					case 'endsolid'
						iType=0;
						[DD,level]=UpdateStack(DD,level);
					otherwise
						error('solid-element %s is not implemented',w)
				end
			case 20	% facet
				switch w
					case 'outer'
						iType=30;
						% check if it's "outer loop"?
						level=level+1;
						DD{level}={};
					case 'endfacet'
						iType=10;
						[DD,level]=UpdateStack(DD,level);
					otherwise
						error('facet %s is not implemented',w)
				end
			case 30	% outer
				switch w
					case 'vertex'
						x=sscanf(l(iNxt+1:end),'%g',[1 3]);
						%DD{level}{1,end+1}={w x};
						DD{level}{1,end+1}=struct(w,x);
					case 'endloop'
						iType=20;
						[DD,level]=UpdateStack(DD,level);
					otherwise
						error('outer %s is not implemented',w)
				end
		end
	end
	D=DD{1};
	if isscalar(D)
		D=D{1};
	end
end

if isempty(bSomeAnalysis)
	bSomeAnalysis = ~isstruct(D) || ~isfield(D,'uX');
end

if bSomeAnalysis	% !!!!! temporarily !!!!!??
	if isstruct(D)
		V=D.vertex;
	elseif isstruct(D{1})
		[V,D]=GetVertexData(D);
	else
		DD=struct('STL',cell(1,length(D)),'vertex',[],'normal',[]);
		for i=1:length(D)
			[~,DD(i)]=GetVertexData(D{i});
		end
		D=DD;
		V=cat(3,DD.vertex);
	end
	%% find unique points
	if length(tol)>1
		tol=(max(V(:))-min(V(:)))*tol(2);
	end
	[uX,Ix]=FindUniqueVals(V(1,:,:),tol);
	[uY,Iy]=FindUniqueVals(V(2,:,:),tol);
	[uZ,Iz]=FindUniqueVals(V(3,:,:),tol);
	
	% find unique points
	Ipt=zeros(3,size(V,3));
	uIpt=zeros(size(V,3)*3,1);
	nUIpt=0;
	% combine 3 dimensions of indices to one scalar
	Ixyz=Ix-1+max(Ix(:)).*(Iy-1+max(Iy(:)).*Iz(:));
	[Is,iIxyz]=sort(Ixyz(:));
	i=1;
	while i<=length(Is)
		nUIpt=nUIpt+1;
		iI=iIxyz(i);
		uIpt(nUIpt)=iI;
		Ipt(iI)=iI;
		j=i+1;
		while j<=length(Is)&&Is(j)==Is(i)
			Ipt(iIxyz(j))=iI;
			j=j+1;
		end
		i=j;
	end
	uIpt=uIpt(1:nUIpt);
	
	V1=V(:,2,:)-V(:,1,:);
	V2=V(:,3,:)-V(:,1,:);
	Nx=V1(2,:).*V2(3,:)-V1(3,:).*V2(2,:);
	Ny=V1(3,:).*V2(1,:)-V1(1,:).*V2(3,:);
	Nz=V1(1,:).*V2(2,:)-V1(2,:).*V2(1,:);
	A=sqrt(Nx.^2+Ny.^2+Nz.^2)/2;
	
	if length(D)>1	%!!!!!!!!!!!!!!!!!!!
		D=struct('D',D,'vertex',V);
	end
	D.Ipt=Ipt;
	D.uIpt=uIpt;
	D.uX=uX;
	D.uY=uY;
	D.uZ=uZ;
	D.A=A;
end

if bPlot
	if isstruct(D)
		if bWireframe
			% Make one line
			V=D.vertex;
			V(:,4,:)=NaN;
			line(reshape(V(1,[1:3 1 4],:),1,[]),reshape(V(2,[1:3 1 4],:),1,[]),reshape(V(3,[1:3 1 4],:),1,[]))
		else
			patch(squeeze(D.vertex(1,:,:)),squeeze(D.vertex(2,:,:)),squeeze(D.vertex(3,:,:)),'b')
% 			for i=1:size(D.vertex,3)
% 				patch(D.vertex(1,:,i),D.vertex(2,:,i),D.vertex(3,:,i),'b');
% 			end
		end
	else
		if bWireframe
			warning('Wireframe not yet implemented for this type of STL!')
		else
			for i=1:length(D)
				if isstruct(D{i})&&isfield(D{i},'vertex')
					Z=cat(1,D{i}.vertex);
					patch(Z([1:3 1],1),Z([1:3 1],2),Z([1:3 1],3),'b');
				elseif iscell(D{i})
					ReadSTL(D{i});
				end
			end
		end		% ~bWireframe
	end		% if bPlot
	axis equal
end		% if bPlot

function D=Simplify(D)
if iscell(D)
	if isscalar(D)
		D=D{1};
	elseif all(cellfun(@isstruct,D))
		fn=cellfun(@fieldnames,D);
		if all(cellfun('length',fn))&&all(strcmp(fn{1},fn(2:end)))
			D=[D{:}];
		end
	end
end

function [DD,level]=UpdateStack(DD,level)
D1=Simplify(DD{level});
level=level-1;
DD{level}{1,end+1}=D1;

function [uX,Ix]=FindUniqueVals(V,tol)
V=V(:);
[uX,~,Ix]=unique(V);
Bdouble=false(size(uX));
nUnique=length(uX);
if ~isempty(tol)
	iRef=1;
	for i=2:nUnique
		if uX(i)-uX(iRef)<tol
			Ix(Ix==i)=iRef;
			Bdouble(iRef)=true;
			Bdouble(i)=true;
		else
			iRef=i;
		end
	end
end
if any(Bdouble)	% this could be done in the first loop
	i=1;
	while i<nUnique
		if Bdouble(i)
			j=i;
			s=0;
			n=0;
			while j<=nUnique&&Bdouble(j)
				n1=sum(V==uX(j));
				s=s+n1*uX(j);
				n=n+n1;
				j=j+1;
			end
			%uX(i)=mean(uX(i:j-1));
			uX(i)=s/n;	% weighted mean
			Bdouble(i)=false;	% keep this element and remove other doubles
			i=j+1;
		else
			i=i+1;
		end
	end
	uX(Bdouble)=[];
end
uX=uX';

function [V,D]=GetVertexData(D)
B=false(1,length(D));
N=zeros(length(D),3);
C=D;
for i=1:length(D)
	B(i)=isfield(D{i},'vertex');
	if B(i)
		C{i}=cat(1,D{i}.vertex)';
	elseif isfield(D{i},'normal')
		N(i,:)=D{i}.normal;
	end
end
V=cat(3,C{B});
D=struct('STL',{D},'vertex',V,'normal',N(B,:));
