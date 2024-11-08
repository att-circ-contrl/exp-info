function result = eiCalc_helper_analyzePCorr( ...
  wavedest, wavesrc, samprate, delaylist, params )

% function result = eiCalc_helper_analyzeMutual( ...
%   wavedest, wavesrc, samprate, delaylist, params )
%
% This is an analysis function, per TIMEWINLAGFUNCS.txt.
%
% This calculates time-lagged Pearson's correlation between the supplied
% signals. If multiple trials are supplied, the trials are concatenated.
%
% "wavedest" and "wavesrc" are expected to be either 1 x Nsamples vectors
%   or Ntrials x Nsamples matricies containing signal data.
% "params" contains the following fields:
%   "replicates" is the number of replicates to use for bootstrapped variance
%     estimation, or 0 to not use bootstrapping.
%   "want_parallel" is true to use the multithreaded implementation and
%     false otherwise.
%   "want_squared" is true to report r^2 and false to report r.


% Check for the empty case (querying result fields).

if isempty(wavedest) || isempty(wavesrc) || isempty(delaylist)
  result = struct( 'pcorr', [] );
  return;
end


% Get geometry.

if isrow(wavedest) || iscolumn(wavedest)
  % We were given one-dimensional vectors. Make sure they're rows.
  wavedest = reshape( wavedest, 1, [] );
  wavesrc = reshape( wavesrc, 1, [] );
end

trialcount = size(wavedest,1);
sampcount = size(wavedest,2);


% Package the data.

scratchdata = { wavedest, wavesrc };


% Calculate time-lagged Pearson's correlation.

if params.want_parallel
  [ rlist rvars ] = cEn_calcLaggedPCorr_MT( ...
    scratchdata, delaylist, params.replicates );
else
  [ rlist rvars ] = cEn_calcLaggedPCorr_MT( ...
    scratchdata, delaylist, params.replicates );
end


% If we were asked for r^2, modify rlist and rvars.

if params.want_squared

  rlist = rlist .* rlist;

  % For standard deviation much smaller than the mean, variance of r^2 is
  % approximately: 4 * r^2 * var(r)
  % If I'm doing the math right, for normal distributions the full
  % expression is: 4 * r^2 * var(r) + 2 * var(r)^2

  rvars = (4 * rlist .* rvars) + (2 * rvars .* rvars);

end


% Store this in an appropriately-named field.

result = struct();
result.pcorrdata = rlist;
result.pcorrvar = rvars;
% FIXME - Ignore trial trimming.
result.pcorrcount = ones(size( rlist )) * trialcount * sampcount;


% Done.
end


%
% This is the end of the file.
