function D = ReadPyIMGbin(fName,varargin)
%ReadPyIMGbin - Read binary file from ImageNavitagor (Python)
%         extended to also reading pck-files (pickle)
%      D = ReadPyIMGbin(fName)

[bPlot] = nargout==0;
[lim3D] = [];
[depth_Clim] = [];
[rotate3d] = [1 -1 -1];
if ~isempty(varargin)
	setoptions({'bPlot','lim3D','depth_Clim','rotate3d'},varargin{:})
end

fName = fFullPath(fName);
[~,fNameF,fExt] = fileparts(fName);

if strcmpi(fExt,'.bin')
	D = ReadSV_BIN(fName);
elseif strcmpi(fExt,'.pck')
	D = ReadPickle(fName);
else
	error('Unknown type (file-extension)! (%s)',fExt)
end
if bPlot
	if isfield(D,'depth')
		getmakefig('SV_depth')
		imagesc(D.depth)
		colorbar
		axis equal
		title(fNameF,'Interpreter','none')
		if ~isempty(depth_Clim)
			clim(depth_Clim)
		end
	end
	if isfield(D,'pc')
		getmakefig('SV_pointcloud')
		B = true(size(D.pc,1),1);
		if isvector(rotate3d)
			A = diag(rotate3d);
		else
			A = rotate3d;
		end
		PC = D.pc*A;
		if ~isempty(lim3D)
			if isfield(lim3D,'X') && ~isempty(lim3D.X)
				B = B & PC(:,1)>=lim3D.X(1) & PC(:,1)<=lim3D.X(2);
			end
			if isfield(lim3D,'Y') && ~isempty(lim3D.Y)
				B = B & PC(:,2)>=lim3D.Y(1) & PC(:,2)<=lim3D.Y(2);
			end
			if isfield(lim3D,'Z') && ~isempty(lim3D.Z)
				B = B & PC(:,3)>=lim3D.Z(1) & PC(:,3)<=lim3D.Z(2);
			end
		end
		h = scatter3(PC(B,1),PC(B,2),PC(B,3),'.');grid
		h.Parent.Toolbar.Visible = 'on';
		h.CData = D.pc(B,3);
		axis equal
		title(fNameF,'Interpreter','none')
	end
	if isfield(D,'rgb')
		getmakefig('SV_rgb')
		image(D.rgb)
		axis equal
		title(fNameF,'Interpreter','none')
		axis off
	end
end

function D = ReadSV_BIN(fName)
fid = fopen(fName);
x = fread(fid,[1 Inf],'*uint8');
fclose(fid);

[typ,ix] = ReadString(x,0);
if ~startsWith(typ,'VIDEObin') && ~startsWith(typ,'VIDEOstream')
	%(!!!)VIDEOstream contains multile images!!!!
	error('Unexpected start!')
end
D = struct('type',typ);
while ix<length(x)
	[typ,ix] = ReadString(x,ix);
	switch typ
		case {'depth','pc','gray'}
			[D,ix] = ReadData(x,ix,2,D,typ);
		case 'rgb'
			[D,ix] = ReadData(x,ix,3,D,typ);
		case 'time'
			ixn = ix+8;
			t = typecast(x(ix+1:ixn),'double')/1000;	% ms --> s
			[D,bExtra] = AddField(D,typ,t);
			if bExtra
				break
			end
			ix = ixn;
		otherwise
			if length(typ)>32 || any(typ<32 | typ>127)
				printhex(typ(1:min(length(typ),32)))
				typ = '???';
			end
			warning('Wrong/unknown data? ("%s": %d/%d)',typ,ix,length(x))
			break
	end
end

function [s,ix] = ReadString(x,ix)
ixn = ix+1;
while ixn<length(x) && x(ixn)
	ixn = ixn+1;
end
if x(ixn)	% wrong end of file?
	ixn = ixn+1;
end
s = char(x(ix+1:ixn-1));
ix = ixn;

function [D,bExtra] = AddField(D,fld,d)
bExtra = false;
nExtra = 0;
while isfield(D,fld)
	fld(end+1) = '_'; %#ok<AGROW> 
	bExtra = true;
	nExtra = nExtra+1;
	if nExtra>=10
		warning('To many records of field "%s"',fld)
		return
	end
end
D.(fld) = d;

function [D,ix] = ReadData(x,ix,ndim,D,fld)
[dtyp,ix] = ReadString(x,ix);
switch dtyp
	case {'uint8','int8'}
		nB = 1;
	case {'uint16','int16'}
		nB = 2;
	case {'uint32','int32'}
		nB = 4;
	case 'float32'
		nB = 4;
		dtyp = 'single';
	case 'double'	% shouldn't this be 'float' or 'float64'?
		nB = 8;
	otherwise
		error('Unknown datatype! (%s)',dtyp)
end
ixn = ix+4*ndim;
siz = typecast(x(ix+1:ixn),'uint32');
ix = ixn;
ixn = ix+prod(siz)*nB;
d = x(ix+1:ixn);
if ~strcmp(dtyp,'uint8')
	d = typecast(d,dtyp);
end
ix = ixn;
d = reshape(d,siz(ndim:-1:1));
if ndim==2
	d = d';
elseif ndim==3
	d = permute(d(siz(3):-1:1,:,:),ndim:-1:1); % generic?
end
D = AddField(D,fld,d);
