function [X,nX]=leescana(fn,varargin)
% LEESCANA - Leest CANalyser (ASCII-)metingen
%    x= leescana(fn[,options]);
%        options
%              nMax : maximum number of data-lines

nMax=1e12;

if nargin>1
	setoptions({'nMax'},varargin{:})
end

if ischar(fn)
	fid=fopen(zetev([],fn),'rt');
	if fid<3
		fid=fopen(fn,'rt');
		if fid<3
			error('Kan file niet openen')
		end
	end
else
	fid=fn;
end
fseek(fid,0,'eof');
flen=ftell(fid);
fseek(fid,0,'bof');

x1='';
xs='';
CR=char([13 10]);
while ~strcmpi(x1(1:min(end,5)),'begin')||~strcmpi(x1(1:min(end,5)),'start')
	x1=fgetl(fid);
	xl=lower(x1);
	if ~isempty(findstr(xl,'begin'))||~isempty(findstr(xl,'start'))
		break
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
X=[];
nx=0;
p1=ftell(fid);
a11=false;
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
	bTx = 0;
	if n==3
		% use of additional 'x' is not used (extended ID)
		if any(x1=='R')
			[a2,n2,~,in2]=sscanf(x1(in+1:end),' Rx d %d',1);
		elseif any(x1=='T')
			[a2,n2,~,in2]=sscanf(x1(in+1:end),' Tx d %d',1);
			bTx = 1;
		elseif contains(x1,'ErrorFrame')
			fprintf('ErrorFrame! --- discarded --- "%s"\n',x1)
			continue
		else
			error('Other format? ("%s")',x1)
		end
		n = n+n2;
		in = in+in2;
		a1 = [a1;a2]; %#ok<AGROW>
	end
	if n~=4
		while in>1&&x1(in-1)~=' '	% (!) vooral om het lezen van 'e' te "compenseren"
			in=in-1;
		end
		while in<=length(x1)&&x1(in)==' '
			in=in+1;
		end
		x2=lower(x1(in:end));
		i=find(x2==' ');
		if ~isempty(i)
			x2=lower(x2(1:i(1)-1));
		end
		if n>=2
			if strcmp(x2,'statistic:')
				continue;	%% niets mee gedaan (?bijhouden als extra gegevens?)
			elseif strcmp(x2,'errorframe')
				continue;	%% niets mee gedaan (?bijhouden als extra gegevens?)
			end
		elseif n==1
			if strcmp(x2,'start')
				continue;	%% niets mee gedaan
			elseif strcmp(x2,'can')
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
		d=sscanf(x1(in:end),'%x')';
		if a1(4)~=length(d)
			error('onverwacht aantal data-bytes')
		else
			if a1(2)~=1&&~a11
				a11=true;
				fprintf('...... %s\n',deblank(x1));
			end
			if nx==0
				estN=ceil((flen-p1)/(length(x1)+2));
				X=zeros(estN,12);
			elseif nx>=size(X,1)
				X=[X;zeros(100,12)];	%#ok<AGROW> %?? tweede estimation?
			end
			nx=nx+1;
			X(nx)=a1(3);	%#ok<AGROW> % ID
			X(nx,10)=a1(1);	%#ok<AGROW> % t
			X(nx,2:1+a1(4))=d; %#ok<AGROW>
			X(nx,11) = a1(4);
			X(nx,12) = bTx;
			if nx>=nMax
				break
			end
		end
	end
end
p1=ftell(fid);
fseek(fid,0,'eof');
p2=ftell(fid);
if ischar(fn)
	fclose(fid);
end
if p1<flen
	fprintf('!!niet alles ingelezen (%d/%d bytes)\n',p1,p2)
end
X=X(1:nx,:);
if nargout>1
	nX={'ID','d1','d2','d3','d4','d5','d6','d7','d8','t','DLC','Tx'};
end
