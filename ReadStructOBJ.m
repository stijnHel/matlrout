function X=ReadStructOBJ(fName,fModel,varargin)
%ReadStructOBJ - Read OBJ-file from structure measurement
%     X=ReadStructOBJ(fName[,fModel])

bReadImg = nargin>1&&ischar(fModel)&&~isempty(fModel);
fName = fFullPath(fName);

bPlot = nargout==0&&nargin>1;
if ~isempty(varargin)
	setoptions({'bPlot'},varargin{:})
end


X=struct('file',fName,'comments',{{}});

[~,~,fExt] = fileparts(fName);
if strcmp(fExt,'.zip')
	Z = ReadZip(fName);
	B = strcmpi({Z.fName},'Model.obj');
	if ~any(B)
		uiwait(errordlg('Sorry, wrong zip-file? or at least unexpected contents'))
		error('Sorry, can''t read zip-file')
	end
	fName = Z(B).fUncomp;	% no filename, but direct data-input
end

if isa(fName,'uint8')	% direct input
	x = fName;
	if iscolumn(x)
		x = x';
	end
	ii = [0 find(x==10) length(x)+1];
	L = cell(1,length(ii)-1);
	for i=1:length(L)
		L{i} = char(x(ii(i)+1:ii(i+1)-1));
	end
	X.file = 'directInput';
else
	f = cBufTextFile(fFullPath(fName,false,'.obj'));
	n = 1e6;
	L = f.fgetlN(n);
	if length(L)==n
		LL = cell(1,20);
		LL{1} = L;
		nLL = 1;
		while length(LL{nLL})==n
			nLL = nLL+1;
			LL{nLL} = f.fgetlN(n);
		end
		L = [LL{1:nLL}];
	end
end
TYP = zeros(1,length(L),'uint8');
for i=1:length(L)
	l = L{i};
	if length(l)>1
		c1 = l(1);
		c2 = l(2);
		if c1=='v'
			if c2==' '
				TYP(i) = 'v';
			elseif c2=='n'
				TYP(i) = 'n';
			elseif c2=='t'
				TYP(i) = 't';
			else
			end
		elseif c1=='f'
			TYP(i) = 'f';
		elseif c1=='#'
			X.comments{1,end+1}=sprintf('%d: %s',i,l);
		elseif c1=='m'
			if startsWith(l,'mtllib','IgnoreCase',true)
				X.mtllib = strtrim(l(7:end));
			else
			end
		elseif c1=='u'
			if startsWith(l,'usemtl','IgnoreCase',true)
				X.usemtl = strtrim(l(7:end));
			else
			end
		else
		end
	end
end		% for i
L(2,:) = {newline};

X.Av  = sscanf([L{:,TYP=='v'}],'v %g %g %g\n'   ,[3 Inf])';
X.Avn = sscanf([L{:,TYP=='n'}],'vn %g %g %g\n'  ,[3,Inf])';
B = TYP=='f';
i = find(B,1);
if contains(L{1,i},'//')
	sTp='f %d//%d %d//%d %d//%d\n';
	nTp = 6;
	ii = 1:2:6;
	jj = 2:2:6;
	Dd = [-1  0  0;
		 1  0  0;
		 0 -1  0;
		 0  1  0;
		 0  0 -1;
		 0  0  1];
else
	sTp='f %d/%d/%d %d/%d/%d %d/%d/%d\n';
	nTp = 9;
	ii = 1:3:9;
	jj = 2:3:9;	%(!!!???)
	Dd = zeros(9,6);
	for i = 1:3
		j1 = (i-1)*2+1;
		i1 = (i-1)*3+1;
		Dd(i1,j1:j1+1) = -1;
		Dd(i1+1,j1) = 1;
		Dd(i1+2,j1+1) = 1;
	end
end
X.Af = sscanf([L{:,B}],sTp,[nTp,Inf])';
dA = X.Af * Dd;
if all(dA,'all')==0
	X.Afv = X.Af(:,ii);
	X.Afvt = X.Af(:,jj);
else
	warning('Expected to have another format!')
end

if bReadImg
	X.Img = imread(fFullPath(fModel));
end

if bPlot
	f3D = getmakefig('STRUCT3D');
	l3D = plot3(X.Av(:,1),X.Av(:,2),X.Av(:,3),'.');
	lMarker3D = line(0,0,0,'marker','o','color',[1 0 0],'linestyle','none');
	grid
	axis equal
	X.f3D = f3D;
	X.lMarker3D = lMarker3D;
	if exist('figmenu','file')
		figmenu
	end
	
	if bReadImg && ~isempty(X.img)
		fImg = getmakefig('STRUCTimg');
		h = image([0 1],[1 0],X.Img);
		axis xy
		lPtImg = line(X.Avt(:,1),X.Avt(:,2),'marker','.','linestyle','none');
		lMarkerImg = line(0,0,'marker','o','color',[1 0 0],'linestyle','none');
		axis equal
		X.fImg = fImg;
		X.hImg = h;
		X.lPtImg = lPtImg;
		X.l3D = l3D;
		X.lMarkerImg = lMarkerImg;
		set(lPtImg,'ButtonDownFcn',@LineImgClicked)
		set(l3D,'ButtonDownFcn',@Line3DClicked)
		set([fImg,f3D],'UserData',X)
	end
end

function LineImgClicked(l,~)
f = ancestor(l,'figure');
X = get(f,'UserData');
pt = get(gca,'CurrentPoint');
[dst,iPt] = min((X.Avt(:,1)-pt(1,1)).^2+(X.Avt(:,2)-pt(1,2)).^2);
set(X.lMarker3D,'XData',X.Av(iPt,1),'YData',X.Av(iPt,2),'ZData',X.Av(iPt,3));
set(X.lMarkerImg,'XData',X.Avt(iPt,1),'YData',X.Avt(iPt,2));
% also plot "neighbours"?

function Line3DClicked(l,~)
ax = ancestor(l,'axes');
f = ancestor(ax,'figure');
X = get(f,'UserData');

pt = get(ax,'CurrentPoint');

[ptSel,iPt]=GetSelPt3D(l,pt);
set(X.lMarker3D,'XData',ptSel(1),'YData',ptSel(2),'ZData',ptSel(3))
set(X.lMarkerImg,'XData',X.Avt(iPt,1),'YData',X.Avt(iPt,2));
%fprintf('%5d - (%6.3f,%6.3f,%6.3f)\n',iPt,X.Av(iPt,:))
