function Dout=GetUsedFunc(bAll)
%GetUsedFunc - Get functions currently used
%      Dout=GetUsedFunc(bAll)
%             bAll (default false): all functions
%                  true (or >0) files in Matlab root are removed
%                  -1: only remove standard Matlab files from list

if nargin==0
	bAll=false;
end

[mm,mmx]=inmem('-completenames');
mm=[mm;mmx];
mm=setdiff(mm,which(mfilename));	% remove this function(!)
dmm=mm;
B=true(1,length(mm));
mR=matlabroot; %#ok<MCMLR>
nmR=length(mR);
mRM1=fullfile(mR,'toolbox','matlab'); %#ok<MCTBX>
nmRM1=length(mRM1);
mRM2=fullfile(mR,'toolbox','local'); %#ok<MCTBX>
nmRM2=length(mRM2);
for i=1:length(mm)
	[dmm{i},mm{i}]=fileparts(mm{i});
	if ~islogical(bAll)&&bAll<0
		B(i)=~(strncmpi(dmm{i},mRM1,nmRM1)||strncmpi(dmm{i},mRM2,nmRM2));
	elseif ~bAll
		B(i)=~strncmpi(dmm{i},mR,nmR);
	end
end
if ~all(B)
	dmm=dmm(B);
	mm = mm(B);
end
[ud,~,iM]=unique(dmm);
D=struct('dir',ud,'files',[]);
for i=1:length(ud)
	D(i).files=sort(mm(iM==i));
end

if nargout
	Dout=D;
else
	c='-';
	for i=1:length(ud)
		fprintf('%s:\n%s\n',ud{i},c(ones(1,length(ud{i})+1)));
		fprintf('       %s\n',D(i).files{:});
		fprintf('\n')
	end
end
