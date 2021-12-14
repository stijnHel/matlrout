function [L,X]=CheckMarginImg(X,varargin)
%CheckMarginImg - Check the margins of an image

[bWrite,fFileOut,fDefault	...
	,bBackup,fBackup]=deal(false,[],'_crop'	...
		,false,'_backup');
if nargin>1
	setoptions({'bWrite','fFileOut','fDefault','bBackup','fBackup'},varargin{:})
end

bRead=false;
Alpha=[];
if ischar(X)
	fName=X;
	[X,~,Alpha]=imread(fName);
	bRead=true;
elseif iscell(X)||isstruct(X)
	for i=1:length(X)
		if iscell(X)
			fName=X{i};
		else
			fName=X(i).name;
		end
		CheckMarginImg(fName,varargin{:})
	end
	return
end

i1=Inf;
i2=0;
j1=Inf;
j2=0;
for i=1:size(X,3)
	i_1=find(any(any(X~=255,3)),1,'first');
	i_2=find(any(any(X~=255,3)),1,'last');
	j_1=find(any(any(X~=255,3),2),1,'first');
	j_2=find(any(any(X~=255,3),2),1,'last');
	if ~isempty(i_1)
		i1=min(i1,i_1);
		i2=max(i2,i_2);
		j1=min(j1,j_1);
		j2=max(j2,j_2);
	end
end
if i1>i2
	warning('Empty image?!')
	i1=1;
	i2=10;
	j1=1;
	j2=10;
end
X=X(j1:j2,i1:i2,:);
if nargout
	L=[i1 i2;j1 j2];
end
if bWrite
	if isempty(fFileOut)
		if bRead
			if isempty(fDefault)
				fFileOut=fName;
			else
				[fP,fN,fE]=fileparts(fName);
				fFileOut=fullfile(fP,[fN fDefault,fE]);
			end
		else
			error('Default name is only possible if file is read in the function!')
		end
	end
	if bBackup
		if bRead
			fToRename=fName;
		else
			fToRename=fFileOut;
		end
		if exist(fToRename,'file')
			[fP,fN,fE]=fileparts(fToRename);
			fBackup=fullfile(fP,[fN fBackup,fE]);
			dos(['rename ' fToRename ' ' fBackup]);
		else
			warning('No file backed up!')
		end
	end
	if isempty(Alpha)
		imwrite(X,fFileOut)
	else
		imwrite(X,fFileOut,'Alpha',Alpha(j1:j2,i1:i2))
	end
end
