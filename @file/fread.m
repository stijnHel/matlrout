function X=fread(F,varargin)
%file/fread - Read from file
%       X=fread(F,...);
%          similar to base fread-function, but on file-object

X=fread(F.fid,varargin{:});
