function [A,namen,dim,BB,gegs,str,err] = leesmusy(naam,start,Lengte,ongeschaald,kanalen,i1)
% LEESMUSY - leest data van het MUSICS-systeem. (opvolger van leesmusi)
%    [A,namen,dim,BB,gegs,str,err] = leesmusy(naam,start,lengte,ongeschaald,kanalen)

% er wordt niet getest op totaal lengte
% bij lezen van namen wordt laatste comma niet gelezen
global EVDIR

if ~exist('naam');naam=[];end
if ~exist('start');start=[];end
if ~exist('Lengte');Lengte=[];end
if ~exist('ongeschaald');ongeschaald=[];end
if ~exist('kanalen');kanalen=[];end
if ~exist('i1');i1=[];end

dag=[];maand=[];jaar=[];uur=[];minu=[];sec=[];

info=0;
if ~isstr(naam)
	if naam>0
		naam=sprintf('c%03dd01.raw',naam);
	elseif naam<0
		[A,namen,dim,BB,gegs,str,err]=leesmusy(sprintf('%07d',-naam));
		return
	else
		error('leesmusy(0) is niet mogelijk');
	end
elseif strcmp(naam,'info')
	info=1;
	naam=start;
	start=Lengte;
	Lengte=ongeschaald;
	ongeschaald=kanalen;
	kanalen=i1;
elseif isdir([EVDIR naam])
	direc=dir([EVDIR naam]);
	A={};
	namen={};
	dim={};
	dts=[];
	nk=0;
	gegs=[];
	for i=1:length(direc)
		if ~direc(i).isdir
			[a1,n1,d1,BB,g1,str,err]=leesmusy([naam '\' direc(i).name]);
			if isempty(gegs)
				gegs=g1;
			else
				gegs(11)=gegs(11)+g1(11);
			end
			nk=nk+size(a1,2)-1;
			nieuwe=0;
			if isempty(dts)
				nieuwe=1;
			else
				j=find(dts==a1(2,1));
				if isempty(j)
					nieuwe=1;
				end
			end
			if nieuwe
				A{end+1}=a1;
				namen{end+1}=n1;
				dim{end+1}=d1;
				dts(end+1)=a1(2,1);
			else
				if size(a1,1)>size(A{j},1)
					fprintf('van kanaal %d %d van de %d meetpunten weggehaald\n',nk,size(a1,1)-size(A{j},1),size(a1,1));
					a1(size(A{j},1)+1:end,:)=[];
				elseif size(a1,1)<size(A{j},1)
					fprintf('%d van de %d meetpunten weggehaald\n',size(A{j},1)-size(a1,1),size(a1,1));
					A{j}(size(a1,1)+1:end,:)=[];
				end
				A{j}=[A{j} a1(:,2:end)];
				namen{j}=addstr(namen{j},n1(2:end,:));
				dim{j}=addstr(dim{j},d1(2:end,:));
			end
		end
	end
	if (length(A)==1)|1
		A=A{1};
		namen=namen{1};
		dim=dim{1};
	end
	gegs=[gegs(1:18) ones(1,gegs(11)) zeros(1,gegs(11))];
	return
end

if isempty(start)
	start=0;
end
if isempty(Lengte)
	Lengte=10000000;
end
if ~exist([EVDIR naam])&~any(naam=='.')
	if exist([EVDIR naam '.raw'])==2
		naam=[naam '.raw'];
	else
		disp('File niet gevonden');
		err=-1;
		gegs=[];
		str='';
		BB=[];
		return;
	end
end		
A=[];

fid=fopen([EVDIR naam]);
if fid==-1
% errordlg('File niet gevonden');
	disp('File kan niet geopend worden');
	err=-1;
	gegs=[];
	str='';
	BB=[];
	return;
end
c=0;
i=0;
while c~=124
	i=i+1;
	c=fread(fid,1,'char');
	if feof(fid)|i>20
		fclose(fid);
		fprintf('File is leeg of van het verkeerde type\n');
		namen='';
		dim='';
		BB=[];
		gegs=[];
		str=[];
		err=1;
		return
	end
end
if nargout>=4
	BB=[];
end
mogelijkheden='CF,';
nietlezen='CS,';	% data wordt in verwerking van key zelf gelezen
namen='';
xunit='';
dim='';
ts=[];
if isempty(ongeschaald)
	ongeschaald=0;
end
iNr=1;
iSoort=2;
iIndexSamplesKey=3;
iOffsetBufferInSamplesKey=4;
iBufferLengthBytes=5;
iOffsetFirstSampleInBuffer=6;
iBufferFilledBytes=7;
iBytes=8;
iNumberFormat=9;
iSignBits=10;
iMask=11;
iOffset=12;
iDirectSequenceNumber=13;
iIntervalBytes=14;
iAna=15;
iDimensie=16;
iNumberComp=17;
iFieldType=18;
iDx=19;
iDxCalib=20;
iTransformation=21;
iGain=22;
iScOffset=23;
iCalibrated=24;
iNaam=25;
iDim=26;
volgorde=[];
DataGegs=zeros(0,iDim);
rawdatablock=0;
while ~feof(fid)
	s=setstr(fread(fid,3,'char')');
	if info
		fprintf('%3s ',s);
	end
	if isempty(findstr(mogelijkheden,s))
		if info
			fprintf('Er loopt iets fout met de volgorde (%s en niet %s)\n',s,mogelijkheden);
		end
	end
	versie=lees1get(fid,',');
	lengte=lees1get(fid,',');
	if isempty(findstr(nietlezen,s))
		sf=setstr(fread(fid,lengte,'uchar')');
		% else 	 data wordt in verwerking van key zelf gelezen
	end
	switch s(1)
	case 'C'
		switch s(2)
		case 'F' % file format
			if versie~=2
				fclose(fid);
				error(sprintf('versie twee verwacht voor file formaat ipv %d',versie));
			elseif lengte~=1
				fclose(fid);
				error('lengte moest 1 zijn bij fileformaat');
			end
			p=sf(1);
			if p~='1'
				fclose(fid);
				error(sprintf('ik verwachtte een processor = 1 ipv %c',p));
			end
			if info
				fprintf('Processor OK\n');
			end
			mogelijkheden='CK,';
		case 'K' % finished
			if versie~=1
				fclose(fid);
				error(sprintf('versie 1 verwacht voor start a group of keys ipv %d',versie));
			elseif lengte~=3
				fclose(fid);
				error('lengte moest 3 zijn bij group of keys');
			end
			p=sf(1:3);
			if ~strcmp(p(1:2),'1,')
				fclose(fid);
				error('ik verwachtte voor group of keys "1,x"');
			end
			if info
				if p(3)=='1'
					fprintf('group of keys finished correctly\n');
				elseif p(3)=='0'
					fprintf('group of keys not finished correctly\n');
				else
					fclose(fid);
					error('Verkeerde start group of keys');
				end
			end
			mogelijkheden='NO,CT,CB,CG,';
		case 'B' % group definition
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor group definition')
			end
			[index,ng,sf]=lees1get(sf,',');
			[namel,ng,sf]=lees1get(sf,',');
			name=sf(1:namel);
			c=sf(namel+1);
			if c~=','
				fclose(fid);
				error(', verwacht');
			end
			[comml,ng,sf]=lees1get(sf(namel+2:length(sf)),',');
			comm=sf(1:comml);
			if info
				fprintf('groep %s : , %s\n',name,comm);
			end
			mogelijkheden='CG,Cb,';
		case 'T' % definition of text
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor text')
			end
			[index,ng,sf]=lees1get(sf,',');
			[namel,ng,sf]=lees1get(sf,',');
			name=sf(1:namel);
			c=sf(namel+1);
			if c~=','
				fclose(fid);
				error(', verwacht');
			end
			[tekstl,ng,sf]=lees1get(sf(namel+2:length(sf)),',');
			tekst=sf(1:tekstl);
			c=sf(tekstl+1);
			if c~=','
				fclose(fid);
				error(', verwacht');
			end
			[comml,ng,sf]=lees1get(sf(tekstl+2:length(sf)),',');
			comm=sf(1:comml);
			if info
				fprintf('text %d\n   %s\n   %s\n   %s\n',index,name,tekst,comm);
			end
			mogelijkheden='CB,CT,NO,Cb,';
		case 'G' % definition of data field, start of a group
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor group')
			end
			[numberComp,ng,sf]=lees1get(sf,',');
			[fieldtype,ng,sf]=lees1get(sf,',');
			nc=[1 2 2 2 2 2];
			if info
				switch fieldtype
				case 1
					fprintf('real, ');
				case 2
					fprintf('XY, x monotonous increasing, ');
				case 3
					fprintf('XY, x charac curve, ');
				case 4
					fprintf('complex, R,I, ');
				case 5
					fprintf('complex, A,f, ');
				case 6
					fprintf('complex, dB, f, ');
				end
			end
			[dimensie,ng,sf]=lees1get(sf);
			if nc(fieldtype)~=dimensie
				fprintf('dimensie is anders dan verwacht (%d ipv %d)\n',dimensie,nc(fieldtype));
			end
			if info
				fprintf('dimensie %d, nCompon %d\n',dimensie,numberComp);
			end
			iComp=0;
			DataGegs(end+1,[iFieldType iDimensie iNumberComp iNaam iDim])=[fieldtype dimensie numberComp size(namen,1)+1 size(dim,1)+1];
			mogelijkheden='CD,NT,CC,Cb,';
		case 'D' % scaling
			if (versie<1)|(versie>2)
				fclose(fid);
				error(sprintf('versie 1 of 2 verwacht voor scaling ipv %d',versie))
			end
			[dx,ng,sf]=lees1get(sf,',');
			ts=[ts;dx];
			[calibrated,ng,sf]=lees1get(sf,',');
			if info
				if calibrated==0
					fprintf('not calibrated, ');
				elseif calibrated==1
					fprintf('time base calibrated (dx=%g), ',dx);
				else
					fprintf('?????????????, ');
				end
			end
			[ul,ng,sf]=lees1get(sf,',');
			unit=sf(1:ul);
			xunit=unit;
			if info
				fprintf('%s\n',unit);
			end
			switch versie
				case 1
					if ~strcmp(sf(3:length(sf)),'0,0,0')
						fprintf('toch iets fout met scaling (%s)\n',sf);
					end
				case 2
					if length(find(sf(3:end)==','))~=4
						fclose(fid);
						error('scaling toch iets anders dan verwacht');
					end
			end
			DataGegs(end,[iDx iDxCalib])=[dx calibrated];
			mogelijkheden='NT,CC,Cb,';
		case 'C' % start of a component
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor scaling')
			end
			iComp=iComp+1;
			if iComp>numberComp
				fprintf('Meer components dan verwacht.\n');
			end
			[compIndex,ng,sf]=lees1get(sf,',');
			ad=lees1get(sf);
			if info
				fprintf('comp #%2d index : %1d, ',iComp,compIndex);
				if ad==1
					fprintf('analoog\n');
				elseif ad==2
					fprintf('digitaal\n');
				else
					fprintf('iets fout met A/D\n');
				end
			end
			if DataGegs(end,iAna)
				DataGegs(end+1,[iAna iNaam iDim])=[ad size(namen,1)+1 size(dim,1)+1];
				DataGegs(end,[iFieldType iDimensie iNumberComp])=	...	gegevens horen tot zelfde
					DataGegs(end-1,[iFieldType iDimensie iNumberComp]);	% groep
			else
				DataGegs(end,iAna)=ad;
			end
			mogelijkheden='CD,CC,NT,CP,Cb,';	% (?CC?)
		case 'P' % packet information
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor scaling')
			end
			[bufferReference,ng,sf]=lees1get(sf,',');
			[bytes,ng,sf]=lees1get(sf,',');
			[numberFormat,ng,sf]=lees1get(sf,',');
			[signBits,ng,sf]=lees1get(sf,',');
			[mask,ng,sf]=lees1get(sf,',');
			[offset,ng,sf]=lees1get(sf,',');
			[directSequenceNumber,ng,sf]=lees1get(sf,',');
			[intervalBytes,ng,sf]=lees1get(sf,',');
			if info
				fprintf('packet info : #%d, %d bytes, ',bufferReference,bytes);
				switch numberFormat
				case 1
					fprintf('unsigned byte, ');
				case 2
					fprintf('signed byte, ');
				case 3
					fprintf('unsigned short, ');
				case 4
					fprintf('signed short, ');
				case 5
					fprintf('unsigned long, ');
				case 6
					fprintf('signed long, ');
				case 7
					fprintf('float, ');
				case 8
					fprintf('double, ');
				case 11
					fprintf('2-byte-word digital, ');
				otherwise
					fprintf('onbekend formaat, ');
				end
				fprintf('%d bits, mask=%d,\n    offset=%d, direct : %d, intervalbytes = %d\n',   ...
				signBits,mask,offset,directSequenceNumber,intervalBytes);
			end
			if DataGegs(end,iNr)
				if DataGegs(end,iNr)~=bufferReference
					fclose(fid);
					error('Er loopt iets fout met de bufferReference (Cb)');
				end
			else
				DataGegs(end,iNr)=bufferReference;
			end
			DataGegs(end,[iBytes iNumberFormat iSignBits iMask iOffset iDirectSequenceNumber iIntervalBytes])=	...
				[bytes numberFormat signBits mask offset directSequenceNumber intervalBytes];
			mogelijkheden='CR,ND,CN,CS,CC,CC,CT,CB,CG,Cb,';
		case 'b' % buffer description
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor scaling')
			end
			[numberBufferInKey,ng,sf]=lees1get(sf,',');
			if (numberBufferInKey~=numberComp)
				fprintf('!!Een andere numberBufferInKey dan verwacht (%d ipv %d)\n',numberBufferInKey,numberComp);
			end
			[bytesInUserInfo,ng,sf]=lees1get(sf,',');
			if bytesInUserInfo~=0
				fprintf('!!toch bytesInUserInfo!!\n');
			end
			for i=1:numberBufferInKey
				[bufferReference,ng,sf]=lees1get(sf,',');
				[indexSamplesKey,ng,sf]=lees1get(sf,',');
				[offsetBufferInSamplesKey,ng,sf]=lees1get(sf,',');
				[bufferLengthBytes,ng,sf]=lees1get(sf,',');
				[offsetFirstSampleInBuffer,ng,sf]=lees1get(sf,',');
				[BufferFilledBytes,ng,sf]=lees1get(sf,',');
				if ~strcmp(sf(1:6),'0,0,0,')
					[a1,ng,sf]=lees1get(sf,',');
					[a2,ng,sf]=lees1get(sf,',');
					[a3,ng,sf]=lees1get(sf,',');
					if info
						fprintf('fout bij lezen van buffer description (geen 0,0,0, maar %g,%g,%g)\n',a1,a2,a3);
					end
				else
					sf(1:6)='';
				end
				userinfo=sf(1:bytesInUserInfo);
				if ~isempty(sf)
					sf(1:bytesInUserInfo+1)='';
				end
				j=find(DataGegs(:,iNr)==bufferReference);
				if isempty(j)
					fprintf('Het komt dus toch voor dat Cb nieuwe kanalen "definieert".\n');
					if DataGegs(end,iNr)
						j=size(DataGegs,1)+1;
					else
						j=size(DataGegs,1);
					end
					DataGegs(j,iNr)=bufferReference;
				end
				DataGegs(j,iIndexSamplesKey)=indexSamplesKey;
				DataGegs(j,iOffsetBufferInSamplesKey)=offsetBufferInSamplesKey;
				DataGegs(j,iBufferLengthBytes)=bufferLengthBytes;
				DataGegs(j,iOffsetFirstSampleInBuffer)=offsetFirstSampleInBuffer;
				DataGegs(j,iBufferFilledBytes)=BufferFilledBytes;
				if indexSamplesKey~=1
					warning('Meerdere CS-keys zijn slechts in ontwikkeling!!!!!');
				end
				if info
					fprintf('buffer description #%d : index %d, offset %d, lengte %d, offset first %d, filled bytes %d, "%s\n', ...
					bufferReference,indexSamplesKey,offsetBufferInSamplesKey, ...
					bufferLengthBytes,offsetFirstSampleInBuffer,BufferFilledBytes,[userinfo '"']);
				end
			end % for i
			mogelijkheden='CS,CC,CR,Cb,';	% ??Cb
		case 'R' % value range
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor scaling')
			end
			[transformation,ng,sf]=lees1get(sf,',');
			[factor,ng,sf]=lees1get(sf,',');
			[offset,ng,sf]=lees1get(sf,',');
			[calibrated,ng,sf]=lees1get(sf,',');
			[unitl,ng,sf]=lees1get(sf,',');
			unit=sf(1:unitl);
			if isempty(unit)
				unit='#';
			end
			dim=addstr(dim,unit);
			if info
				if transformation
					fprintf('do transformation, ');
				else
					fprintf('raw data, ');
				end
				fprintf('factor,offset = %g,%g, ',factor,offset);
				if calibrated
					fprintf('calibrated, ');
				else
					fprintf('not calibrated, ');
				end
				fprintf('[%s]\n',unit);
			end
			DataGegs(end,[iTransformation iGain iScOffset iCalibrated])=	...
				[transformation,factor,offset,calibrated];
			mogelijkheden='CN,CC,Cb,';
		case 'N' % name, comment about channel
			if versie~=1
				fclose(fid);
				error(sprintf('versie 1 verwacht voor scaling ipv %d',versie))
			end
			[indexGroup,ng,sf]=lees1get(sf,',');
			[i,ng,sf]=lees1get(sf,',');
			if i~=0
				fclose(fid);
				error('Ik verwachtte een nul in "CN" na indexGroup\n');
			end
			[i,ng,sf]=lees1get(sf,',');
			[namel,ng,sf]=lees1get(sf,',');
			name=sf(1:namel);
			%!!!if digital data meerdere keren mogelijk!!!!
			namen=addstr(namen,name);
			c=sf(namel+1);
			if c~=','
				fclose(fid);
				error(', verwacht');
			end
			[comml,ng,sf]=lees1get(sf(namel+2:length(sf)),',');
			comm=sf(1:comml);
			if info
				fprintf('# %d, %s, %s\n',indexGroup,name,comm);
			end
			mogelijkheden='NU,Cb,CG,CB,CT,CS,';	% !!Normaal zou CN ook kunnen
		case 'S' % samples
			if versie~=1
				fclose(fid);
				error('versie 1 verwacht voor samples')
			end
			rawdatablock=rawdatablock+1;
			filep=ftell(fid);
			[indexGroup,ng]=lees1get(fid,',');
			if info
				fprintf('data # %d (lengte=%d)\n',indexGroup,lengte-ng);
			end
			if indexGroup~=rawdatablock
				fprintf('indexGroup verschillend van verwachte waarde (%d ipv %d)\n',indexGroup,rawdatablock)
			elseif indexGroup>1
				fprintf('Meerdere sample-blokken. Dit werd nog niet getest!!\n');
			end
			filepos=filep+ng;
			lens=DataGegs(:,iBufferFilledBytes)./(DataGegs(:,iBytes)+DataGegs(:,iIntervalBytes));
			if isempty(ts)
				% Dit is nu helemaal afzonderlijk gedaan.  Mogelijk kunnen er meer
				% gemeenschappelijke delen komen
				if max(lens)~=min(lens)
					fprintf('lengtes :');fprintf(' %d',lens);fprintf('\n');
					warning('Alle kanalen waren niet even lang!!! sommige zijn ingekort');
					lens(:)=min(lens);
				end
				if isempty(A)
					A=zeros(min(Lengte,lens(1)-start),size(namen,1));
					k=0;
				elseif size(A,1)==min(Lengte,lens(1)-start)
					k=size(A,2);
				else
					fclose(fid);
					error('Verschillende lengtes voor verschillende groepen nog niet geimplementeerd')
				end
				l=find(DataGegs(:,3)==DataGegs(end,3));
				for i=1:length(l)
					nb=DataGegs(1,iBytes);
					fseek(fid,filepos+DataGegs(i,iOffsetBufferInSamplesKey)+start*nb+DataGegs(i,iOffset),'bof');
					switch DataGegs(i,iNumberFormat)
					case 1
						typ='uint8';
					case 2
						typ='int8';
					case 3
						typ='uint16';
					case 4
						typ='int16';
					case 5
						typ='uint32';
					case 6
						typ='int32';
					case 7
						typ='single';
					case 8
						typ='double';
					case 11
						typ='uint16';
					otherwise
						switch DataGegs(i,iBytes)
						case 1
							typ='int8';
						case 2
							typ='int16';
						case 4
							typ='int32';
						case 8
							typ='int64';
						otherwise
							fclose(fid);
							error('Onbekend type en ongewoon aantal bytes');
						end
					end
						
					A1=fread(fid,lens(i),typ,DataGegs(i,iIntervalBytes));
					if DataGegs(i,iAna)==2
						if i==size(DataGegs,1)
							j=size(namen,1);
						else
							j=DataGegs(i+1,iNaam)-1;
						end
						b=1;
						while k<j
							k=k+1;
							A(:,k)=bitand(A1,b)>0;
							dim=strvcat(dim(1:k-1,:),';OFF;ON',dim(k:end,:));
							b=b*2;
						end
					elseif ongeschaald
						k=k+1;
						A(:,k)=A1;
					else
						k=k+1;
						A(:,k)=A1*DataGegs(i,iGain)+DataGegs(i,iScOffset);
					end
				end	% for i
			else
				t1=min(ts);
				t2=max(ts);
				isnel=find(ts<t1*1.1);
				itraag=find(ts>t1*1.1);
				A=zeros(min(Lengte,max(lens(isnel))-start),length(isnel)+1);
				if ~isempty(A)
					volgorde=isnel;
					A(:,1)=(start+(0:size(A,1)-1))'*t1;
					for j=1:length(isnel)
						i=isnel(j);
						fseek(fid,filepos+DataGegs(i,iOffsetBufferInSamplesKey)+start*DataGegs(i,iBytes)+DataGegs(i,iOffset),'bof');
						len=min(lens(i)-start,Lengte);
						A1=fread(fid,lens(i),'int16',DataGegs(i,iIntervalBytes));	%!!!!!
						if ongeschaald
							A(1:lens(i),j+1)=A1;
						else
							A(1:lens(i),j+1)=A1*DataGegs(i,iGain)+DataGegs(i,iScOffset);
						end
					end	% for j
				end	% ~isempty(A)
				namen=addstr('t',namen([isnel;itraag],:));
				dim=addstr(xunit,dim([isnel;itraag],:));
				if isempty(itraag)
					BB=[];
				else
					volgorde=[volgorde;itraag];
					BB=zeros(min(Lengte,max(lens(itraag))-start),length(itraag)+1);
					if ~isempty(BB)
						BB(:,1)=(start+(0:size(BB,1)-1))'*t2;
						for j=1:length(itraag)
							i=itraag(j);
							len=min(lens(i)-start,Lengte);
							fseek(fid,filepos+DataGegs(i,iOffsetBufferInSamplesKey)+start*DataGegs(i,iBytes)+DataGegs(i,iOffset),'bof');
							A1=fread(fid,lens(i),'int16',DataGegs(i,iIntervalBytes));
							if ongeschaald
								BB(1:lens(i),j+1)=A1;	%!!!!!!
							else
								BB(1:lens(i),j+1)=A1*DataGegs(i,iGain)+DataGegs(i,iScOffset);
							end
						end	% for j
					end
				end	% ~isempty(itraag)
			end	% ~isempty(ts)
			fseek(fid,filep+lengte,'bof');
			mogelijkheden='CS,CC,CR,CG,';
		otherwise
			fclose(fid);
			error('Onverwachte kode');
		end
	case 'N'
		switch s(2)
		case 'O'
			% dit zou juist na CK moeten komen
			[origin,ng,sf]=lees1get(sf,',');
			if info
				if origin==1
					fprintf('calculated');
				else
					fprintf('original');
				end
			end
			[namel,ng,sf]=lees1get(sf,',');
			name=sf(1:namel);
			if sf(namel+1)~=','
				fclose(fid);
				error(', verwacht');
			end
			[comml,ng,sf]=lees1get(sf(namel+2:end),',');
			comm=sf(1:comml);
			if info
				fprintf(' van %s (%s)\n',name,comm);
			end
		case 'T' % trigger tijd
			[dag,ng,sf]=lees1get(sf,',');
			[maand,ng,sf]=lees1get(sf,',');
			[jaar,ng,sf]=lees1get(sf,',');
			[uur,ng,sf]=lees1get(sf,',');
			[minu,ng,sf]=lees1get(sf,',');
			[sec,ng,sf]=lees1get(sf);
			if info
				fprintf('triggertijd %02d-%02d-%04d, %02d:%02d:%5.2f\n',dag,maand,jaar,uur,minu,sec);
			end
		case 'D' % display properties
			[ColorR,ng,sf]=lees1get(sf,',');
			[ColorG,ng,sf]=lees1get(sf,',');
			[ColorB,ng,sf]=lees1get(sf,',');
			[yMin,ng,sf]=lees1get(sf,',');
			[yMax,ng,sf]=lees1get(sf);
			if info
				fprintf('kleur (%d,%d,%d), %g:%g\n',ColorR,ColorG,ColorB,yMin,yMax);
			end
		case 'U' % user-defined key
			[identLength,ng,sf]=lees1get(sf,',');
			keyWord=sf(1:identLength);
			if sf(identLength+1)~=','
				fclose(fid);
				error(', verwacht')
			end
			idenData=sf(identLength+2:end);
			if info
				fprintf('user-defined key, %s "%s"\n',keyWord,idenData);
			end
			mogelijkheden='NU,CC,CN,CN,Cb,';
		end
	otherwise
		fclose(fid);
		error(sprintf('Onbekende kode (%s)',s));
	end
	c=fread(fid,1,'char');
	if c~=';' & info
		fprintf('!!!";" werd verwacht\n');
	end
	xtest='';
	c=fread(fid,1,'char');
	while (c~='|') & ~feof(fid)
		xtest(end+1)=c;
		c=fread(fid,1,'char');
	end
	if info
		iCRLF=find((xtest==13)|(xtest==10));
		if ~isempty(iCRLF)
			xtest(iCRLF)=[];
		end
		if length(xtest)>4
			fprintf('%d karakters na key\n',length(xtest)-1);
			if length(xtest)>5
				printhex(xtest(1:end-1))
			end
		end
	end
end
fclose(fid);
if nargout>3
	datum=[dag maand jaar uur minu sec];
	if length(datum)~=6
		datum=zeros(1,6);
	end
	Nkan=size(DataGegs,1)-isempty(ts);
	isSigned=((numberFormat>6)|~rem(numberFormat,2))&(numberFormat<=8);
	Nmet=size(A,1);
	%           1 : versie
	%           2 : LPH-nummer
	%           3 : lenge van de header
	%           4 : dag
	%           5 : maand
	%           6 : jaar
	%           7 : uur
	%           8 : minuut
	%           9 : seconde
	%          10 : referentiepunt
	%          11 : aantal kanalen
	%          12 : dt
	%          13 : aantal kanalen per blok
	%          14 : resolutie (# bits)
	%          15 : (un)signed
	%          16 : lengte van de tekst
	%          17 : aantal meetpunten
	%          18 : lengte van de file
	%       1    2 3 4-6,7-9 0  1   2  3    4        5     6  7      8
	gegs=[versie 0 0 datum   0 Nkan mean(diff(A(:,1))) 0 signBits isSigned 0 Nmet filep+lengte+1 DataGegs(volgorde,iGain)' DataGegs(volgorde,iScOffset)'];
	str='';
	err=0;
end
