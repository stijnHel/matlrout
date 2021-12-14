function [V,W]=GetScriptVars(IIIII_scriptName)
%GetScriptVars - Gives the names used in a script
%     GetScriptVars(scriptName)
%         Displays all variables defined in a script
%     [V,W]=GetScriptVars(scriptName)
%         V: a cell-vector with all variable names
%         W: a struct-vector (output from whos) with additional info like
%            size, class, ... ((!)nesting is related to this function!)
%  The script is run, and the variables created after the run are used.
%  It's not doing any statical code analysis, and it's run in the function
%  workspace, meaning that if the script is relying on variables in the
%  workspace this doesn't work (in this version).  (((this can be added!)))
%
%  see also: whos

eval(IIIII_scriptName)
clear IIIII_scriptName
if nargout
	W=whos;
	V={W.name};
else
	whos
end
