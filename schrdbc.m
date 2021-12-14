function schrdbc(ids,fn)
% SCHRDBC  - Schrijf DBC-file
%   schrdbc(ids,fn)

%!!!!!!!erg eenvoudig vanuit een andere DBC-file gehaald

fid=fopen(fn,'wt');
if fid<3
	error('Kan file niet openen')
end

head={'VERSION "HIPBNYYYYYYYYYYYYYYYYYYYYYYYYYYYNNNNNNNNNN/4/%%%/4/''%**4NNN///"',	...
	'','','NS_ : ','	NS_DESC_','	CM_','	BA_DEF_','	BA_','	VAL_','	CAT_DEF_',	...
	'	CAT_','	FILTER','	BA_DEF_DEF_','	EV_DATA_','	ENVVAR_DATA_','	SGTYPE_',	...
	'	SGTYPE_VAL_','	BA_DEF_SGTYPE_','	BA_SGTYPE_','	SIG_TYPE_REF_',	...
	'	VAL_TABLE_','	SIG_GROUP_','	SIG_VALTYPE_','	SIGTYPE_VALTYPE_','',	...
	'BS_:','','BU_: Vector__XXX TOOL TCU'};
S0=struct('signal',{'B0','B1','B2','B3','B4','B5','B6','B7'}	...
	,'byte',{1,2,3,4,5,6,7,8},'bit',{255,255,255,255,255,255,255,255}	...
	,'scale',{1,1,1,1,1,1,1,1});

for i=1:length(head)
	fprintf(fid,'%s\n',head{i});
end

for i=1:length(ids)
	str=ids(i).structure;
	nu='TCU';	%%!!!
	suse='TOOL';	%%!!!
	if isempty(str)
		nb=8;	%!!!!
		str=S0;
	else
		nb=max(cat(2,str.byte));
	end
	fprintf(fid,'\nBO_ %d %s: %d %s\n',ids(i).ID,ids(i).naam,nb,nu);
	bit1=zeros(length(str),1);
	nbit=bit1;
	for j=1:length(str)
		b1=min(str(j).bit);
		bit1(j)=(min(str(j).byte)-1)*8+b1;
		nbit(j)=max(str(j).bit)-b1+1;
	end
	[bit1,j]=sort(-bit1);
	bit1=-bit1;
	nbit=nbit(j);
	str=str(j);
	for j=1:length(str)
		if strcmp(lower(str(j).signal),'r_imotc')
			order=1;	%!!!breakpoint-setting
		end
		order=1;
		if length(str(j).byte)>1
			if any(diff(str(j).byte))<0
				order=0;	%????juist!!!
			end
		end
		if str(j).scale<0
			sig='-';
		else
			sig='+';
		end
		fprintf(fid,' SG_ %s : %d|%d@%d%c ',str(j).signal,bit1(j),nbit(j),order,sig);
		off=0;
		if isfield(str,'offset')
			off=str(j).offset;
		end
		fprintf(fid,'(%g,%g) ',str(j).scale,off);
		if isfield(str(j),'lim')
			lim=str(j).lim;
		elseif sig=='-'
			lim=[-2^(nbit(j)-1) 2^(nbit(j)-1)-1]*str(j).scale;
		else
			lim=[0 (2^nbit(j)-1)*str(j).scale];
		end
		fprintf(fid,'[%g|%g] ',lim);
		dim='';
		if isfield(str(j),'dim')
			dim=str(j).dim;
		end
		fprintf(fid,'"%s"  %s\n',dim,suse);
	end
end

fprintf(fid,'\n\n');
% het volgende is niet nodig!!
tail={'CM_ BU_ TOOL "VDT Display Tool";','CM_ BU_ TCU "HCVT CONTROL UNIT";'	...
	,'CM_ BO_ 898 "TB HEV T-CAR";'};
for i=1:length(tail)
	fprintf(fid,'%s\n',tail{i});
end
for i=1:length(ids)
	str=ids(i).structure;
	if ~isempty(str)&isfield(str,'comment')
		for j=1:length(str)
			if ~isempty(str(j).comment)
				fprintf(fid,'CM_ SG_ %d %s "%s";\n',ids(i).ID,str(j).signal,str(j).comment);
			end
		end
	end
end

fclose(fid);
