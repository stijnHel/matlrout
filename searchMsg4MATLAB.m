function Mout=searchMsg4MATLAB(in,matName)
%searchMsg4MATLAB - Searches for matlab-files in msg-files
%   M=searchMsg4MATLAB(msg-filename)
%   M=searchMsg4MATLAB(msg-structure)	% see readMScompDoc
%   searchMsg4MATLAB(in,filename)
%   searchMsg4MATLAB(in,0)	% uses default name
%   searchMsg4MATLAB(in,directory)	% write to a directoy

S=retrieveAttachments(in);
i=strmatch('.mat',lower({S.extension}));
M=S(i);

if nargin>1
	bNewName=false;
	if ischar(matName)
		if exist(matName,'dir')
			fPath=matName;
			if fPath(end)~=filesep
				fPath(1,end+1)=filesep;
			end
		else
			[fpth,fnm]=fileparts(matName);
			if ~isempty(fpth)
				fnm=[fpth filesep fnm];
			end
			bNewName=true;
		end
	else
		fPath=[pwd filesep];
	end
	for i=1:length(M)
		if bNewName
			if length(M)==1
				fName=[fnm,'.mat'];
			else
				fName=[fnm,num2str(i),'.mat'];
			end
		else
			fName=[fPath M(i).longF];
		end
		fid=fopen(fName,'w');
		if fid<3
			error('Can''t open a file for writing')
		end
		fwrite(fid,M(i).contents);
		fclose(fid);
		fprintf('file "%s" created.\n',fName)
	end
end

if nargout
	Mout=M;
end
