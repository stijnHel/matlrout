function Y=flattenDir(X)
% STRUCT/FLATTENDIR - Maakt een hierarchieloze directory-lijst
%     Y=flattenDir(X)
%
%  see also hierdir

Y=X.contents([]);
Y(1).name='';
Y.dir=[];
Y.fulldir=[];
ny=0;
Y(10000).name='';
dird='\';
ref=struct('type',{'.','()'},'subs',{'contents',{0}});
refnaam=struct('type','.','subs','name');
while length(ref)>1
	i=ref(end).subs{1};
	if i>=length(subsref(X,ref(1:end-1)))
		ref=ref(1:end-2);
	else
		i=i+1;
		ref(end).subs{1}=i;
		X1=subsref(X,ref);
		if X1.isdir
			ref=[ref struct('type',{'.','()'},'subs',{'contents',{0}})];
		else
			d1='';
			for i=2:2:length(ref)-2
				d1=[d1 dird subsref(X,[ref(1:i) refnaam])];
			end
			if ~isempty(d1)
				d1(1)='';
			end
			X1.dir=d1;
			X1.fulldir=[X.dirnaam dird d1];
			ny=ny+1;
			Y(ny)=X1;
		end
	end
end
Y=Y(1:ny);
