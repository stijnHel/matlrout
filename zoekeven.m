function X=zoekeven(s,mineven,alle)
% ZOEKEVEN - Zoekt event die aan bepaalde voorwaarden voldoet.
%  x=zoekeven(s,mineven,alle)
%     s : voorwaarden :
%         't=...:test,.....'
%     mineven (als gegeven) minimum event
%     alle (als gegeven) : ==0 stoppen bij eerst gevonden, anders zoekt alle

if ~exist('mineven');mineven=[];end
if ~exist('alle');alle=[];end
if isempty(mineven)
	mineven=0;
end
if isempty(alle)
	alle=0;
end
labelletters=zeros(255,1);
labelletters(abs(['0':'9' 'a':'z' '_']))=ones(37,1);
tijden=[];
testen=[];
vars=[];
s=lower(s);
while ~isempty(s)
	if length(s)<5
		error('fout in voorwaarden')
	end
	if strcmp(s(1:2),'t=')
		t=[];
		s(1:2)=[];
		while (s(1)>='0')&(s(1)<='9')
			t=[t s(1)];
			s(1)=[];
		end
		tijden=[tijden;str2num(t)];
		if s(1)~=':'
			error('fout in voorwaarden')
		end
		s(1)=[];
		i=find(s==',');
		if isempty(i)
			test1=s;
			s=[];
		else
			test1=s(1:i(1)-1);
			s(1:i(1))=[];
		end
		testen=addstr(testen,test1);
		while ~isempty(test1)
			while ~labelletters(abs(test1(1)))
				test1(1)=[];
				if isempty(test1)
					break
				end
			end
			if ~isempty(test1)
				if (test1(1)<'0')|(test1(1)>'9')
					v=[];
					while labelletters(abs(test1(1)))
						v=[v test1(1)];
						test1(1)=[];
						if isempty(test1)
							break;
						end
					end
					if isempty(fstrmat(vars,v))
						vars=addstr(vars,v);
					end
				else	% geen cijfer als begin
					while labelletters(abs(test1(1)))
						test1(1)=[];
						if isempty(test1)
							break;
						end
					end
				end	% letter als begin (sla dit over)
			end	% einde test1
		end	% zoek variabelen
	else	% niet begonnen met t=
		error('fout in voorwaarden')
	end
end
d=direv(0,'data* /o');
i_events=findstr(d,[10 'DATA']);
x=[];
i_tijden=round(tijden/0.016384)+1;
status('Zoeken naar de juiste even',0)
for j=1:length(i_events)
	status((j-1)/length(i_events));
	n=str2num(d(i_events(j)+5:i_events(j)+8));
	if n>=mineven
		ok=1;
		[e,ne,de,t]=leeseven(n,[],[],[],0);
		j_tijden=i_tijden*round(t(2)/0.016384);
		if max(j_tijden)>length(t)
			ok=0;
		else
			e=e(j_tijden,:);
			ne=lower(ne);
			for k=1:size(vars,1)
				l=fstrmat(ne,deblank(vars(k,:)));
				if isempty(l)
					ok=0;
					break;
				end
				l=l(1);
				extr_n=deblank(ne(l,:));
				eval([extr_n '=e(:,' int2str(l) ');']);
			end	% bepaal aanwezigheid van variabelen
		end
		if ok
			for k=1:length(tijden)
				eval(['test=' deblank(testen(k,:)) ';']);
				if ~test(k)
					ok=0;
					break;
				end
			end % for k
			if ok
				x=[x n];
				if ~alle
					break;
				end
			end
		end	% voorwaarden voldoen niet om test uit te voeren.
	end	% if event na minimum
end	% for i_events
if nargout
	X=x;
else
	fprintf('event ');fprintf('%d ',x)
	fprintf('\n')
end
status
