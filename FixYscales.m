function FixYscales(f,cmd)
%FixYscales - function to correct bad Y-scaling of new ML versions
%    FixYscales(fig) - in figure (default current figure)
%    FixYscales(fig,'off')	- set y-scaling automatic

if nargin==0
	f=gcf;
	cmd=[];
elseif ischar(f)
	if nargin>1
		error('Wrong inputs?!')
	end
	cmd=f;
	f=gcf;
elseif isempty(f)
	f=gcf;
end

if ~isempty(cmd)
	if ischar(cmd)
		switch lower(cmd)
			case {'off','auto'}
				ax = GetNormalAxes(f);
				set(ax,'YLimmode','auto')
		end
	else
		error('Wrong input for cmd!')
	end
	return
end

[S,Sinfo] = getsigs(f);
if isnumeric(S)
	S = {S};
end
for i=1:length(S)
	yMax = -Inf;
	yMin = Inf;
	Si = S{i};
	if isnumeric(Si)
		Si = {Si};
	end
	for j=1:length(Si)
		y=Si{j}(Si{j}(:,3)>0,2);
		if ~isempty(y)
			yMax = max(yMax,max(y));
			yMin = min(yMin,min(y));
		end
	end
	if yMax>=yMin	% otherwise no visible point found
		% currently very simple "tight limitting"
		if yMax==yMin
			if yMin==0
				dy = 1;
			else
				dy = yMin/10;
			end
			yMax = yMax+dy;
			yMin = yMin-dy;
		end
	end
	set(Sinfo(i).axes,'Ylim',[yMin,yMax])
end
