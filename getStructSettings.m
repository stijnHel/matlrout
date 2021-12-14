function CS=getStructSettings(S)
%getStructSettings - get cell-vector with settings from struct-fields
%  CS=getStructSettings(S)

if ~isscalar(S)
	error('Sorry, but the settings-struct must be a scalar struct!')
end
CS=fieldnames(S)';
CS(2,:)=cell(1,length(S));
B=true(size(CS));
for i=1:length(CS)
	CS{2,i}=S.(CS{1,i});
	if islogical(CS{2,i})
		if CS{2,i}
			CS{1,i}=['-' CS{1,i}];
		else
			CS{1,i}=['--' CS{1,i}];
		end
		B(2,i)=false;
	end
end
CS=CS(B)';
