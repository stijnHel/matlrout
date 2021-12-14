function D=leesvrml(fn)
%LEESVRML - Leest vrml-files

global UnKnownKW

if ~iscell(UnKnownKW)
	UnKnownKW={};
end

B_METHAAKJES=false;
B_ZONDERTYPE=true;
B_ZONDERSOORTNR=true;

fid=fopen(fn);
if fid<3
	error('Kan file niet openen')
end

l1=fgetl(fid);	%#VRML V2.0 utf8

D={'file',fn,0,0};	% {type,data,soortdata,typenummer}
%     soortdata :
%         <0 : error
%                 -1 getal waar niet bedoeld
%                 -2 verkeerde structuur
%          1 : [
%          2 : {
%          6 : ]
%          7 : }
%         10 : data
%         11 : object
D{1000,1}=[];
nD=1;
l='';
iLeesData=0;

bNumber=logical(zeros(1,255));	% (matlab5.2 compatibiliteit)
bNumber(abs('01234567890.-'))=true;
bNumberDel=bNumber;
bNumberDel([abs('eE, ') 9])=true;
bKeyword=logical(zeros(1,255));
bKeyword([abs('a'):abs('z') abs('A'):abs('Z')])=true;

KeyWords={	... (naam, leesData)
	'worldinfo',1;	% 1, WorldInfo {title "Matlab-VRML"}
	'title',1;	% 2
	'navigationinfo',1;	% 3
	'headlight',1;	% 4
	'type',1;	% 5
	'background',1;	% 6
	'skycolor',1;	% 7
	'transform',1;	% 8
	'scale',1;	% 9
	'children',1;	% 10
	'viewpoint',1;	% 11
	'position',1;	% 12
	'fieldofview',1;	% 13
	'orientation',1;	% 14
	'description',1;	% 15
	'shape',1;	% 16
	'geometry',0;	% 17, geometry IndexedLineSet {, geometry Text {
	'coord',0;	% 18
	'point',1;	% 19
	'coordindex',1;	% 20
	'color',1;	% 21
	'colorPervertex',1;	% 22
	'translation',1;	%23
	'string',1;	% 24
	'fontstyle',1;	% 25
	'size',1;	% 26
	'justify',1;	% 27
	'colorpervertex',1;	% 28
	'indexedlineset',1;
	'coordinate',1;
	'text',1;
	'indexedfaceset',1;
	'solid',1;
	'def',2;
	'use',2;
	'sphere',1;
	'radius',1;
	'appearance',1;
	'material',1;
	'diffusecolor',1;
	'box',1;
	};
bWarnNumKW=true;
nSluitVerkeerd=0;
TESTNDmax=0;
lNr=1;

iStoreCols=1:4;
if B_ZONDERTYPE
	iStoreCols(iStoreCols==3)=[];
end
if B_ZONDERSOORTNR
	iStoreCols(iStoreCols==4)=[];
end

% Leest eerst naar een vlakke cell-array
while ~feof(fid)
	TESTNDmax=max(TESTNDmax,nD);
	if isempty(l)
		l=deblank(fgetl(fid));
		lNr=lNr+1;
	end
	if ~isempty(l)
		while l(1)==' '|l(1)==9
			l(1)='';
		end
		[w1,n,errstr,nxt]=sscanf(l,'%s',1);
		i_l=nxt-1;
		if iLeesData
			d=[];
			if iLeesData==2
				d=w1;
				iLeesData=0;
			elseif l(1)=='['
				iLeesData=~strcmp(D{nD,1},'children');
				i_l=1;
				nD=nD+1;
				D{nD,1}='[';
				D{nD,2}=[];
				D{nD,3}=1;
				D{nD,4}=[];
			elseif l(1)=='{'
				iLeesData=0;
				i_l=1;
				nD=nD+1;
				D{nD,1}='{';
				D{nD,2}=[];
				D{nD,3}=2;
				D{nD,4}=[];
			elseif bNumber(abs(l(1)))
				i=find(~bNumberDel(abs(l)));
				if isempty(i)
					i_l=length(l);
				else
					i_l=i(1)-1;
				end
				d=str2num(l(1:i_l));
			elseif w1(1)=='"'
				i=find(l(2:end)=='"');
				if isempty(i)
					error('Er wordt vanuit gegaan dat strings geen meerdere lijnen mogen bevatten')
				end
				d=l(2:i(1));
				i_l=i(1)+1;
			elseif strcmp(lower(w1),'true')
				d=logical(1);	% not just true because of Matlab5.2
			elseif strcmp(lower(w1),'false')
				d=logical(0);
			else
				iLeesData=0;	% ?OK?
				i_l=0;
			end
			if ~isempty(d)
				bToegevoegd=false;
				if isempty(D{nD,2})
					D{nD,2}=d;
					bToegevoegd=true;
				elseif isnumeric(D{nD,2})&isnumeric(d)
					if size(D{nD,2},2)==size(d,2)
						D{nD,2}(end+1:end+size(d,1),:)=d;
						bToegevoegd=true;
					end
				elseif ischar(D{nD,2})&ischar(d)
					D{nD,2}=strvcat(D{nD,2},d);
					bToegevoegd=true;
				end
				if ~bToegevoegd
					if iscell(D{nD,2})
						D{nD,2}{end+1}=d;
					else
						D{nD,2}={D{nD,2},d};
					end
				end
			end	% ~empty(d)
		elseif l(1)==']'|l(1)=='}'
			nD=nD+1;
			D{nD,1}=l(1);
			i_l=1;
			D{nD,2}=[];
			D{nD,3}=6+(w1=='}');
			D{nD,4}=[];
			i=findStructPt(D,nD-1);
			if i==0
				warning('Sluitend haakje zonder opening (lijn %d)?',lNr)
			else
				j=iStoreCols;
				if B_METHAAKJES
					i_lijst=i:nD;
				else
					i_lijst=i+1:nD-1;
					if ~isempty(D{i,2})
						if i-nD>1
							warning('!!!combinatie van verschillende soorten data (lijn %d)??!!',lNr)
						else
							i_lijst=i;
							j=2;
						end
					end
				end
				D1=D(i_lijst,j);
				if numel(D1)==1
					D1=D1{1};
				end
				if D{i,3}~=D{nD,3}-5
					nSluitVerkeerd=nSluitVerkeerd+1;
					if nSluitVerkeerd<3
						warning('!verkeerd sluitend haakje (lijn %d)!',lNr)
					end
				else
					if isempty(D{i-1,2})
						D{i-1,2}=D1;
					elseif iscell(D{i-1,2})&min(size(D{i-1,2}))==1
						D{i-1,2}{end+1}=D1;
						warning('Toevoegen van data op onverwachte manier (lijn %d)!!',lNr)
					else
						D{i-1,2}={D{i-1,2},D1};
						warning('Toevoegen van data op onverwachte manier (lijn %d)!!',lNr)
					end
					nD=i-1;
				end
			end	% overeenkomend haakje gevonden
		elseif l(1)=='['|l(1)=='{'
			i_l=0;	% waarom wordt dit aanzien als leesData???
			iLeesData=1;
		elseif bNumber(abs(w1(1)))
			iLeesData=1;
			i_l=0;
			if bWarnNumKW
				nD=nD-1;
				bWarnNumKW=false;
				warning(sprintf('!!getal als keyword (lijn %d)??!!',lNr))
			end
		else
			if ~all(bKeyword(abs(w1)))
				i=find(~bKeyword(abs(w1)));
				if i(1)==1
					warning('???keyword begint met "verboden teken" (lijn %d)???',lNr)
				else
					i_l=i(1)-1;
					w1=w1(1:i_l);
				end
			end
			nD=nD+1;
			D{nD,1}=w1;
			D{nD,2}=[];
			D{nD,3}=[];
			D{nD,4}=[];
			i=strmatch(lower(w1),KeyWords(:,1),'exact');
			if isempty(i)
				i=strmatch(lower(w1),UnKnownKW,'exact');
				if isempty(i)
					UnKnownKW{end+1}=lower(w1);
				end	% al bekend onbekend keyword
			else
				iLeesData=KeyWords{i,2};
				D{nD,4}=i;
			end
		end	% not iLeesData
		l=l(i_l+1:end);
	end	% not empty
end	% while not feof(fid)
fclose(fid);
D=D(1:nD,iStoreCols);
%fprintf('Maximale nD : %d\n',max(TESTNDmax,nD))

function i=findStructPt(D,i);
while i
	if D{i,3}>0&D{i,3}<5
		return
	end
	i=i-1;
end
