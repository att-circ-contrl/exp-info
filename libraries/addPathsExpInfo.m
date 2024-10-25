function addPathsExpInfo

% function addPathsExpInfo
%
% This function detects its own path and adds appropriate child paths to
% Matlab's search path.
%
% No arguments or return value.


% Detect the current path.

fullname = which('addPathsExpInfo');
[ thisdir fname fext ] = fileparts(fullname);


% Add the new paths.
% (This checks for duplicates, so we don't have to.)

addpath([ thisdir filesep 'lib-expinfo-aux' ]);
addpath([ thisdir filesep 'lib-expinfo-calc' ]);
addpath([ thisdir filesep 'lib-expinfo-plot' ]);


% Done.

end


%
% This is the end of the file.
