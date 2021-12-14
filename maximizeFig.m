function maximizeFig(fList,onoff)
%maximizeFig - Maximize figures
%    maximizeFig(fList,onoff)
%        onoff: default - on
%             'on','off','toggle'

fAll = get(0,'children');
if nargin==0||isempty(fList)
	if isempty(fAll)
		error('No figure?!')
	end
	fList = gcf;
elseif ischar(fList)
	if strcmpi(fList,'all')
		fList = fAll;
	else
		error('Unknown input for figure list')
	end
end
if nargin<2 || isempty(onoff)
	onoff = 'on';
end

switch lower(onoff)
	case 'on'
		wState = 'maximized';
	case 'off'
		wState = 'normal';
	case 'toggle'
		if strcmp(get(fList(1),'WindowState'),'normal')
			wState = 'maximized';
		else
			wState = 'normal';
		end
	otherwise
		error('Wrong onoff-input')
end

set(fList,'WindowState',wState)
