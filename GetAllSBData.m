function X=GetAllSBData(block)
%GetAllSBData - Get all data of a Simulink Block
%      X=GetAllSBData(block)

X=get_param(block,'ObjectParameters');
fn=fieldnames(X);
for i=1:length(fn)
	try
		X.(fn{i})=get_param(block,fn{i});
	catch err
		X.(fn{i})=struct('getError',err);
	end
end
