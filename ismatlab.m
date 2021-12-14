function b=ismatlab()
%ismatlab - Indicates if the environment is Matlab (and not Octave)
%       b=ismatlab()

v=ver;
b=any(strcmp({v.Name},'MATLAB'));
