classdef python_extensions < handle
	%python_extensions - class handling some functionality easier to do in Python

	% see remarks in mat_extensions.py, related to the question of using a
	%    python class or just a python module (which has effect here!)

	properties
		mat
	end		% properties

	methods
		function c = python_extensions()
			myPth = fileparts(which(mfilename()));
			cDir = pwd;
			cd(fullfile(myPth,'python'))
			pyt = py.importlib.import_module('mat_extensions');
			c.mat = pyt.MatlabExtensions();
			cd(cDir)
		end		% python_extensions

		function x = url_bin_read(c,url)
			x = uint8(c.mat.url_bin_read(url));
		end		% url_bin_read
	end		% methods
end		% python_extensions