function fdif=compbinfiles(f1,f2,recurs)
% COMPBINFILES - Vergelijk binaire files

if exist(f1,'dir')
	status('Vergelijken van directories');
	d1=dirlijst(f1,recurs);
	d1=sort(d1,'name');
	status('tekst','Inlezen tweede directory')
	d2=dirlijst(f2,recurs);
	d2=sort(d2,'name');
	status
	i1=1;
	i2=1;
	missing1=[];
	missing2=[];
	equals=zeros(0,3);
	notequals=zeros(0,3);
	status('Vergelijken van files',0)
	while i1<=length(d1)&i2<=length(d2)
		ncmp=strcmpc(d1(i1).name,d2(i2).name);
		while i2<=length(d2)&ncmp>0
			missing2(end+1)=i2;
			i2=i2+1;
			if i2>length(d2)
				break;
			end
			ncmp=strcmpc(d1(i1).name,d2(i2).name);
		end
		if i2>length(d2)	% "double break" is not possible
			break;
		end
		if ncmp<0
			missing1(end+1)=i1;
		else
			if d1(i1).bytes~=d2(i2).bytes
				notequals(end+1,:)=[i1 i2 1];
			else
				fdif=compbinfiles([f1 filesep d1(i1).name],[f2 filesep d2(i2).name]);
				if fdif<=0
					equals(end+1,:)=[i1 i2 fdif<0];
				else
					notequals(end+1,:)=[i1 i2 fdif];
				end
			end	% equal length
			i2=i2+1;
		end	% equal filenames
		status(i1/length(d1))
		i1=i1+1;
	end
	status
	if i1<=length(d1)
		missing1(end+1:end+length(d1)-i1+1)=i1:length(d1);
	end
	fdif=struct('f1',f1,'f2',f2,'d1',d1,'d2',d2	...
		,'missing1',missing1,'missing2',missing2	...
		,'equals',equals,'notequals',notequals);
	return;
end
fid=fopen(f1,'r');
if fid<3
	error('kan file 1 niet openen')
end
x1=fread(fid);
fclose(fid);
fid=fopen(f2,'r');
if fid<3
	error('kan file 2 niet openen')
end
x2=fread(fid);
fclose(fid);
if length(x1)~=length(x2)
	fdif=1;
elseif isempty(x1)
	fdif=-1;
elseif any(x1~=x2)
	fdif=2;
else
	fdif=0;
end


function d=dirlijst(f,recurs)
d=dir(f);
if isempty(d)
	return;
end
%d=sort(d,'name');
i=1;
nd=strvcat(d.name);
d(nd(:,1)=='.')=[];
while i<=length(d)
	if d(i).isdir
		if recurs
			d1=dir([f filesep d(i).name]);
			nd1=strvcat(d1.name);
			d1(nd(:,1)=='.')=[];
			for j=1:length(d1)
				d1(j).name=[d(i).name filesep d1(j).name];
			end
			d(end+1:end+length(d1))=d1;
		end
		d(i)=[];
	else
		i=i+1;
	end
end