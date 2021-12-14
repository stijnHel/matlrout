function pout=nonmatlabpath(bSupportPackages)
%nonmatlabpath - Gives the directories in the path which are non-matlab
%     p=nonmatlabpath;	--> gives the path in p (cell array)
%     nonmatlabpath		--> displays the path in the command window
%     ...nonmatlabpath(bSupportPackages) --> with / without extra packages
%                     default false (no support packages)

if nargin==0 || isempty(bSupportPackages)
	bSupportPackages = false;
end

p=[pathsep path pathsep];
MLroot=matlabroot;

if ~bSupportPackages
	supPath = 'C:\ProgramData\MATLAB\';
end

iS=find(p==pathsep);
P=cell(1,length(iS)-1);
B=true(size(P));
for i=1:length(P)
	P{i}=p(iS(i)+1:iS(i+1)-1);
	B(i)=~strncmp(P{i},MLroot,length(MLroot));
	if B(i) && ~bSupportPackages && startsWith(P{i},supPath)
		B(i) = false;
	end
end
P=P(B);
if nargout
	pout=P;
else
	fprintf('non-Matlab directories in the matlab-path:\n')
	fprintf('     %s\n',P{:})
end
