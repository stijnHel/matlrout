function P=leesdcm(f)
% LEESDCM   - Leest DCM-file (data van ASCET/INCA)

fid=fopen(f,'rt');
if fid<3
	error('Kan file niet openen')
end
inblok=0;
isVlag=0;
onbblok='';
onbdata='';
P=struct('naam',{},'type',{},'value',{});
while ~feof(fid)
	l=fgetl(fid);
	if isempty(l)|l(1)=='*'
		continue;
	end
	[w1,n,err,inext]=sscanf(l,'%s',1);
	%while l(inext)==' '
	%	inext=inext+1;
	%end
	if inext<length(l)
		[w2,n,err,inext2]=sscanf(l(inext:end),'%s',1);
		inext2=inext+inext2-1;
	end
	if inblok
		switch w1
		case 'END'
			switch inblok
			case 1
				if numel(W)~=1
					warning(sprintf('!!!parameter met meerdere waarden??? (%s)',n1))
				end
				if isVlag
					t='vlag';
				else
					t='param';
				end
			case {2,7}
				t='1D';
				W=[X W];
			case 3
				t='lijst';
			case {4,5}	% kennfeld (en festkenfeld)
				t='2D';
				W=getmatr(X,Y,W');
			case 6	% functionen
				inblok=0;
				continue;
			otherwise
				fprintf('Niet opgenomen "%d".\n',inblok);
				inblok=0;
				continue;
			end
			P(end+1)=struct('naam',n1,'type',t,'value',W);
			inblok=0;
		case 'WERT'
			[v1,nval]=sscanf(l(inext:end),'%g');
			if nval==0
				switch w2
				case 'true'
					v1=1;
					isVlag=1;
				case 'false'
					v1=0;
					isVlag=1;
				otherwise
					error('onleesbare waarde')
				end
			end
			W(iw+1:iw+length(v1),iy)=v1;
			iw=iw+length(v1);
		case 'ST/X'
			v1=sscanf(l(inext:end),'%g')';
			X(ix+1:ix+length(v1))=v1;
			ix=ix+length(v1);
		case 'ST/Y'
			iw=0;
			iy=iy+1;
			v1=sscanf(l(inext:end),'%g');
			Y(iy)=v1;
		case 'FKT'
		case 'FUNKTION'
		case 'LANGNAME'
		case 'DISPLAYNAME'
		case 'TEXT'
			W=w2;
		case 'EINHEIT_W'
		case 'EINHEIT_X'
		case 'EINHEIT_Y'
		otherwise
			if isempty(fstrmat(onbdata,w1))
				onbdata=addstr(onbdata,w1);
				warning(sprintf('onbekende data (%s)',w1))
			end
		end
	elseif strcmp(w1,'FESTWERT')
		n1=w2;
		inblok=1;
		iw=0;
		iy=1;
		W=0;
		isVlag=0;
	elseif strcmp(w1,'KENNLINIE')
		n1=w2;
		grootte=sscanf(l(inext2:end),'%d');
		inblok=2;
		iw=0;
		ix=0;
		iy=1;
		W=zeros(grootte,1);
		X=W;
	elseif strcmp(w1,'FESTKENNLINIE')
		n1=w2;
		grootte=sscanf(l(inext2:end),'%d');
		inblok=7;
		iw=0;
		ix=0;
		iy=1;
		W=zeros(grootte,1);
		X=W;
	elseif strcmp(w1,'FESTWERTEBLOCK')
		n1=w2;
		grootte=sscanf(l(inext2:end),'%d');
		inblok=3;
		iw=0;
		iy=1;
		W=zeros(grootte,1);
	elseif strcmp(w1,'KENNFELD')
		n1=w2;
		grootte=sscanf(l(inext2:end),'%d');
		inblok=4;
		iw=0;	% niet nodig
		iy=0;
		ix=0;
		W=zeros(grootte');
		X=zeros(grootte(1),1);
		Y=zeros(grootte(2),1);
	elseif strcmp(w1,'FESTKENNFELD')
		n1=w2;
		grootte=sscanf(l(inext2:end),'%d');
		inblok=5;
		iw=0;	% niet nodig
		iy=0;
		ix=0;
		W=zeros(grootte');
		X=zeros(grootte(1),1);
		Y=zeros(grootte(2),1);
	elseif strcmp(w1,'KONSERVIERUNG_FORMAT')
		fprintf('formaat %s\n',w2)
	elseif strcmp(w1,'FUNKTIONEN')
		inblok=6;
	else
		if isempty(fstrmat(onbblok,w1))
			onbonbblok=addstr(onbblok,w1);
			warning(sprintf('onbekende soort (%s)',w1))
		end
		inblok=-1;
		n1='';
	end
end
fclose(fid);
