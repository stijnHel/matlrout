function Adata=conva2ml(a2ml)
% CONVA2ML - Converteert A2ML-data
%    Adata=conva2ml(a2ml)
%      Converteert data om te kunnen gebruiken in leesasap.

if ischar(a2ml)
	Adata={'d1',stringdata(a2ml)};
	return
end
if iscell(a2ml)
	error('!!!nog niet klaar')
end
switch a2ml.type
case 'struct'
	Adata=leesstrucdata(a2ml.data);
case 'enum'
	Adata={'enum',a2ml.data.naam};
case 'taggedstruct'
	Adata=cell(0,2);
	f=fieldnames(a2ml);
	for i=1:length(f)
		if ~strcmp(f{i},'type')&~strcmp(f{i},'naam')&~strcmp(f{i},'data')
			if strcmp(f{i}(max(1,end-1):end),'_x')
				Adata{end+1,1}=f{i}(1:end-2);	%!!!!!!!!!aangeven
			else
				Adata{end+1,1}=f{i};
			end
			Adata{end,2}=conva2ml(getfield(a2ml,f{i}));
		end
	end
	Adata={'extra',Adata};
case 'taggedunion'
	Adata=cell(0,2);
	f=fieldnames(a2ml);
	for i=1:length(f)
		if ~strcmp(f{i},'type')&~strcmp(f{i},'naam')&~strcmp(f{i},'data')
			Adata{end+1,1}=f{i};
			Adata{end,2}=conva2ml(getfield(a2ml,f{i}));
		end
	end
	Adata={'extra',Adata};	%!!!!!aanduiden dat maar één element gegeven mag worden!!!
case '('
	t=stringdata(a2ml.data);
	if ~strcmp(t,'int')
		warning('!!!!(xxxxxx)!!!!!')
		Adata={};
	else
		Adata={'(#)',{'d1',t}};
	end
otherwise
	error('onbekend a2ml-type')
end

function Adata=leesstrucdata(data)
Adata=cell(0,2);

for idata=1:length(data)
	Adata{end+1,1}=['d' num2str(size(Adata,1))];
	if isstruct(data{idata})
		if strcmp(data{idata}.type,'struct')
			if idata>1
				error('onverwacht')
			end
			Adata=conva2ml(data{idata});
		else
			A1=conva2ml(data{idata});
			if strcmp(A1{1},'extra')
				if idata<length(data)|size(A1,1)>1
					error('onmogelijk')
				end
				A1=A1{2};
				Adata{end,1}='extra';
			end
			Adata{end,2}=A1;
		end
	elseif iscell(data{idata})
		error('onverwacht')
	else
		Adata{end,2}=stringdata(data{idata});
	end
end
if iscell(Adata{end,2})&all(size(Adata{end,2})==[1 2])&strcmp(Adata{end,2}{1,1},'extra')
	Adata{end,1}='extra';
	Adata{end,2}=Adata{end,2}{1,2};
end

function Adata=stringdata(d)
j=find(d=='[');
if ~isempty(j)
	k=find(d==']');
	if length(j)~=1|length(k)~=1|j>k|k<length(d)
		error('foute array-specificatie (of onverwachte fout)')
	end
	sn=str2num(d(j+1:k-1));
	d=d(1:j-1);
	if ~strcmp(d,'char')
		warning('arrays van niet char''s komen toch voor!!')
	end
else
	sn='';
end
switch d
case {'char','int','long','uchar','uint','ulong'}
	if strcmp(d,'char')&~isempty(sn)
		Adata='string';
	else
		Adata=[sn 'int'];
	end
case {'double','float'}
	Adata=[sn 'float'];
otherwise
	error('!!!!')
end
