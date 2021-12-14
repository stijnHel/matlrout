function X=leesmdl(f)
% LEESMDL  - Leest matlab simulink-file in een struct.
%   Deze file werd voornamelijk gemaakt om files van een hogere
%      simulink-versie in te lezen, en te zien wat er mee te doen is.

fid=fopen(f,'rt');
if fid<3
	error('kan file niet openen')
end
s=fgetl(fid);
stack={'basis',[]};
blok=[];
while ischar(s)
	[s1,n,~,i]=sscanf(s,'%s',1);
	if ~n
		if feof(fid)
			break;
		else
			continue;	% ??lege lijn??
		end
	end
	snext=fgetl(fid);
	if strcmp(s1,'}')
		if isempty(stack)
			fclose(fid);
			error('Verkeerde structuur')
		end
		naam=stack{end,1};
		stack(end,:)=[];
		A=stack{end,2};
		if isempty(A)
			A=struct(naam,blok);
		elseif isfield(A,naam)
			B=getfield(A,naam);
			if iscell(B)
				B{end+1}=blok;
			else
				B={B,blok};
			end
			A=setfield(A,naam,B);
		else
			A=setfield(A,naam,blok);
		end
		blok=A;
	else
		while s(i)==' '||s(i)==char(9)	% normaal gezien altijd "iets"
			i=i+1;
		end
		if s(i)=='{'
			stack{end,2}=blok;
			stack{end+1,1}=s1;
			blok=[];
		else
			s=deblank(s(i:end));
			if s(1)=='"'
				while snext(1)=='"'	% normaal gezien nooit leeg en nooit einde file
					s=[s(1:end-1) snext(2:end)];
					snext=fgetl(fid);
				end
			end
			if s(1)=='"'
				if s(end)~='"'
					warning('!!een string zonder eind-''"'' (%s)?',s)
				else
					s=s(2:end-1);
				end
			end
			if ~isempty(s)&&s(1)=='['
				if s(end)~=']'
					warning('!!een array zonder eind-'']'' (%s)?',s)
				else
					try
						s=eval(s);
					catch
						warning('niet interpreteerbare array (%s)',s)
					end
				end
			end
			if isempty(blok)
				blok=struct(s1,s);
			elseif isfield(blok,s1)
				fclose(fid);
				error('dit was niet verwacht!!!')
			else
				blok=setfield(blok,s1,s);
			end
		end
	end
	
	s=snext;
end
fclose(fid);
if size(stack,1)~=1
	error('verkeerde structuur')
end
X=blok;
