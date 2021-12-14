function A=retrieveAttachments(in)
%retrieveAttachments - Retrieve attachments from msg-file
%   A=retrieveAttachments(msg-filename)
%   A=retrieveAttachments(msg-structure)	% see readMScompDoc

if ischar(in)
	S=readMScompDoc(in);
else
	S=in;
end

iAtt=strmatch('__attach_version',{S.name});
D=cell(1,length(iAtt));
A=struct('filename',D,'extension',D,'longF',D,'MIME',D		...
	,'contents',D);

Ssubst='__substg';
for i=1:length(iAtt)
	T=S(iAtt(i)).children;
	for j=1:length(T)
		if strncmp(T(j).name,Ssubst,length(Ssubst))
			data=T(j).data;
			switch T(j).name(end-3:end)
				case '001E'
					data=char(data);
				case '001F'
					data=char([1 256]*reshape(data,2,[]));
			end
			switch T(j).name(end-7:end-4)
				case '3701'
					A(i).contents=data;
				case '3703'
					A(i).extension=data;
				case '3704'
					A(i).filename=data;
				case '3707'
					A(i).longF=data;
				case '370E'
					A(i).MIME=data;
				case '3712'
					A(i).contents=data;
			end
		end
	end
end
