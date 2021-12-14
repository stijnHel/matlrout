function [msgs,X]=leesdbc(f)
% LEESDBC  - Leest can-DBC-file
%    msgs=leesdbc(f)
%       msgs te gebruiken als input voor init van 'canmsg'-functie

fid=file(f);

ver=fgetl(fid);
lineNr=1;
if ~strcmp(ver(1:min(end,7)),'VERSION')
	warning('!DBC-file begint niet met VERSION!')
end

msgs=cell(0,7);
	% [msgID  msgName  signals #bytes target(?) extended combSig]
inblok=0;
X=struct('VAL',struct('ID',cell(1,0),'signal',[],'values',[])	...
	,'VAL_TABLE',struct('name',cell(1,0),'values',[]));
while ~feof(fid)
	ll=0;
	a=fgetl(fid);
	lineNr=lineNr+1;
	while ~feof(fid)&&isempty(a)
		ll=1;
		a=fgetl(fid);
		lineNr=lineNr+1;
	end
	if isempty(a)
		break;
	end
	a=deblank(a);
	if isempty(a)	%(!!! om eventuele problemen met input van enkel spaties te vermijden
		break;
	end
	if inblok
		if ll
			inblok=0;
		end
	end
	switch inblok
		case 0
			i_=find(a==' '|a==9|a==':',1);
			if isempty(i_)
				a3=a;
			else
				a3=a(1:i_-1);
				%a3=a(1:min(end,3));
			end
			switch a3
				case 'NS_'	% ?naamlijst???
					inblok=1;
				case 'BS_'	%?
				case 'BU_'	%?lijst van (?)objecten
					i=find(a==':');
					if isempty(i)
						warning('fout bij interpreteren van "BU_"')
						continue;
					end
					a=a(i(1)+1:end);
					bu={};
					while ~isempty(a)
						[bu{end+1},~,~,next]=sscanf(a,'%s',1);
						a=a(next:end);
					end
					%bu	% iets doen met bu?
				case 'BO_'	% can-boodschap
					inblok=2;
					a=a(5:end);
					msgs{end+1,3}=struct('signal',{},'M',{},'byte',{},'bit',{}	...
						,'bitorder',{},'bSigned',{},'bBigEndian',{}	...
						,'scale',{},'unit',{},'ob',{});
					[ID,~,~,next]=sscanf(a,'%u',1);
					msgs{end,1}=bitand(ID,2^30-1);
					msgs{end,6}=ID>=2^31;
					a=a(next:end);
					[nm,~,~,next]=sscanf(a,'%s',1);
					msgs{end,2}=nm(1:end-1);
					a=a(next:end);
					[nb,~,~,next]=sscanf(a,'%u',1);
					msgs{end,4}=nb;
					a=a(next:end);
					[ob,~,~,next]=sscanf(a,'%s',1);
					msgs{end,5}=ob;
				case 'CM_'	% ?config / comment?
				case 'VAL_TABLE_'
					a=strtrim(a(i_+1:end));
					[nm,~,~,next]=sscanf(a,'%s',1);
					a=a(next:end);
					X.VAL_TABLE(1,end+1).name=nm;
					X.VAL_TABLE(end).values=ReadValues(a);
				case 'VAL_'
					a=strtrim(a(i_+1:end));
					[id,~,~,next]=sscanf(a,'%u',1);
					a=a(next+1:end);
					[nm,~,~,next]=sscanf(a,'%s',1);
					a=a(next+1:end);
					X.VAL(1,end+1).ID=id;
					X.VAL(1,end).signal=nm;
					X.VAL(end).values=ReadValues(a);
				otherwise
					%fprintf('onbekende code %s\n',a);
			end
		case 1	% ns
		case 2	% bo
			bSigned = [];	% unknown
			bBigEndian = [];	% unknown
			[nm,~,~,next]=sscanf(a,'%s',1);
			if ~strcmp(nm,'SG_')
				warning(['onbekende info bij "BO_" (' nm ')'])
				continue;
			end
			M='';
			a=a(next:end);
			[nm,~,~,next]=sscanf(a,'%s',1);
			a=a(next:end);
			if nm(end)==':'
				nm(end)='';
			else
				[xx,~,~,next]=sscanf(a,'%s',1);
				a=a(next:end);
				if ~strcmp(xx,':')
					M=xx;
					[xx,~,~,next]=sscanf(a,'%s',1);
					a=a(next:end);
				end
				if ~strcmp(xx,':')
					warning('verkeerde vorm signaal-info')
					continue
				end
			end
			[binfo,~,~,next]=sscanf(a,'%d|%d',2);
			a=a(next:end);
			[bextra,~,~,next]=sscanf(a,'%s',1);
			if length(bextra)==3 && bextra(1)=='@'
				bSigned = bextra(3)=='-';
				bBigEndian = bextra(2)=='0';
			else
				bBigEndian = false;
				warning('extra signal-info not as expected! ("%s")',bextra)
			end
			byte=floor(binfo(1)/8);
			if bBigEndian
				bitLast = binfo(1)-binfo(2)+1;
				byteLast = floor(bitLast/8);
				if byteLast<byte
					byteLast = 2*byte-byteLast;
				end
			else
				byteLast = floor((binfo(1)+binfo(2)-1)/8);
			end
			byte = byte:byteLast;
			a=a(next:end);
			[schaal,~,~,next]=sscanf(a,' (%g,%g) [%g|%g]',4);
			a=a(next:end);
			[unit,~,~,next]=sscanf(a,'%s',1);
			if ~isempty(unit)&&strcmp(unit([1 end]),'""')
				unit=unit(2:end-1);
			end
			a=a(next:end);
			[ob,~,~,next]=sscanf(a,'%s',1);
			if ~isempty(msgs{end,3})
				nmPrev = msgs{end,3}(end).signal;
				if endsWith(nmPrev,'_high','IgnoreCase',true)	...
						&& endsWith(nm,'_low','IgnoreCase',true)		...
						&& strncmpi(nm,nmPrev,length(nm)-4)
					link1 = struct('link',length(msgs{end,3})+[0 1]	...
						,'factor',[1;1]	...
						,'name',nm(1:end-4));
					if isempty(msgs{end,7})
						msgs{end,7} = link1;
					else
						msgs{end,7}(1,end+1) = link1;
					end
				elseif endsWith(nmPrev,'_low','IgnoreCase',true)	...
						&& endsWith(nm,'_high','IgnoreCase',true)		...
						&& strncmpi(nm,nmPrev,length(nm)-5)
					link1 = struct('link',length(msgs{end,3})+[0 1]	...
						,'factor',[1;1]	...
						,'name',nm(1:end-5));
					if isempty(msgs{end,7})
						msgs{end,7} = link1;
					else
						msgs{end,7}(1,end+1) = link1;
					end
				end
			end
			msgs{end,3}(end+1)=struct('signal',nm,'M',M,'byte',byte,'bit',binfo'	...
				,'bitorder',bextra,'bSigned',bSigned,'bBigEndian',bBigEndian	...
				,'scale',schaal','unit',unit,'ob',ob);
	end
end
fclose(fid);

function values=ReadValues(a)
values=cell(20,2);
nV=0;
i=1;
while i<length(a)
	[v,cnt,err,next]=sscanf(a(i:end),'%g',1);
	if cnt==0
		warning('Problem interpreting values?! (%s)',err)
		break
	end
	nV=nV+1;
	values{nV}=v;
	i=i+next;
	if a(i)=='"'	% ?always?
		i=i+1;
		i1=i;
		while i<=length(a)&&a(i)~='"'
			if a(i)=='\'	% possible?
				i=i+1;
			end
			i=i+1;
		end
		label=a(i1:i-1);
		i=i+1;
		while i<length(a)&&a(i)==' '
			i=i+1;
		end
	else
		[label,~,~,next]=sscanf(a(i:end),'%s',1);
		i=i+next;
	end
	if ~isempty(label)&&label(end)==';'
		label=label(1:end-1);
		warning('unexpected end?')
	end
	values{nV,2}=label;
end
values=values(1:nV,:);
