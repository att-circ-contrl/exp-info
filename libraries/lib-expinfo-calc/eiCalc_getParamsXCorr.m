function [ preconfig anparams ] = ...
  eiCalc_getParamsXCorr( detrend_method, norm_method )

% function [ preconfig anparams ] = ...
%   eiCalc_getParamsXCorr( detrend_method, norm_method )
%
% This creates a preprocessing configuration list and an analysis
% configuration structure suitable for use with the helper_analyzeXCorr()
% analysis function.
%
% "detrend_method" is 'detrend', 'zeromean', or 'none'.
% "norm_method" is the normalization method to pass to "xcorr". This is
%   typically 'unbiased' (to normalize by sample count) or 'coeff' (to
%   normalize so that self-correlation is 1).
%
% "preconfig" is a cell array containing preprocessing configuration flags.
% "anparams" is a configuration structure passed to helper_analyzeXCorr(),
%   per TIMEWINLAGFUNCS.txt.


% Preprocessing configuration.
% Support the old "demean" syntax as well as "zeromean".

preconfig = {};

if strcmp('detrend', detrend_method)
  preconfig = { 'detrend' };
elseif strcmp('zeromean', detrend_method) || strcmp('demean', detrend_method)
  preconfig = { 'zeromean' };
end


% Analysis configuration.
% Just copy this as-is to the configuration structure.

anparams = struct();
anparams.('norm_method') = norm_method;


% Done.
end


%
% This is the end of the file.
