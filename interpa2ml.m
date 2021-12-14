function a2ml=interpa2ml(a2mldata)
% INTERP22ML - Interpreteer a2ml-data
%    a2ml=interpa2ml(a2mldata)
%       a2mldata={[tekstdata]}

hier={'basis','',{},{}};;
idata=0;
a='';
typexp={'declaration'};
while 1
	[a1,a,idata]=getword(a2mldata,idata,a);
	if ~ischar(a1)
		break;
	end
	switch a1
	case 'struct'
		[a1,a,idata]=getword(a2mldata,idata,a);
		hasstruct=0;
		if strcmp(a1,'{')	% struct {
			ident='';
			hasstruct=1;
		else
			ident=a1;
			[a2,a_,i_]=getword(a2mldata,idata,a);
			if strcmp(a2,'{')	% struct <ident> {
				a=a_;
				idata=i_;
				hasstruct=1;
			end
		end
		if hasstruct
			hier{end,4}=typexp;
			hier{end+1,1}='struct';
			hier{end,2}=ident;
			hier{end,3}={};
			typexp={'struct_member_list'};
		else
			hier{end,3}{end+1}=struct('type','struct','naam',ident,'data',[]);
		end
	case 'taggedstruct'
		[a1,a,idata]=getword(a2mldata,idata,a);
		hasstruct=0;
		if strcmp(a1,'{')	% taggedstruct {
			ident='';
			hasstruct=1;
		else
			ident=a1;
			[a2,a_,i_]=getword(a2mldata,idata,a);
			if strcmp(a2,'{')	% taggedstruct <ident> {
				a=a_;
				idata=i_;
				hasstruct=1;
			end
		end
		if hasstruct
			hier{end,4}=typexp;
			hier{end+1,1}='taggedstruct';
			hier{end,2}=ident;
			hier{end,3}={};
			typexp={'taggedstruct_member_list'};
%			typexp={'tag','block_def'};
		else
			hier{end,3}{end+1}=struct('type','taggedstruct','naam',ident,'data',[]);
		end
	case 'taggedunion'
		[a1,a,idata]=getword(a2mldata,idata,a);
		hasstruct=0;
		if strcmp(a1,'{')	% taggedunion {
			ident='';
			hasstruct=1;
		else
			ident=a1;
			[a2,a_,i_]=getword(a2mldata,idata,a);
			if strcmp(a2,'{')	% taggedunion <ident> {
				a=a_;
				idata=i_;
				hasstruct=1;
			end
		end
		if hasstruct
			hier{end,4}=typexp;
			hier{end+1,1}='taggedunion';
			hier{end,2}=ident;
			hier{end,3}={};
			typexp={'taggedunion_member_list'};
		else
			hier{end,3}{end+1}=struct('type','taggedunion','naam',ident,'data',[]);
		end
	case 'enum'
		[a1,a,idata]=getword(a2mldata,idata,a);
		hasstruct=0;
		if strcmp(a1,'{')	% enum {
			ident='';
			hasstruct=1;
		else
			ident=a1;
			[a2,a_,i_]=getword(a2mldata,idata,a);
			if strcmp(a2,'{')	% enum <ident> {
				a=a_;
				idata=i_;
				hasstruct=1;
			end
		end
		if hasstruct
			hier{end,4}=typexp;
			hier{end+1,1}='enum';
			hier{end,2}=ident;
			hier{end,3}={};
			typexp='enum';
		else
			hier{end,3}{end+1}=struct('type','enum','naam',ident,'data',[]);
		end
	case 'block'
		hier{end,4}=typexp;
		[tag,a,idata]=getword(a2mldata,idata,a);
		hier{end+1,1}='block';
		hier{end,2}=tag;
		hier{end,3}={};
		typexp='type_def';
	case '}'
		[hier,typexp]=endstruct(hier);
	case '('
		hier{end,4}=typexp;
		hier{end+1,1}='(';
		hier{end,3}={};
	case ')*'
		if ~strcmp(hier{end,1},'(')
			error('Verkeerde structuur');
		end
		[hier,typexp]=endstruct(hier);
	case ';'
	case ','
	case '['
	case ']'
	otherwise
		if ischar(typexp)
			switch typexp
			case 'enum'
				hier{end,3}(end+1).naam=a1;
				[a2,a_,i_]=getword(a2mldata,idata,a);
				if strcmp(a2,'=')
					[hier{end,3}(end).waarde,a,idata]=getword(a2mldata,i_,a_);
				end
			case 'type_def'
				[hier,typexp]=endstruct(hier);
			otherwise
				error('nog onbekend')
			end
		else
			hier{end,3}{end+1}=a1;
%			if strcmp(hier(end,1),'block')	%!!!!!!????
%				[hier,typexp]=endstruct(hier);
%			end
		end
	end % switch a1
end	% end
if size(hier,1)~=1
	error('Verkeerde structuur')
end
a2ml=hier{1,3};
if iscell(a2ml)&length(a2ml)==1
	a2ml=a2ml{1};
end

function [hier,typexp]=endstruct(hier)
T=struct('type',hier{end,1}	...
	,'naam',hier{end,2}	...
	);
if strcmp(hier{end,1},'taggedstruct')
	i=1;
	X=hier{end,3};
	while i<=length(X)
		if ischar(X{i})
			if isfield(T,X{i})
				error('Meerdere keren zelfde veld!')
			end
			T=setfield(T,X{i},X{i+1});
			i=i+1;
		elseif strcmp(X{i}.type,'(')
			if length(X{i}.data)==1
				if ~strcmp(X{i}.data.type,'block')
					error('onverwachte structuur')
				end
				T=setfield(T,X{i}.data.naam,X{i}.data.data);
			elseif length(X{i}.data)~=2|~ischar(X{i}.data{1})
				error('onverwachte structuur')
			else
				T=setfield(T,[X{i}.data{1} '_x'],X{i}.data{2});
			end
		elseif strcmp(X{i}.type,'block')
			T=setfield(T,X{i}.naam,X{i}.data);
		else
			error('onverwachte structuur')
		end
		i=i+1;
	end
elseif strcmp(hier{end,1},'taggedunion')
	i=1;
	X=hier{end,3};
	while i<=length(X)
		if ischar(X{i})
			if isfield(T,X{i})
				error('Meerdere keren zelfde veld!')
			end
			T=setfield(T,X{i},X{i+1});
			i=i+1;
		elseif strcmp(X{i}.type,'(')
			error('onverwachte structuur')
		elseif strcmp(X{i}.type,'block')
			T=setfield(T,X{i}.naam,X{i}.data);
		else
			error('onverwachte structuur')
		end
		i=i+1;
	end
elseif length(hier{end,3})==1
	T.data=hier{end,3}{1};
elseif ~isempty(hier{end,3})
	T.data=hier{end,3};
end
hier(end,:)=[];
hier{end,3}{end+1}=T;
typexp=hier{end,4};
if ischar(typexp)&strcmp(typexp,'type_def')
	[hier,typexp]=endstruct(hier);
end

function [a1,a,idata]=getword(a2mldata,idata,a)
if isempty(a)
	idata=idata+1;
	if idata>length(a2mldata)
		a1=[];
		return
	end
	a=a2mldata{idata};
end
if a(1)=='{'
	a1='{';
	a=a(2:end);
elseif a(1)=='('
	a1='(';
	a=a(2:end);
elseif length(a)>1&strcmp(a(1:2),')*')
	a1=')*';
	a=a(3:end);
elseif a(1)==')'
	a1=')';
	a=a(2:end);
elseif a(1)=='}'
	a1='}';
	a=a(2:end);
elseif a(1)=='='
	a1='=';
	a=a(2:end);
elseif a(1)=='"'
	i=find(a=='"');
	if length(i)~=2
		error('foute string (?)')
	end
	a1=a(2:i(2)-1);
	a=a(i(2)+1:end);
else
	a1=a(2:end);
	i=find(a1==','|a1==';'|a1=='='|a1=='('|a1=='{'|a1=='}'|a1==')');	% niet []
	if isempty(i)
		a1=a;
		a='';
	else
		a1=a(1:i(1));
		a=a(i(1)+1:end);
	end
end
