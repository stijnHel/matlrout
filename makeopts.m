function opts=makeopts(list)
%makeopts - Makes a list of options (to be used in setoptions)
%    opts=makeopts(list)
%  Values are taken from the calling function workspace

opts=cell(2,length(list));
for i=1:length(list)
	opts{1,i}=list{i};
	opts{2,i}=evalin('caller',list{i});
end
