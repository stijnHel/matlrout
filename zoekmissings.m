function [miss,fout]=zoekmissings(D)
% ZOEKMISSINGS - Zoekt naar missende meetpunten in lph1-metingen

if exist('D')&~isempty(D)
	zetev(D);
end
d=dir([zetev '*.log']);
d=sort(d,'name');
miss=zeros(1,length(d));
fout=zeros(1,length(d));
status('testen van files',0);
for i=1:length(d)
	try
		e=leesnlphf([zetev d(i).name]);
		dN=diff(e(:,2));
		ddN=2*dN(2:end-1)-dN(1:end-2)-dN(3:end);
		j=find(abs(ddN)>20&abs(dN(2:end-1))>40&(dN(1:end-2).*dN(3:end)>0)&(dN(1:end-2).*dN(2:end-1)>0)&e(1:end-3,2)>400);
		if ~isempty(j)
			miss(i)=1;
			dj=diff(j);
			if any(dj==1)
				j(find(dj==1)+1)=[];
			end
			fprintf('%3d : %s - ',i,d(i).name);
			if length(j)>10
				fprintf('(!!!meer dan 10 plaatsen!!!)\n')
			else
				t=zeros(length(j),1);
				for k=1:length(j)
					l=max(1,j(k)-1):min(length(dN),j(k)+4);
					[mx,m]=max(abs(dN(l)));
					l1=l;
					l1(m)=[];
					if std(dN(l1))/mx>0.1
						fprintf(' (!!%d:',k)
						fprintf('%1.0f ',dN(l))
						fprintf('!!) ')
					end
					t(k)=mx/abs(mean(dN(l1)));
				end
				fprintf('%3.1f(%3.1f) ',[(j-1)*0.2 t]');
				fprintf('\n');
			end
		end
	catch
		fout(i)=1;
	end
	status(i/length(d));
end
status
miss=strvcat(d(find(miss)).name);
fout=strvcat(d(find(fout)).name);
