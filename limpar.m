function s=limpar(s,c)
% LIMPAR   - Limiteert strings op lengte of op delimiter-teken(s).
%  s=limpar(s,c)
%  s=limpar(s,n)
%  s=limpar(s,{c,n})
%     s kan string-array zijn of cell-array met strings
% (bij string-array worden spaties genegeerd!)

C='';
N=inf;
if iscell(c)
	for i=1:length(c)
		if ischar(c{i})
			C=[C;c{i}(:)];
		elseif isnumeric(c{i})
			N=min(N,c{i});
		else
			error('verkeerde input in limpar')
		end
	end
elseif isnumeric(c)
	N=c;
elseif ischar(c)
	C=c;
else
	error('verkeerde input in limpar')
end

if iscell(s)
	for i=1:numel(s)
		b=0;
		s1=s{i};
		if ~isempty(C)
			for j=1:length(s1)
				if any(s1(j)==C)
					s1=s1(1:j-1);
					b=1;
					break;
				end
			end
		end
		if length(s1)>N
			s1=s1(1:N);
			b=1;
		end
		if b
			s{i}=s1;
		end
	end
else
	B=0;
	for i=1:size(s,1)
		b=0;
		s1=deblank(s(i,:));
		if ~isempty(C)
			for j=1:length(s1)
				if any(s1(j)==C)
					s1=s1(1:j-1);
					b=1;
					break;
				end
			end
		end
		if length(s1)>N
			s1=s1(1:N);
			b=1;
		end
		if b
			s(i,:)=[s1,zeros(1,size(s,2)-length(s1))];
			B=1;
		end
	end
	L=all(s==0|s==' ');
	if all(L)
		s=s(:,[]);
	elseif L(end)
		i=length(L);
		while L(i)
			i=i-1;
		end
		s=s(:,1:i);
	end
end
