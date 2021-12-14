function ChangeVarInMAT(fName,typ,var,new)
%ChangeVarInMAT - Change variable name/value in MAT file
%      ChangeVarInMAT(fName,'name',<var>,<new name>)
%      ChangeVarInMAT(fName,'value',<var>,<new value>)

X=load(fName);

switch typ
	case 'name'
		v=X.(var);
		X=rmfield(X,var);
		X.(new)=v;
	case 'value'
		X.(var)=new;
	otherwise
		error('Wrong use of this function - bad type of change')
end
save(fName,'-struct','X')
