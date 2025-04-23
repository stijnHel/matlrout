function Lout = setup_python(env,execMode)
%setup_python - Setup python (for this computer!)
%    setup_python() - setup for default python environment
%    setup_python(env) - setup using anaconda environment
%    L = setup_python('list') - returns a list of environments
%
%    setup_python(env,execution_mode) - to use a non-default execution mode
%            example: setup_python('vision',"OutOfProcess")

pth = 'C:\Users\stijn.helsen\Anaconda3\envs';

if nargin==0 || isempty(env)
	env = 'vision';
end
if ischar(env)
	if strcmp(env,'list')
		d = dir(pth);
		B = [d.isdir] & ~startsWith({d.name},'.');
		L = {d(B).name};
		if nargout
			Lout = L;
		else
			fprintf('Python (conda) environments:\n')
			printstr(L)
		end
		return
	elseif any(env=='\')
		pth = env;
	else
		pth = fullfile(pth,env,'python');
	end
	if nargin<2 || isempty(execMode)
		pyenv(Version=pth);
	else
		pyenv(Version=pth, ExecutionMode=execMode);
	end
else
	error('Unexpected input?!')
end
