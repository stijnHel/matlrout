function X=readUXdirFile(fn)
% READDOSDIRFILE - Leest DOS-directory-info (uit textfile)
%    [X,C]=readDOSdirFile(fn)

fid=fopen(fn);
if fid<3
	error('Kan file niet openen');
end

ddelim='/'; % UNIX

s0=struct('name',[],'date',[],'bytes',[],'isdir',[],'contents',[]);

curDir=0;
baseDir=0;
indDir=0;
X1=struct('dirnaam',[],'contents',[]);
X=X1([]);
X1.contents=s0([]);

cNum=zeros(1,255);
cKarF=cNum;
cNum(abs('0123456789'))=1;
cPerm=zeros(1,255);
cPerm(abs('l-rwdx'))=1;

ddirs={};
drefs={};
curref=[];

% !!voorlopig nog simple - zonder hierarchie!!!!

while ~feof(fid)
	l=fgetl(fid);
	if isempty(l)||l(1)==' '	% (dat laatste is normaal niet mogelijk?)
		if ~isempty(X1.dirnaam)
			if isempty(curref)
				X(end+1)=X1;
			else
				subsasgn(X,[curref struct('type','.','subs','contents')],X1.contents);
			end
			X1.dirnaam='';
		end
		continue
	end
	isp=[find(l==' ') length(l)+1];
	bF=0;
	w1=l(1:isp(1)-1);
	if isp(1)==11&&all(cPerm(abs(w1)))
		l=l(isp(1)+1:end);
		[nr,n,err,i]=sscanf(l,'%d',1);
		if ~isempty(err)||n<1
			warning('!!!voortijdig afgebroken!!!')
			break
		end
        while l(i)==' '
            i=i+1;
        end
		l=l(i:end);
		[owner,n,err,i]=sscanf(l,'%s',1);
		if ~isempty(err)||n<1
			warning('!!!voortijdig afgebroken!!!')
			break
		end
        while l(i)==' '
            i=i+1;
        end
		l=l(i:end);
		[group,n,err,i]=sscanf(l,'%s',1);
		if ~isempty(err)||n<1
			warning('!!!voortijdig afgebroken!!!')
			break
		end
		[nbytes,n,err,i1]=sscanf(l(i:end),'%d',1);
		i=i+i1;
        while l(i)==' '
            i=i+1;
		end
		l=l(i:end);
		dat=cell(1,3);
		for j=1:3
			[dat{j},n,err,i]=sscanf(l,'%s',1);
			while l(i)==' '
		        i=i+1;
			end
			l=l(i:end);
		end
		
		fn=l;
		bF=1;
		isDir=0;
		nbytes=0;
		if w1(1)=='d'
            isDir=1;
            newdir=[X1.dirnaam ddelim fn];
            ddirs{end+1}=newdir;
            drefs{end+1}=[curref struct('type',{'.','()'}   ...
                ,'subs',{'contents',{length(X1.contents)+1}})];
		end
		if isempty(X1)
			warning('!!!fout - geen directory begin gevonden???!!!')
			break;
		end
		s1=s0;
		s1.name=fn;
		datnum=datenum([dat{1} ' ' dat{2} ' ' dat{3}]);
		s1.date=datevec(datnum);
		s1.bytes=nbytes;
		s1.isdir=isDir;
		X1.contents(end+1)=s1;
	elseif w1(end)==':'
		X1.dirnaam=w1(1:end-1);
		X1.contents(:)=[];  % waarom hier?
        i=strmatch(X1.dirnaam,ddirs,'exact');
        if isempty(i)
            % enkel mogelijk eerste keer (normaal gezien)
            curref=[];
        else
            curref=drefs{i};
            % deze dref en ddir zou weggehaald kunnen/moeten worden
        end
	end
end
fclose(fid);
