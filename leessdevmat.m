function E=leessdevmat(fn)
% LEESSDEVMAT - Leest mat-file van SDEV

S=whos('-file',fn);
E=struct('e',{},'ne',{},'de',{},'dt',{});
n=0;
for i=1:length(S)
	if strcmp(S(i).class,'double')&&S(i).size(2)==2
		x1=load(fn,S(i).name);
		x1=x1.(S(i).name);
		n=n+1;
		E(n).e=x1(:,2);
		E(n).ne=S(i).name;
		E(n).de='-';
		dt=diff(x1(:,1));
		E(n).dt=mean(dt);
		if std(dt)/E(n).dt>1e-5
			warning('!!!niet equidistante meetpunten (%s)!!\n - deze worden toch equidistant behandeld (%g- - %g)'	...
				,S(i).name,std(dt),E(n).dt)
		end
	end
end

