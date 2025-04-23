function D = ReadOrbitData(fName)
%ReadOrbitData - Read orbit data (OEF2.0 format)
%    D = ReadOrbitData(fName)

% see https://newton.spacedys.com/astdys

c = cBufTextFile(fName);
LINES = c.fgetlN(1000);

% read header
H = struct('format','');
epoch = 0;
EqEl = [];
extra = struct();
iL = 0;
while true
	iL = iL+1;
	l = LINES{iL};
	if strcmpi(l,'END_OF_HEADER')
		break
	end
	i = find(l=='=',1);
	if isempty(i)
		error('Unexpected header line!')
	end
	typ = deblank(l(1:i-1));
	r = strtrim(l(i+1:end));
	if any(r=='!')
		r = deblank(r(1:find(r=='!',1)-1));
	end
	if length(r)>1 && r(1)=='''' && r(end)==''''
		r = r(2:end-1);
	end
	H.(typ) = r;
end
if ~strcmp(H.format,'OEF2.0')
	warning('Unexpected file format ("%s")',H.format)
end
if ~isfield(H,'rectype') || ~strcmp(H.rectype,'ML')
	if isfield(H,'rectype')
		rtyp = '???';
	else
		rtyp = H.rectype;
	end
	warning('Not implemented or not specified record type! ("ML" is expected, "%s" given)',rtyp)
end
iL = iL+1;
name = LINES{iL};
while iL<length(LINES)
	iL = iL+1;
	l = LINES{iL};
	if l(1)=='!'
		if strcmp(l(3:min(end,22)),'Equinoctial elements')
			extra.EqEl = l(25:end);
		elseif any(strcmp(l(3:min(end,5)),{'RMS','EIG','WEA'}))
			extra.(l(3:5)) = sscanf(l(7:end),'%g',[1 10]);
		end
	elseif l(1)==' '
		typ = l(2:4);
		switch typ
			case 'EQU'
				equ = sscanf(l(6:end),'%g',[1 10]);
				if length(equ)==6	% as expected
					EqEl = struct('a',equ(1),'eSLP',equ(2),'eCLP',equ(3)		...
						,'tIsLN',equ(4),'tIcLN',equ(5),'mL',equ(6));
					f = EqEl.eSLP;
					g = EqEl.eCLP;
					e = sqrt(f^2+g^2);
					h = EqEl.tIsLN;
					k = EqEl.tIcLN;
					L = EqEl.mL;
					i = 2*atan(sqrt(h^2+k^2));
						% i = atan2(2*sqrt(h^2+k^2),1-h^2-k^2);
					o = atan(g/f)-atan(k/h);
						% o = atan2(g*h-f*k,f*h+g*k);
					O = atan2(k,h);
					u = atan2(h*sin(L)-k*cos(L),h*cos(L)+k*sin(L));
					EqEl.e = e;
					EqEl.i = i;
					EqEl.o = o;
					EqEl.O = O;
					EqEl.u = u;	% M?
				else
					warning('Unexpected number of elements for EQU! (#%d)',length(equ))
					EqEl = equ;
				end
			case 'MJD'
				% for different time systems, look to https://gssc.esa.int/navipedia/index.php/Transformations_between_Time_Systems
				[t,~,~,n] = sscanf(l(6:end),'%g');
				tf = strtrim(l(5+n:end));
				epoch = t+2400000.5;
				if ~strcmp(tf,'TDT')
					warning('For epoch, unexpected time format is given ("%s")',tf)
				end
			case 'MAG'
				extra.mag = sscanf(l(6:end),'%g',[1 2]);
			case 'LSP'
				extra.lsp = sscanf(l(6:end),'%g',[1 3]);
			case 'COV'
				cov = sscanf(l(6:end),'%g',[1 10]);
				if isfield(extra,'COV')
					extra.COV(end+1,:) = cov;
				else
					extra.COV = cov;
				end
			case 'NOR'
				nor = sscanf(l(6:end),'%g',[1 10]);
				if isfield(extra,'NOR')
					extra.NOR(end+1,:) = nor;
				else
					extra.NOR = nor;
				end
			otherwise
				warning('Unknown type ("%s")',typ)
		end
	else
		warning('Unexpected line start ("%s")',l)
	end
end

D = var2struct(H,epoch,name,EqEl,extra);
