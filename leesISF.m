function [e,ne,de,e2,gegs]=leesISF(fName,varargin)
%leesISF - Reads ISF file (file format of Tektronics scopes)
%    [e,ne,de,e2,gegs]=leesISF(fName)

%??? This function has existed but disappeared - and was now remade?!!!

[bRawData] = false;
if nargin>1
	setoptions({'bRawData'},varargin{:})
end

fid = fopen(fFullPath(fName,true,'.ISF'));
x = fread(fid,[1 Inf],'*int8');
fclose(fid);

e = [];
ne = {};
de = {};
e2 = {};
gegs = {};
ix = 1;
H = struct();
while ix<length(x)
	if x(ix)~=':'
		warning('Unexpected character?!!')
		break
	end
	ix = ix+1;
	ix0 = ix;
	while (x(ix)>='A' && x(ix)<='Z') || x(ix)=='_'
		ix = ix+1;
	end
	w = char(x(ix0:ix-1));
	switch w
		case 'WFMP'
			% start of waveform (but normally two time?!!)
		case 'CURV'
			if x(ix)~=' ' || x(ix+1)~='#'
				error('Unexpected curve definition')
			end
			ix = ix+2;
			n = double(x(ix)-48);
			nB = str2double(char(x(ix+1:ix+n)));
			ix = ix+n;
			xRaw = x(ix+1:ix+nB);
			ix = ix+nB;
			if bRawData
				Xi = xRaw;
			else
				Xi = (double(xRaw)-H.YOF)*H.YMU;
			end
			e(:,end+1) = Xi;
			H.dt = H.XIN;
			gegs{1,end+1} = H;
			H = struct();
			ix = ix+1;
		otherwise
			ix = ix+1;
			while true
				ix0 = ix;
				while x(ix)~=';'
					ix = ix+1;
				end
				s_v = char(x(ix0:ix-1));
				if (s_v(1)>='0' && s_v(1)<='9') || s_v(1)=='-'	% number - hopefully...
					vv = str2double(s_v);
					if ~isnan(vv)
						v = vv;
					else
						v = s_v;
					end
				elseif s_v(1)=='"' && s_v(end)=='"'
					v = string(s_v(2:end-1));
				else
					v = s_v;
				end
				if isfield(H,w)
					if ~isequal(H.(w),v)
						warning('Different values for dupplicate data fields (%s)?!',w)
					end
				else
					H.(w) = v;
				end
				ix = ix+1;
				ix0 = ix;
				while x(ix)~=':' && x(ix)~=' '
					ix = ix+1;
				end
				if x(ix)==':'
					break
				end
				w = char(x(ix0:ix-1));
				ix = ix+1;
			end
	end
end
try
	gegs = [gegs{:}];
catch err
	DispErr(err)
	warning('Couldn''t combine "gegs"-parts?!')
	return
end
if isscalar(gegs) && iscell(gegs)
	gegs = gegs{1};
end
ne = {gegs.PT_F};
de = cell(1,length(gegs));
[de{:}] = deal('V');
