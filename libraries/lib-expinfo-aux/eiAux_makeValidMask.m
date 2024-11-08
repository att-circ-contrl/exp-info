function [ ampgoodmask laggoodmask ] = eiAux_makeValidMask( ...
  ampmean, ampdev, lagmean, lagdev, accept_config )

% function [ ampgoodmask laggoodmask ] = eiAux_makeValidMask( ...
%   ampmean, ampdev, lagmean, lagdev, accept_config )
%
% This generates masks indicating whether the specified pairwise information
% peak amplitudes and time lags are valid.
%
% This tolerates NaN values.
%
% "ampmean" is a matrix indexed by (destidx,srcidx,trialidx) with mean
%   pairwise information peak amplitude values.
% "ampdev" is a matrix indexed by (destidx,srcidx,trialidx) with the standard
%   deviation of pairwise information peak amplitude values.
% "lagmean" is a matrix indexed by (destidx,srcidx,trialidx) with mean
%   pairwise information peak time lag values.
% "lagdev" is a matrix indexed by (destidx,srcidx,trialidx) with the standard
%   deviation of pairwise information peak time lag values.
% "accept_config" is a structure with the following fields:
%   "max_amp_dev" is the largest accepted amplitude standard deviation.
%   "max_lag_dev" is the largest accepted time lag standard deviation.
%   "min_amp_for_lag" is the minimum absolute value of the amplitude that
%     must be present for the time lag estimate to be considered valid.
%   "min_amp_rel_for_lag" is the minimum absolute value of the amplitude as
%     a fraction of the maximum absolute value that must be present for the
%     time lag estimate to be considered valid.
%
% "ampgoodmask" is a matrix indexed by (destidx,srcidx,trialidx) that's true
%   for valid amplitudes and false otherwise.
% "laggoodmask" is a matrix indexed by (destidx,srcidx,trialidx) that's true
%   for valid time lags and false otherwise.


% NOTE - We aren't actually using "lagmean"! It's included for consistency
% in calling conventions, for now.


% First pass: Do the "was this well-behaved" checks, using standard deviation.

max_amp_dev = accept_config.max_amp_dev;
max_lag_dev = accept_config.max_lag_dev;

ampgoodmask = (ampdev <= max_amp_dev);
laggoodmask = (lagdev <= max_lag_dev);


% Second pass: Do the "could we actually get a lag estimate" checks.
% The relative amplitude check has to be evaluated per-trial.

min_amp_for_lag = accept_config.min_amp_for_lag;
min_amp_rel_for_lag = accept_config.min_amp_rel_for_lag;

hadamp = nan(size(ampgoodmask));

for tidx = 1:size(hadamp,3)

  ampslice = abs( ampmean(:,:,tidx) );
  maxamp = max( ampslice, [], 'all' );

  this_min_amp = max( min_amp_for_lag, ...
    maxamp * min_amp_rel_for_lag );

  hadamp(:,:,tidx) = ( ampslice >= this_min_amp );

end

% FIXME - Assume that if the amplitude varied a lot (large deviation),
% we _did_ have enough high-amplitude samples for a valid time lag estimate.

largedevmask = (~ampgoodmask) &(~isnan(ampdev));
hadamp(largedevmask) = true;

% Apply the "we had high enough amplitude to estimate lag" mask.
laggoodmask = laggoodmask & hadamp;


% Done.
end


%
% This is the end of the file.
