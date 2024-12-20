function anparams = eiCalc_getParamsPCorr( replicates, want_squared, flags )

% function anparams = eiCalc_getParamsPCorr( replicates, want_squared, flags )
%
% This creates a configuration structure suitable for use with the
% helper_analyzePCorr() analysis function.
%
% "replicates" is the number of replicates to use for bootstrapped variance
%   estimation, or 0 to not use bootstrapping.
% "want_squared" is true to report r^2 (and its variance) and false to
%   report r.
% "flags" is a cell array containing processing flags, per PROCFLAGS.txt.
%
% "anparams" is a configuration parameter structure passed to the analysis
%   helper function, per TIMEWINLAGFUNCS.txt.


anparams = struct();


% Store bootstrapping configuration.

anparams.replicates = replicates;


% Store the "want squared" switch.

anparams.want_squared = want_squared;


% Record the parallel processing flag.

anparams.want_parallel = ismember('parallel', flags);


% Done.
end


%
% This is the end of the file.
