function [X,nX,Dextra,Dhead]=leescana(fn,varargin)
% LEESCANA - Leest CANalyser (ASCII-)metingen
%    [x,nX,Dextra,Dhead] = leescana(fn[,options]);
%        options
%              nMax : maximum number of data-lines

nMax=1e12;
[bSimpleHead] = false;

if nargin>1
	setoptions({'nMax','bSimpleHead'},varargin{:})
end

if isstringlike(fn) || (isstruct(fn) && isfield(fn,'datenum'))
	fid=fopen(fFullPath(fn),'rt');
	if fid<3
		fid=fopen(fn,'rt');
		if fid<3
			error('Kan file niet openen')
		end
	end
	bMyFile = true;
else
	fid = fn;
	bMyFile = false;
end
fseek(fid,0,'eof');
flen=ftell(fid);
fseek(fid,0,'bof');

if bSimpleHead
	fgetl(fid);	% skip first line
	l = 'a';
	while ~isempty(l)
		l = fgetl(fid);
	end
	Dextra = [];
else
	x1='';
	xs='';	% not used - replaced by Dhead?
	CR=char([13 10]);
	Dhead = struct();
	Dextra = struct('t',cell(0,1),'CAN',0,'type','','data',[]);
	while ~strcmpi(x1(1:min(end,5)),'begin')||~strcmpi(x1(1:min(end,5)),'start')
		x1=fgetl(fid);
		[w,~,~,in] = sscanf(x1,'%s',1);
		if any(strcmpi(w,{'begin','start'}))
			x1 = x1(in:end);
			[w,~,~,in] = sscanf(x1,'%s',1);
			Dhead.begin = struct('typ',w,'t',datenum(x1(in+4:end)));
			break
		end
		if strcmpi(w,'date')
			Dhead.date = datenum(x1(in+4:end));
		elseif strcmpi(w,'base')
			w = regexp(x1,' ','split');
			i = 1;
			while i<length(w)
				if isempty(w{i})
					i = i+1;
				else
					Dhead.(w{i}) = w{i+1};
					i = i+2;
				end
			end
		end
		if feof(fid)
			fclose(fid);
			error('Kan begin van data niet vinden');
		end
		if isempty(xs)
			xs=x1;
		else
			xs=[xs CR x1];
		end
	end
end
X=[];
nx=0;
p1=ftell(fid);
nError=0;
while ~feof(fid)
	x1=deblank(fgetl(fid));
	if isempty(x1)
		continue;
	end
	if strcmpi(x1(1:min(end,3)),'end')
		break;
	end
	[a1,n,~,in]=sscanf(x1,'%g %d %x',3);
	if n==3		% check for interpreting text by %x (like "Error")
		i = in-1;
		while isspace(x1(i))
			i = i-1;
		end
		if x1(i+1)>='9'		% no digit
			if x1(i+1)=='x'	% extended
				in = i+1;
			else
				n = n-1;
				a1(3) = [];
				in = i+1;
			end
		end
	end
	bTx = 0;
	if n==3
		% use of additional 'x' is not used (extended ID)
		if any(x1=='R')
			[a2,n2,~,in2]=sscanf(x1(in+1:end),' Rx d %d',1);
		elseif any(x1=='T')
			[a2,n2,~,in2]=sscanf(x1(in+1:end),' Tx d %d',1);
			bTx = 1;
		else
			error('Other format? ("%s")',x1)
		end
		n = n+n2;
		in = in+in2;
		a1 = [a1;a2]; %#ok<AGROW>
	end
	if n~=4
		while in>1&&~isspace(x1(in-1))	% (!) vooral om het lezen van 'e' te "compenseren"
			in=in-1;
		end
		while in<=length(x1)&&isspace(x1(in))
			in=in+1;
		end
		x2=lower(x1(in:end));
		i=find(isspace(x2));
		if ~isempty(i)
			i = i(1);
			x2=lower(x2(1:i-1));
		end
		if n>=2
			if strcmp(x2,'statistic:')
				Dextra(end+1).t = a1(1); %#ok<AGROW> 
				Dextra(end).CAN = a1(2);
				Dextra(end).type = 'stat';
				P = regexp(x1(in+11:end),' ','split');
				try
					P = struct(P{:});
					Dextra(end).data = P;
				catch err
					DispErr(err)
					warning('Something went wrong interpreting statistics (%s)',x1)
				end
				continue
			elseif strcmp(x2,'errorframe')
				Dextra(end+1).t = a1(1); %#ok<AGROW> 
				Dextra(end).CAN = a1(2);
				Dextra(end).type = 'ErrorFrame';
				P = regexp(x1(in+11:end),char(9),'split');
				for i = 1:length(P)
					j = find(P{1,i}=='=');
					if isscalar(j)
						P{2,i} = strtrim(P{1,i}(j+2:end));
						P{1,i} = strtrim(P{1,i}(1:j-2));
					else
						%warning('Something wrong!! (%s)',a1)
						P{2,i} = P{1,i};
						P{1,i} = sprintf('raw%d',i);
					end
				end
				Dextra(end).data = struct(P{:});
				continue;
			else
				aaaaa=1;
			end
		elseif n==1
			if strcmp(x2,'start')
				continue;	%% niets mee gedaan
			elseif strcmp(x2,'can')
				if x1(in+4)>='1' && x1(in+4)<='9' && x1(in+5)==' '
					Dextra(end+1).t = a1(1); %#ok<AGROW> 
					Dextra(end).CAN = x1(in+4)-'0';
					x2 = x1(in+6:end);
					i = find(x2==':',1);
					if isscalar(i)
						Dextra(end).type = x2(1:i-1);
						Dextra(end).data = x2(i+1:end);
					else
						Dextra(end).type = 'unknown';
						Dextra(end).data = x2;
					end
				else
					warning('Unexpected (%s)',x1)
				end
				continue;	%% niets mee gedaan (?bijhouden als extra gegevens?)
			end
		end
		nError=nError+1;
		if nError>=20
			if nError==20
				fprintf('!printing of error lines stopped!\n')
			end
		else
			fprintf('%s\n',x1)
		end
	else
		[d,n2,~,iNxt] = sscanf(x1(in:end),'%x',[1 a1(4)]);
		if a1(4)~=n2
			error('onverwacht aantal data-bytes')
		else
			x1 = strtrim(x1(in+iNxt:end));
			if nx==0
				estN=ceil((flen-p1)/(length(x1)+2));
				X=zeros(estN,15);
			elseif nx>=size(X,1)
				X=[X;zeros(100,15)];	%#ok<AGROW> %?? tweede estimation?
			end
			nx=nx+1;
			X(nx)=a1(3);	%#ok<AGROW> % ID
			X(nx,10)=a1(1);	%#ok<AGROW> % t
			X(nx,2:1+a1(4))=d; %#ok<AGROW>
			X(nx,11) = a1(4); %#ok<AGROW> 
			X(nx,12) = bTx; %#ok<AGROW> 
			X(nx,13) = a1(2);	 %#ok<AGROW> % CAN-nr
			while ~isempty(x1)
				[w,~,~,iNxt] = sscanf(x1,'%s',1);
				[v,~,~,iNxt2] = sscanf(x1(iNxt+1:end),'= %d');
				if isempty(v)
					break
				end
				x1 = x1(iNxt+iNxt2+1:end);
				switch w
					case 'Length'
						X(nx,14) = v;
					case 'BitCount'
						X(nx,15) = v;
					case 'ID'
						if v~=a1(3)
							warning('Two different CAN-ID''s?!! (%d,%d)',a1(3),v)
						end
				end
			end
			if nx>=nMax
				break
			end
		end
	end
end		% while ~feof(fid)
p1=ftell(fid);
fseek(fid,0,'eof');
p2=ftell(fid);
if bMyFile
	fclose(fid);
end
if p1<flen
	fprintf('!!niet alles ingelezen (%d/%d bytes)\n',p1,p2)
end
X=X(1:nx,:);
if nargout>1
	nX={'ID','d1','d2','d3','d4','d5','d6','d7','d8','t','DLC','Tx','CANnr','Length','BitCount'};
end
