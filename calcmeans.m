function Xout=calcmeans(dirimgs,p,metView)
% CALCMEANS - Bepaalt gemiddeldes van images

if ~exist('metView','var')
	metView=1;
end
if iscell(p)
	p=cat(1,p{:});
end
p=max(1,round(p));
Xout=zeros(501,1+numel(p))-1;
nnOK=0;
if metView
	figure
	colormap(hsv(256))
end
nOK=0;
dt=1;
for i=0:500
	try
		X=leesImg(sprintf('%s%cimg%d.bin',dirimgs,filesep,i));
		nOK=nOK+1;
		nnOK=0;
		if metView
			if nOK==1
				for icol=1:3
					subplot(2,2,icol)
					h(icol)=image(X(:,:,icol));
				end
				subplot(2,2,4)
				h(4)=image(X);
				colorbar
			else
				for icol=1:3
					set(h(icol),'CData',X(:,:,icol));	
				end
				set(h(4),'CData',X)
			end
			title(sprintf('%d',i));
			drawnow
			pause(dt);
		end
		m=1;
		Xout(i+1,m)=i;
		for j=1:size(p,1)
			X1=X(p(j,3):p(j,4),p(j,1):p(j,2),:);
			for k=1:3
				m=m+1;
				X2=X1(:,:,k);
				Xout(i+1,m)=mean(X2(:));
			end
			m=m+1;
			Xout(i+1,m)=mean(X1(:));
		end
	catch
		if isempty(findstr(lasterr,'leesImg'))
			error('!!andere error dan toegelaten!!! (%s)',lasterr)
		end
		nnOK=nnOK+1;
		if nnOK>5
			break;
		end
	end
end
Xout(Xout(:,1)<0,:)=[];
