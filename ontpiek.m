function ontpiekt=ontpiek(e,limPieks,limPiek2,maxima,minima)
% ONTPIEK  - Verwijdert pieken uit meting
%          ontpiekt=ontpiek(e,limPieks,limPiek2,maxima,minima);
%             e mag een matrix zijn.
%         Er kan wel slechts een set van parameters gegeven worden,
%            en werkt dus enkel voor signalen met gelijkaardige bereiken.
%
%     Deze functie werkt op basis van het zoeken naar enkele pieken,
%        door te zoeken naar hoge tegengestelde diff-waarden (>limPieks).
%        De twee opeenvolgende diff-waarden moeten samen kleiner zijn
%        dan limPiek2.
%        uitbreiding: limPiek2=[absLim2,relLim2]
%            minimum tussen piek-waarde*relLim2 en absLim wordt genomen
%     Het is ook mogelijk om limieten van mogelijke waarden te bepalen.
%
%   Deze functie werkt goed in gevallen waar enkele pieken (spikes)
%      voorkomen, piekerige signalen met meerdere opeenvolgende piekwaarden
%      geven geen goed resultaat.
if (exist('maxima','var')&&~isempty(maxima))||(exist('minima','var')&&~isempty(minima))
	if ~exist('maxima','var')
		maxima=inf;
	end
	if ~exist('minima','var')
		minima=-inf;
	end
	if (length(maxima)==1)&&(size(e,2)>1)
		maxima=maxima(1,ones(size(e,2),1));
	end
	if (length(minima)==1)&&(size(e,2)>1)
		minima=minima(1,ones(size(e,2),1));
	end
	maxima=maxima(:)';
	if size(e,2)>1
		b=any((e>maxima(ones(size(e,1),1),:))'|(e<minima(ones(size(e,1),1),:))');
	else
		b=(e>maxima)|(e<minima);
	end
	if any(b)
		i=find(b);
		if length(i)==length(b)
			error('All data out of range')
		end
		%fprintf('%d punten verwijderd omwille van extremen.\n',length(i))
		%e(i,:)=[];
		if i(1)==1
			j=2;
			while b(j)
				j=j+1;
			end
			e(1:j-1,:)=e(j+zeros(1,j-i(1)),:);
			i(1:j-1)=[];
		end
		if ~isempty(i)
			if i(end)==size(e,1)
				j=i(end)-1;
				while b(j)
					j=j-1;
				end
				e(j+1:end,:)=e(j+zeros(1,i-j),:);
				i(j+1:end)=[];
			end
			while ~isempty(i)
				j=2;
				while j<=length(i)&&i(j)==i(j-1)+1
					j=j+1;
				end
				ij=i(j-1);
				e(i(1):ij,:)=repmat(mean(e([i(1)-1 ij+1],:)),ij-i(1)+1,1);
				i(1:j-1)=[];
			end
		end
	end
end
if ~exist('limPiek2','var')||isempty(limPiek2)
	limPiek2=limPieks/10;
end

de=diff(e);
de_hoog=find(max(abs(de))>limPieks);
if ~isempty(de_hoog)
	if length(limPiek2)<2
		lim2=limPiek2;
	end
	for i=1:length(de_hoog)
		kan=de_hoog(i);
		%x=e(:,kan);
		dx=de(:,kan);
		idx=find(abs(dx)>limPieks);
		n_idx=length(idx);
		i_idx=1;
		nOnt=0;
		while i_idx<length(idx)
			if i_idx<n_idx;
				j=idx(i_idx);
				if length(limPiek2)>1
					lim2=max(limPiek2(1),limPiek2(2)*abs(dx(idx(i_idx))));
				end
				% (onderstaande test kan wat eenvoudiger.  als twee
				% opeenvolgende indices gevonden worden, en hun product is
				% negatief, zal dit ook kleiner zijn dan limPieks^2.)
				if (j+1==idx(i_idx+1))&&(dx(j)*dx(j+1)<-limPieks^2)&&(abs(dx(j)+dx(j+1))<lim2)
					nOnt=nOnt+1;
					if nOnt<3
						%fprintf('Piek (hoogte %g) verwijderd bij kanaal %2d op niveau %g\n',mean(abs(dx(j:j+1))),kan,(x(j)+x(j+2))/2);
					end
					e(j+1,kan)=mean(e([j j+2],kan));
					i_idx=i_idx+2;
				else
					i_idx=i_idx+1;
				end
			else
				i_idx=i_idx+1;
			end
		end	% while
		if nOnt>2
			%fprintf('  In totaal %d pieken gevonden op dit kanaal.\n',nOnt)
		end
	end
end
ontpiekt=e;
