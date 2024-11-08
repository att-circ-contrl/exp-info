function anparams = eiCalc_getParamsMutualTE( ...
  bin_count_dest, bin_count_src, replicates, flags, exparams )

% function anparams = eiCalc_getParamsMutualTE( ...
%   bin_count_dest, bin_count_src, replicates, flags, exparams )
%
% This creates a configuration structure suitable for use with the
% helper_analyzeMutual() and helper_analyzeTransfer() analysis functions.
%
% "bin_count_dest" is the number of histogram bins to use when processing
%   signals from the destination Field Trip data set. This can be the
%   character vector 'discrete' to auto-bin discrete-valued data.
% "bin_count_src" is the number of histogram bins to use when processing
%   signals from the source Field Trip data set. This can be the character
%   vector 'discrete' to auto-bin discrete-valued data.
% "replicates" is the number of replicates to use for bootstrapped variance
%   estimation,  or 0 to not use bootstrapping.
% "flags" is a cell array containing processing flags, per PROCFLAGS.txt.
% "exparams" is a structure containing extrapolation tuning paramters, per
%   EXTRAPOLATION.txt in the conditional entropy library. If this is empty,
%   default parameters are used. If the character vector 'none' is supplied
%   instead of a structure, extrapolation is disabled.
%
% "anparams" is a configuration parameter structure passed to the
%   relevant analysis functions, per TIMEWINLAGFUNCS.txt.


anparams = struct();


% Store bin counts and "is discrete" flags.

anparams.bins_dest = bin_count_dest;
anparams.bins_src = bin_count_src;

anparams.discrete_dest = ischar(bin_count_dest);
anparams.discrete_src = ischar(bin_count_src);


% Store bootstrapping configuration.

anparams.replicates = replicates;


% Figure out if we want extrapolation, and store a structure if so.

anparams.extrap_config = exparams;
anparams.want_extrap = isstruct(exparams);


% Record the parallel processing flag.

anparams.want_parallel = ismember('parallel', flags);


% Done.
end


%
% This is the end of the file.
