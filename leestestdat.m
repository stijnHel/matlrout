function x=leestestdat(fnaam,nkan)
%LEESTESTDAT - Leest binaire data van testtest_.vi
%    x=leestestdat(fnaam[,nkan])
%
%   Indien nkan niet gegeven, wordt deze "geraden".

fid=fopen(zetev([],fnaam),'r','ieee-be');
if fid<3
	[pth,fn,fext]=fileparts(fnaam);
	if isempty(fext)
		fid=fopen(zetev([],[fnaam '.dat']),'r','ieee-be');
		if fid<3
			error('Kan file niet openen');
		end
	else
		error('Kan file niet openen')
	end
end

x=fread(fid,'single');
fclose(fid);

if ~exist('nkan','var')||isempty(nkan)
	r=rem(length(x),2:20);
	nkan=find(r==0)+1;
	if isempty(nkan)
		warning('Vindt geen geschikt aantal kanalen - 1 wordt verondersteld')
		nkan=1;
	elseif length(nkan)>1
		if sum(nkan<12)==1
			nkan=nkan(1);
		else
			if any(nkan<12)
				nkan=nkan(nkan<12);
			end
			X=nkan;
			Y=nkan;
			Z=nkan;
			for j=1:length(nkan)
				y=reshape(x,[],nkan(j));
				X(j)=mean(std(y));
				Y(j)=sum(max(abs(diff(y))).^2);
				Z(j)=sum(sum(diff(y).^2));
			end
			[mn,j]=min(X);
			[mn,j2]=min(Y);
			[mn,j3]=min(Z);
			if any(j~=[j2 j3])
				fprintf('rem(length,2:20) : ');fprintf('%3d',r);fprintf('\n')
				fprintf('nkan_guess : ');fprintf('%3d',nkan);fprintf('\n')
				fprintf('nkan_guesses (diff methods) mean_std : %d, max_abs_diff : %d, squareddiff : %d\n',nkan([j j2 j3]))
				fprintf('meanstd      : ');fprintf(' %12g',X);fprintf('\n')
				fprintf('max_abs_diff : ');fprintf(' %12g',Y);fprintf('\n')
				fprintf('squareddiff  : ');fprintf(' %12g',Z);fprintf('\n')
				jmin=min([j,j2,j3]);
				warning('Geen gelijke schattingen van aantal kanalen, kleinste (%d) wordt genomen!!',nkan(jmin))
				j=jmin;
			end
			nkan=nkan(j);
			%warning('!!!!schatting gedaan van aantal kanalen!!!')
		end
	end
end
x=reshape(x,[],nkan);
