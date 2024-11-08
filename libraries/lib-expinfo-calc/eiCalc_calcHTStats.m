function htdata = euCalc_calcHTStats( ...
  ftdata_first, ftdata_second, win_params, flags )

% function htdata = eiCalc_calcHTStats( ...
%   ftdata_first, ftdata_second, win_params, flags )
%
% This calculates the coherence, power correlation, and non-Gaussian power
% correlation between pairs of signals within two datasets using the methods
% described in Hindriks 2023. This is done for several time windows, and
% averaged across trials.
%
% NOTE - Both datasets must have the same sampling rate and the same number
% of trials (trials are assumed to correspond).
%
% NOTE - This applies the Hilbert transform to generate analytic signals;
% feeding oscillating signals into it is fine. Hindriks used it on
% narrow-band LFP signals.
%
% "ftdata_first" is a ft_datatype_raw structure with the first set of trials.
% "ftdata_second" is a ft_datatype_raw structure with the second set of trials.
% "win_params" is a structure giving time window information, per
%   TIMEWINLAGSPEC.txt. Delay information is ignored.
% "flags" is a cell array containing one or more of the following character
%   vectors:
%   'avgtrials' generates data averaged across trials, per TIMEWINLAGDATA.txt.
%   'pertrial' generates per-trial data, per TIMEWINLAGDATA.txt.
%
% "htdata" is a structure with the analysis data, per TIMEWINLAGDATA.txt.
%   Relevant fields are:
%   "coherenceXXX" is a matrix containing coherence values. These are
%     complex, with magnitudes between 0 and 1.
%   "powercorrelXXX" is a matrix containing power correlation values. These
%     are real, ranging from -1 to +1.
%   "nongaussXXX" is a matrix containing non-Gaussian power correlation
%     values. These are real, ranging from -1 to +1.


% Overwrite the delay configuration.
win_params.delay_range_ms = 0;
win_params.delay_step_ms = 1;


% We want to analyze analytic signals.
% NOTE - We're not detrending! We might want to.

htdata = eiCalc_doTimeAndLagAnalysis( ...
  ftdata_first, ftdata_second, win_params, flags, ...
  { 'hilbert' }, @helper_analysisfunc, struct(), ...
  {}, @eiCalc_helper_filterNone, struct() );


% Done.
end


%
% Helper Functions


function result = helper_analysisfunc( ...
  wavefirst, wavesecond, samprate, delaylist, params )

  if isempty(wavefirst) || isempty(wavesecond) || isempty(delaylist)
    % This is the empty case (querying result fields).
    result = struct( 'coherence', [], 'powercorrel', [], 'nongauss', [] );
  else

    % NOTE - We're supposed to return a vector with the same length as the
    % delay list.

    [ scratchcoherence scratchcorrel scratchnongauss ] = ...
      nlProc_compareSignalsHT( wavefirst, wavesecond );

    result = struct();

    scratchvec = zeros(size( delaylist ));
    countvec = ones(size( scratchvec ));
    varvec = nan(size( scratchvec ));

    scratchvec(:) = scratchcoherence;
    result.coherencedata = scratchvec;
    result.coherencecount = countvec;
    result.coherencevar = varvec;

    scratchvec(:) = scratchcorrel;
    result.powercorreldata = scratchvec;
    result.powercorrelcount = countvec;
    result.powercorrelvar = varvec;

    scratchvec(:) = scratchnongauss;
    result.nongaussdata = scratchvec;
    result.nongausscount = countvec;
    result.nongaussvar = varvec;

  end

end

%
% This is the end of the file.
