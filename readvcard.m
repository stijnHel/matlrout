function vcards=readvcard(f)
% READVCARD - Leest vcard-info

if length(f)<100
	fid=fopen(f);
	if fid<3
		error('kan file niet openen');
	end
	x=fread(fid);
else
	x=f;
end
if max(x(1:2:end))==0
	x=x(2:2:end);
end

i=find(x==13|x==10);
j=find(diff(i)==1);
if ~isempty(j)
	x(i(j))=[];
	i=find(x==13|x==10);
end
if ~ischar(x)
	x=char(x);
end
if size(x,1)>1
	x=x';
end
i=[0 i(:)'];
vcards=[];
vcard=struct;
vcard0=struct;
v1='';
for j=1:length(i)-1
	x1=deblank(x(i(j)+1:i(j+1)-1));
	k=find(x1==':');
	if length(k)==1
		x11=lower(x1(1:k-1));
		if strcmp(x11,'begin')
			x2=x1(k+1:end);
			if ~strcmp(lower(x2),'vcard')
				error(sprintf('Ander gegeven dan verwacht (%s)',x2))
			end
			if ~isempty(vcards)
				vcard=vcard0;
			end
		elseif strcmp(x11,'end')
			x2=x1(k+1:end);
			if ~strcmp(lower(x2),'vcard')
				error(sprintf('Ander gegeven dan verwacht (%s)',x2))
			end
			if isempty(vcards)
				vcards=vcard;
			else
				vcards(end+1)=vcard;
			end
		else
			if isempty(k)
				k=find(x1==';');
				if isempty(k)
					error('niet gevonden wat ik zocht')
				end
			else
				k1=find(x1==';');
				if ~isempty(k1)
					if k1(1)<k(1)
						k=k1;	% !!!
					end
				end
			end
			typ=x1(1:k(1)-1);
			if isempty(vcards)
				vcard0=setfield(vcard0,typ,'');
			end
			vcard=setfield(vcard,typ,x1(k(1)+1:end));
		end
	end	% length(k)==1
end
