function disp(c,f0,f1,hier)
% CSWF/DISP - Geeft de SWF-file weer in tekst-formaat.
%    disp(c,frame0,frame1,hier)

global SWF_tags SWF_ttypes SWF_actionIDs SWF_sactions

fprintf('versie %d, lengte %d, frame [%d %d %d %d], framerate %d, framecount %d\n',	...
	c.versie, c.len, c.frameSize, c.frameRate, c.frameCount);
if ~exist('f0')|isempty(f0)
	f0=1;
end
if ~exist('f1')|isempty(f1)
	f1=length(c.frames);
end
if ~exist('hier')|isempty(hier)
	hier=0;
end

if ischar(f0)
	return
end

fprintf('F nr nr  id lengte naam\n');
for i=f0:f1
	fnr=sprintf('%4d ',i);
	for j=1:length(c.frames{i})
		u1=c.frames{i}(j);
		u=u1.tagData;
		if u1.tagID>=length(SWF_tags)
			name='xxxxx';
		else
			name=SWF_tags{u1.tagID+1};
		end
		fprintf('%s%3d %3d %5d %-25s ',	...
			fnr,j,u1.tagID,u1.tagLen,name)
		if isfield(u,'ID')&length(u)==1
			fprintf('ID %d ',u.ID);
		end
		if u1.tagID==5|u1.tagID==28
			fprintf('depth %d',u.depth)
		elseif u1.tagID==9
			fprintf('%d %d %d',u)
		elseif u1.tagID==12&length(u)==1
			if any(u.ID==SWF_actionIDs)
				fprintf('%s',SWF_sactions{find(u.ID==SWF_actionIDs)});
			else
				fprintf('xxx');
			end
		elseif u1.tagID==12&hier>1&length(u)>1
			fprintf('\n');
			for k=1:length(u)
				fprintf('               %d ',u(k).ID);
				if any(u(k).ID==SWF_actionIDs)
					fprintf('%s',SWF_sactions{find(u(k).ID==SWF_actionIDs)});
				else
					fprintf('xxx');
				end
				fprintf(' %d\n',length(u(k).data))
			end
			fprintf('.............................');
		elseif u1.tagID==20|u1.tagID==36
			fprintf('%dx%d, %d',u.width,u.height,u.format);
		elseif u1.tagID==26
			fprintf(' depth %d',u.depth);
		elseif u1.tagID==39	% sprite
			fprintf(' %d frames',length(u.frames))
			if hier
				fprintf('\n');
				for k=1:length(u.frames)
					fnr=sprintf('%4d ',k);
					for l=1:length(u.frames{k})
						u1=u.frames{k}(l);
						u0=u1.tagData;
						if u1.tagID>=length(SWF_tags)
							name='xxxxx';
						else
							name=SWF_tags{u1.tagID+1};
						end
						fprintf('  %s%3d %3d %5d %-25s ',	...
							fnr,l,u1.tagID,u1.tagLen,name)
						if isfield(u0,'ID')&length(u0)==1
							fprintf('ID %d ',u0.ID);
						end
						if u1.tagID==5|u1.tagID==28
							fprintf('depth %d',u0.depth)
						elseif u1.tagID==12&length(u0)==1
							if any(u0.ID==SWF_actionIDs)
								fprintf('%s',SWF_sactions{find(u0.ID==SWF_actionIDs)});
							else
								fprintf('xxx');
							end
						elseif u1.tagID==26
							fprintf(' depth %d',u0.depth);
						elseif isstruct(u0)
							fprintf('struct[%d]',length(u0))
						elseif ischar(u0)&size(u0,1)==1
							fprintf('%s',u0)
						elseif ~isempty(u0)
							fprintf('%d',length(u0))
						end
						fprintf('\n')
						fnr='     ';
					end	% for l
				end	% for k
				fprintf('--------------------------');
			end	% if hier
		elseif u1.tagID==56&length(u)==1
			fprintf('tag %d %s',u.tag,u.asset);
		elseif isstruct(u)
			fprintf('struct[%d]',length(u))
		elseif ischar(u)&size(u,1)==1
			fprintf('%s',u)
		elseif ~isempty(u)
			fprintf('%d',length(u))
		end
		fprintf('\n')
		fnr='     ';
	end	% for j
end	% for i
