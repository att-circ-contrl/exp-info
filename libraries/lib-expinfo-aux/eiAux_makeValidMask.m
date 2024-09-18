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
% "ampmean" is a matrix indexed by (destidx,srcidx) with mean
%   pairwise information peak amplitude values.
% "ampdev" is a matrix indexed by (destidx,srcidx) with the standard
%   deviation of pairwise information peak amplitude values.
% "lagmean" is a matrix indexed by (destidx,srcidx) with mean
%   pairwise information peak time lag values.
% "lagdev" is a matrix indexed by (destidx,srcidx) with the standard
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
% "ampgoodmask" is a matrix indexed by (destidx,srcidx) that's true
%   for valid amplitudes and false otherwise.
% "laggoodmask" is a matrix indexed by (destidx,srcidx) that's true
%   for valid time lags and false otherwise.


% NOTE - We aren't actually using "lagmean"! It's included for consistency
% in calling conventions, for now.


max_amp_dev = accept_config.max_amp_dev;
max_lag_dev = accept_config.max_lag_dev;
min_amp_for_lag = accept_config.min_amp_for_lag;
min_amp_rel_for_lag = accept_config.min_amp_rel_for_lag;

% Convert the relative amplitude into an absolute amplitude and merge with
% the absolute amplitude constraint.
maxamp = max(max( abs(ampmean) ));
min_amp_for_lag = max( min_amp_for_lag, maxamp * min_amp_rel_for_lag );


ampgoodmask = (ampdev <= max_amp_dev);
laggoodmask = (lagdev <= max_lag_dev);

hadamp = ( abs(ampmean) >= min_amp_for_lag );

% FIXME - Assume that if the amplitude varied a lot, we _did_ have enough
% high-amplitude samples for a valid time lag estimate.
hadamp(~ampgoodmask) = true;

laggoodmask = laggoodmask & hadamp;


% Done.
end


%
% This is the end of the file.
