function unprotect(c)
% CSWF/UNPROTECT - haal protect uit SWF

% Er wordt vanuit gegaan dat "ShowFrame" altijd op het einde van de frame staat
%  en dat deze nooit wordt weggehaald.  Daarom wordt niet getest op einde van de
%  tag.
if ~c.protected
	fprintf('SWF is niet beveiligd!\n');
	return
end
if isfield(c.frames{1},'tagStart')
	i=zoektags(c,'Protect');
	if size(i,1)
		warning('!!!!Meer dan een protect-tag')
	end
	% Dit kan sneller bij meerdere tags, maar normaal komt dat nooit voor
	for j=size(i,1):-1:1
		i0=i(j,2);
		n=c.frames{j}(i0+1).tagStart-c.frames{j}(i0).tagStart;
		for k=i(j,1):length(c.frames)
			for l=i0:length(c.frames{k})
		end
	end
	
else
	error('niet klaar met dit type object, en ik weet niet of dit ooit komt - lees swf met leesswf1 of met cswf(xxxx,1)')
end
