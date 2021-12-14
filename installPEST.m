function installPEST
%installPEST - Install PEST toolbox

if ~exist('opti','file')
	installOpti
end
if ~exist('deopt','file')
	installDET
end
dPEST='C:\Users\shel\Documents\MATLAB\PEsT_v4.0\pest';
addpath(genpath(dPEST))

rehash
