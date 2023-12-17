function reminder(txt,t)
%reminder - Give an alert after some time

if isdatetime(t)
	t = datenum(t);
elseif isnumeric(t)
	if isvector(t) && length(t)>1
		if length(t)>6
			error('What an input?!')
		elseif length(t)~=3 && length(t)~=6
			t(6) = 0;
		end
		if size(t,2)==0
			t = t';
		end
		t = datenum(t);
	end
else
	error('Wrong input')
end
dt = (t-now)*86400;
if dt<5
	error('Sorry, but you must give me some time.... (you gave me %g s!',dt)
end
st = warning("off");
t = timer('StartDelay',dt,'TimerFcn',@ItsTime,'UserData',txt);
start(t)
warning(st)

function ItsTime(t,~)
stop(t)
txt = t.UserData;
msgbox(txt,'reminder-message!','modal')
delete(t)
