function X=ReadStruct(fName,fModel)
%ReadStruct - Read Structure measurement file
%     X=ReadStruct(fName[,fModel])

%!!!!!????? difference with ReadStructObj?

bPlot = nargout==0&&nargin>1;

if isstruct(fName)&&isfield(fName,'Av')
	Plot(fName)
	return
end
fFull = fFullPath(fName,false,'.obj',false);
if isempty(fFull)
	fFull = fFullPath(fName,false,'.zip');
end
[~,~,fExt] = fileparts(fFull);
if strcmpi(fExt,'.zip')
	Z = ReadZip(fFull);
	B = strcmpi({Z.fName},'Model.obj');
	if ~any(B)
		error('File not found!')
	end
	Z = Z(B);
	Xraw = Z.fUncomp;
else
	fid = fopen(fFull);
	Xraw = fread(fid,[1 Inf],'*uint8');
	fclose(fid);
end

iiLF = [0 find(Xraw==10) length(Xraw)+1];
F = struct('Xraw',Xraw, 'iiLF',iiLF, 'nrLine', 1);
BlineType = false(length(iiLF)-1,2);
X=struct('file',fName,'comments',{{}},'Av',[],'Avn',[],'Avt',[],'Af',[]);
while F.nrLine<length(iiLF)
	[F,l] = GetNextLine(F);
	if isempty(l)
		warning('empty line!(?) %d',F.nrLine)
	elseif l(1)=='#'
		X.comments{1,end+1}=sprintf('%d: %s',F.nrLine,l);
	else
		[s,cnt,~,iNext]=sscanf(l,'%s',1);
		if cnt
			switch lower(s)
				case 'mtllib'
					X.mtllib = strtrim(l(iNext:end));
				case 'usemtl'
					X.usemtl = strtrim(l(iNext:end));
				case 'v'
					if isempty(X.Av)
						sTp='v %g %g %g\n';
						[F,D] = ReadData(F,sTp);
						X.Av=[sscanf(l,sTp,[1,3]);D];
					else	% mixed data!
						BlineType(F.nrLine-1,1) = true;
					end
				case 'vn'
					if isempty(X.Avn)
						sTp='vn %g %g %g\n';
						[F,D] = ReadData(F,sTp);
						X.Avn=[sscanf(l,sTp,[1,3]);D];
					else
						BlineType(F.nrLine-1,2) = true;
					end
				case 'vt'
					if ~isempty(X.Avt)
						warning('Not foreseen!!!!')
					end
					sTp='vt %g %g\n';
					[F,D] = ReadData(F,sTp);
					X.Avt=[sscanf(l,sTp,[1,2]);D];
				case 'f'
					if ~isempty(X.Af)
						warning('Not foreseen!!!!')
					end
					sTp='f %d/%d/%d %d/%d/%d %d/%d/%d\n';
					x=sscanf(l,sTp,[1,9]);
					if length(x)<9
						sTp='f %d//%d %d//%d %d//%d\n';
						x=sscanf(l,sTp,[1,6]);
						if length(x)<6
							warning('Something is going wrong!!!')
						end
					end
					[F,D] = ReadData(F,sTp);
					X.Af=[x;D];
					if length(x)==9
						Dd=zeros(9,6);
						for i=1:3
							j1=(i-1)*2+1;
							i1=(i-1)*3+1;
							Dd(i1,j1:j1+1)=-1;
							Dd(i1+1,j1)=1;
							Dd(i1+2,j1+1)=1;
						end
						ii=1:3:9;
					else
						Dd=[-1  0  0;
							 1  0  0;
							 0 -1  0;
							 0  1  0;
							 0  0 -1;
							 0  0  1];
						 ii=1:2:6;
					end
					dA=X.Af*Dd;
					if all(dA(:))==0
						X.Af=X.Af(:,ii);
					else
						warning('Expected to have another format!')
					end
				otherwise
					fprintf('what? (#%d - %s)\n',F.nrLine,l)
			end
		end
	end
end
if any(BlineType(:))	% existing mixed data (no blocks of the same data)
	nLinesToAdd = sum(BlineType);
	Av = zeros(nLinesToAdd(1),length(X.Av));
	Avn = zeros(nLinesToAdd(2),length(X.Avn));
	n = zeros(1,2);
	for i=1:size(BlineType,1)
		if BlineType(i)
			l = char(Xraw(iiLF(i)+3:iiLF(i+1)-1));
			n(1) = n(1)+1;
			v = sscanf(l,'%g %g %g');
			if length(v)==3
				Av(n(1),:) = v;
			else
				warning('Problem with "v"!')
			end
		elseif BlineType(i,2)
			l = char(Xraw(iiLF(i)+4:iiLF(i+1)-1));
			n(1) = n(1)+1;
			v = sscanf(l,'%g %g %g');
			if length(v)==3
				Avn(n(1),:) = v;
			else
				warning('Problem with "vn"!')
			end
		end
	end
	X.Av = [X.Av;Av];
	X.Avn = [X.Avn;Avn];
end

if nargin>1
	X.Img = imread(fFullPath(fModel));
end

if bPlot
	Plot(X)
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

function [F,l] = GetNextLine(F)
l = char(F.Xraw(F.iiLF(F.nrLine)+1:F.iiLF(F.nrLine+1)-1));
F.nrLine = F.nrLine+1;

function [F,D] = ReadData(F,sTp)
iSp = find(sTp==' ',1);
ii = F.iiLF(F.nrLine:end-1)+1;
while ii(end)>length(F.Xraw)-iSp
	ii(end) = [];
end
B = F.Xraw(ii)==sTp(1);
if ~all(B)
	ii = ii(1:find(~B,1)-1);
end
for i=1:iSp-1
	B = F.Xraw(ii+i)==sTp(i+1);
	if ~all(B)
		ii = ii(1:find(~B,1)-1);
		if isempty(ii)
			break
		end
	end
end
nLines = length(ii);
if nLines==0
	D = zeros(0,sum(sTp=='%'));
else
	D = sscanf(char(F.Xraw(ii(1):F.iiLF(F.nrLine+nLines))),sTp,[sum(sTp=='%'),Inf])';
	F.nrLine = F.nrLine+nLines;
end

function Plot(X)
if isfield(X,'Img')&&~isempty(X.Img)
	fImg = getmakefig('STRUCTimg');
	h = image([0 1],[1 0],X.Img);
	axis xy
	lPtImg = line(X.Avt(:,1),X.Avt(:,2),'marker','.','linestyle','none');
	lMarkerImg = line(0,0,'marker','o','color',[1 0 0],'linestyle','none');
	axis equal
	X.fImg = fImg;
	X.hImg = h;
	X.lPtImg = lPtImg;
	X.lMarkerImg = lMarkerImg;
	set(lPtImg,'ButtonDownFcn',@LineImgClicked)
else
	fImg = [];
end

f3D = getmakefig('STRUCT3D');
l3D = plot3(X.Av(:,1),X.Av(:,2),X.Av(:,3),'.');
lMarker3D = line(0,0,0,'marker','o','color',[1 0 0],'linestyle','none');
grid
axis equal

X.f3D = f3D;
X.l3D = l3D;
X.lMarker3D = lMarker3D;
if exist('figmenu','file')
	figmenu
end

set([fImg,f3D],'UserData',X)
set(l3D,'ButtonDownFcn',@Line3DClicked)
