function addstdir
%addstdir  - Adds a specific matlrout directory

d=which('addstdir');
d=strrep(d,'addstdir.m','zonnew');
addpath(d,'-end')
