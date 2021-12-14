function ch=toonchil(h,types,wat)
% TOONCHIL - toont children van figuur
if ~exist('h');h=[];end
if ~exist('wat');wat=[];end
if ~exist('types')
	types=[];
else
	types=[' ' types ' '];
end
if isempty(wat) & nargout==0
	wat='Type';
end
if isempty(h)
	h=gcf;
end
x=get(h,'children');
j=0;
y=[];
for i=1:length(x)
	if isempty(types) | ~isempty(findstr(types,[' ' get(x(i),'Type') ' ']))
		j=j+1;
		y(j)=x(i);
		if ~isempty(wat)
			fprintf('%2d (%2d, %f) : ',j,i,x(i));
			w=get(x(i),wat);
			if isempty(w)
				fprintf('[]\n');
			else
				disp(w)
			end
		end
	end
end
if nargout>0
	ch=y;
end
