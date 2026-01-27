%calcStartSeiz - script voor bepaling van start van seizoenen

if ~exist('bWriteResults','var')||isempty(bWriteResults)
	bWriteResults = false;
end
if ~exist('bPlotResults','var')||isempty(bPlotResults)
	bPlotResults = true;
end

T = [repmat([repmat((18:26)',4,1) reshape(ones(9,1)*(3:3:12),[],1)],400,1) reshape(ones(9*4,1)*(1850:2249),[],1)];
Tjm = calcjc(T)/10;
P = zeros(9,4,length(Tjm)/36);
elD = calcvsop87('aarde','zoek');
for i = 1:length(Tjm)
	[P(i),a,b] = calcvsop87(elD,Tjm(i));
end
A = zeros(size(P,3),4);
P(:,3,:) = P(:,3,:)-2*pi*(P(:,3,:)>4);
hL = [1 1.5 0 0.5]*pi;
for i = 1:4
	for j = 1:size(P,3)
		A(j,i) = interp1(P(:,i,j),T(1:9,1),hL(i),'spline');
	end
end
Ad = floor(A);
As = (A-Ad)*24;Ah=floor(As);As=(As-Ah)*60;Am=floor(As);As=(As-Am)*60;
AA = [Ad Ah Am As];
AA = AA(:,[1:4:16 2:4:16 3:4:16 4:4:16]);
if bWriteResults
	fid = fopen('AstrSeizoenStarts.txt','w');
	for i = 1:length(A)
		fprintf(fid,'%4d: %2d/3 %2d:%02d:%02.0f %2d/6 %2d:%02d:%02.0f %2d/9 %2d:%02d:%02.0f %2d/12 %2d:%02d:%02.0f\n',T(1,3)-1+i,AA(i,:));
	end
	fclose(fid);
end

if bPlotResults
	getmakefig StartSeizoenen
	plot(T(1:36:end,3),A);grid
	set(gca,'ylim',[18.5 24.5])
	legend 'lente' zomer herfst winter location southwest
	title 'start van seizoenen (in UTC)'
	xlabel 'jaartal'
	ylabel 'dag van maand'
end
