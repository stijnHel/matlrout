function D=ReadDBF(fName)
%ReadDBF  - Reads DBF file (dBase database)
%    D=ReadDBF(fName)
% in development!!!
%
% reference: http://www.dbf2002.com/dbf-file-format.html
%                  DBF File structure
%                    (compact nicely documented)

fid=fopen(fName);
if fid<3
	fid=fopen(zetev([],fName));
	if fid<3
		error('Can''t open the file!')
	end
end

LE=[1;256;65536;16777216];

H1=fread(fid,[1 32]);

DBFfiletypes={2,'FoxBASE';
	  2,'FoxBASE'
	  3,'FoxBASE+/Dbase III plus, no memo'
	 48,'Visual FoxPro'
	 49,'Visual FoxPro, autoincrement enabled'
	 50,'Visual FoxPro with field type Varchar or Varbinary'
	 67,'dBASE IV SQL table files, no memo'
	 99,'dBASE IV SQL system files, no memo'
	131,'FoxBASE+/dBASE III PLUS, with memo'
	139,'dBASE IV with memo'
	203,'dBASE IV SQL table files, with memo'
	245,'FoxPro 2.x (or earlier) with memo'
	229,'HiPer-Six format with SMT memo file'
	251,'FoxBASE';
	};
i=find([DBFfiletypes{:,1}]==H1(1));
if isempty(i)
	DBFfiletype='unknown';
else
	DBFfiletype=DBFfiletypes{i,2};
end
lastUpdate=datenum(H1(2)+1900,H1(3),H1(3));
nRecords=H1(5:8)*LE;
recStart=H1(9:10)*LE(1:2);
lRecord=H1(11:12)*LE(1:2);
tabFlags=H1(29);
codePageMark=H1(30);

H2=fread(fid,recStart-32);
x=fread(fid);
fclose(fid);
if length(H2)~=recStart-32
	error('Couldn''t read the record definition!')
end
if H2(end)~=13
	error('Unexpected problem reading the file - no DBF-structure?')
end
if rem(length(H2),32)~=1
	error('Problem with record definition length!')
end
H2=reshape(H2(1:end-1),32,[]);
nFields=size(H2,2);
recordDef=struct('name',cell(1,nFields),'type',[],'pos',[],'length',[]	...
	,'numDec',[],'flags',[],'next',[],'step',[],'reserved',[]);
for i=1:nFields
	recordDef(i).name=deblank(char(H2(1:11,i)'));
	recordDef(i).type=char(H2(12,i));
	recordDef(i).pos=H2(13:16,i)'*LE;
	recordDef(i).length=H2(17,i);
	recordDef(i).numDec=H2(18,i);
	recordDef(i).flags=H2(19,i);
	recordDef(i).next=H2(20:23,i)'*LE;
	recordDef(i).step=H2(24,i);
	recordDef(i).reserved=H2(25:32,i);
end
bOK=true;
if rem(length(x),lRecord)~=1
	if rem(length(x),lRecord)~=0
		warning('READDBF:lenData','No end-mark in data?')
		x(end+1)=26;
		bOK=false;
	else
		warning('READDBF:lenData','Problem with the lenght of the data part - data is truncated!')
		x=x(1:floor(length(x)/lRecord)*lRecord+1);
		bOK=false;
	end
end
x=char(reshape(x(1:end-1),lRecord,[]));
nRec=size(x,2);
if nRec~=nRecords&&bOK
	warning('READDBF:badNumRecs','Other number of records compared to header!')
end
bNumOut=all([recordDef.type]=='N');
iFields=[0 cumsum([recordDef.length])+1];
if bNumOut
	X=zeros(nRec,nFields);
	for i=1:nRec
		for j=1:nFields
			s=x(iFields(j)+1:iFields(j+1),i)';
			X(i,j)=str2double(s);
		end
	end
else
	X=cell(nRec,nFields);
	for j=1:nFields
		switch recordDef(j).type
			case 'N'
				for i=1:nRec
					s=x(iFields(j)+1:iFields(j+1),i)';
					X{i,j}=str2double(s);
				end
			case 'L'
				d=x(iFields(j+1),:);
				if any(d~='F'&d~='T')
					warning('READDBF:LogFault','Fault in logical data?')
					D=num2cell(d);
				else
					D=num2cell(d=='T');
				end
				[X{:,j}]=deal(D{:});
			case 'D'
				d = x(iFields(j)+1:iFields(j+1),:);
				if any(d<'0' | d>'9','all')
					D = num2cell(zeros(nRec,1));
					warning('No valid date-data?! (%s)',recordDef(j).name)
				else
					d=d'-'0';
					d=d*[1000 100 10 1 0 0 0 0;0 0 0 0 10 1 0 0;0 0 0 0 0 0 10 1]';
					D=num2cell(datenum(d));
				end
				[X{:,j}]=deal(D{:});
			otherwise	% not implemented(!) - just text
				for i=1:nRec
					s=deblank(x(iFields(j)+1:iFields(j+1),i)');
					X{i,j}=s;
				end
		end
	end
end

head=var2struct('DBFfiletype','lastUpdate','nRecords','recStart'	...
	,'lRecord','tabFlags','codePageMark');
D=struct('head',head,'recordDef',recordDef,'X',{X});
