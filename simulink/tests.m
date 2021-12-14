function [sys,x0]=tests(t,x,u,flag,p);
% TESTS	is a M-file to read all results in a simulation
global testvar itestvar
if ~exist('p');p=[];end
if flag==0
	x0=[];
	sys=[0;0;0;-1;0;1];
	itestvar=0;
	testvar=[];
elseif flag<9
	if itestvar>0
		stokvar=[p,flag t u(:)'];
		if length(stokvar)<size(testvar,2)
			stokvar=[p-10,flag t u(:)'];
			fprintf('stokvar verlengd %2d --> %2d\n',length(stokvar),size(testvar,2));
			stokvar=[stokvar zeros(1,size(testvar,2)-length(stokvar))];
		end
			if itestvar>length(testvar)
				testvar=[testvar;zeros(1000,length(stokvar))];
			end
		testvar(itestvar,:)=stokvar;
	end
	itestvar=itestvar+1;
else
	sys=[];
	itestvar=itestvar-1;
	testvar=testvar(1:itestvar,:);
end
