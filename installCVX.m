%installCVX - Installs the CVX-toolbox (optimizer)

if exist('fullCVXsetup','var')
	curDir = pwd;
	cd 'C:\Users\SHEL\Documents\MATLAB\cvx'
	cvx_setup
	cd(curDir)
else
	run C:\Users\SHEL\Documents\MATLAB\cvx\cvx_startup.m
end
