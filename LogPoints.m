function varargout=LogPoints(label,data,bWarn)
%LogPoints - Log points in an array
%    LogPoints(<list-name>,data)
%    Data=LogPoints('get',<list-name>);
%    LogPoints('clear'[,<list-name>])

global LOGPOINTdata

if ~ischar(label)
	error('The first input must be a string, the list-label or "get"!')
elseif strcmp(label,'get')
	if nargin==1
		if isempty(LOGPOINTdata)
			if nargout
				varargout={};
			else
				fprintf('No logs available!\n')
			end
		elseif nargout
			varargout={{LOGPOINTdata.label}};
		else
			fprintf('The following logs are available:\n');
			L={LOGPOINTdata.label;LOGPOINTdata.nData};
			fprintf('     %-20s : #%4d points\n',L{:})
		end
	else
		if isempty(LOGPOINTdata)
			error('Can''t get data from an empty list!')
		end
		i=find(strcmp(data,{LOGPOINTdata.label}));
		if isempty(i)
			error('List not found!')
		else
			data=LOGPOINTdata(i).data(1:LOGPOINTdata(i).nData,:);
			varargout={data};
		end
	end
elseif strcmp(label,'clear')
	if nargin==1
		data='all';
	end
	if strcmp(data,'all')
		clear global LOGPOINTdata
	elseif isempty(LOGPOINTdata)
		if nargin<3||bWarn
			warning('No list exists!')
		end
	else
		b=strcmp(data,{LOGPOINTdata.label});
		if ~any(b)
			if nargin<3||bWarn
				warning('List not found!')
			end
		else
			LOGPOINTdata(b)=[];
		end
	end
else
	if size(data,2)==1&&size(data,1)>1
		data=data';
	end
	if isempty(LOGPOINTdata)
		bNewList=true;
	else
		i=find(strcmp(label,{LOGPOINTdata.label}));
		if isempty(i)
			bNewList=true;
		else
			bNewList=false;
			nData=LOGPOINTdata(i).nData;
			if size(data,2)~=size(LOGPOINTdata(i).data,2)
				warning('Log (%s) is restarted after %d points because of a different input size! (%d->%d)'	...
					,label,nData,size(LOGPOINTdata(i).data,2),size(data,2))
				nData=0;
				LOGPOINTdata(i).data=zeros(size(LOGPOINTdata(i).data,1),size(data,2));
			end
			if size(LOGPOINTdata(i).data,1)<size(data,1)+nData
				LOGPOINTdata(i).data(end+max(1000,round(nData/10)),1)=0;
			end
			LOGPOINTdata(i).data(nData+1:nData+size(data,1),:)=data;
			LOGPOINTdata(i).nData=nData+size(data,1);
		end
	end
	if bNewList
		L1=struct('label',label,'data',data,'nData',size(data,1));
		if isempty(LOGPOINTdata)
			LOGPOINTdata=L1;
		else
			LOGPOINTdata(end+1)=L1;
		end
	end
end
