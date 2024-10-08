function eiPlot_plotPairwisePeaks( infodata, infofield, infopeaks, ...
  destswanted, srcswanted, sigthreshold, ampztype, colmapamp, colmaplag, ...
  ampunits, titleprefix, outfilepat )

% function eiPlot_plotPairwisePeaks( infodata, infofield, infopeaks, ...
%   destswanted, srcswanted, sigthreshold, ampztype, colmapamp, colmaplag, ...
%   ampunits, titleprefix, outfilepat )
%
% This generates heatmap plots of peak pairwise shared information (and the
% time lags associated with these peaks) for all desired channel pairs.
%
% "infodata" is a data structure with pairwise shared information as a
%   function of time and delay, per TIMEWINLAGDATA.txt.
% "infofield" is the fieldname within "infodata" that contains data to be
%   plotted (e.g. 'xcorrsingle', 'mutualavg', etc).
% "infopeaks" is a structure containing the amplitude and delay of peak
%   pairwise information as a function of time, per TIMEWINLAGPEAKS.txt.
% "destswanted" is a cell array containing destination channels to consider,
%   or {} to use all destination channels.
% "srcswanted" is a cell array containing source channels to consider, or
%   {} to use all source channels.
% "sigthreshold" is the minimum significant peak amplitude expressed as
%   standard deviations above background, or NaN to plot all peaks.
% "ampztype" is 'symm' or 'asymm', per eiPlot_getZRange().
% "colmapamp" is the colormap to use for amplitude values.
% "colmaplag" is the colormap to use for delay values.
% "ampunits" is the color scale label for amplitude, or '' for no label.
% "titleprefix" is a prefix to use when building plot titles.
% "outfilepat" is a sprintf() pattern to use when generating plot filenames.
%   This should have two '%s' codes, for type (amp/lag) and for destination,
%   in that order.
%
% No return value.



% Get raw data metadata.

pm = eiPlot_getChanTimeLagMetadata( ...
  infodata, infofield, destswanted, srcswanted, ampztype );


% Get significance test metadata.

[ data_mean data_dev ] = eiCalc_getPerPairMeanDev( infodata, infofield );


% Get plotting metadata.

lagrange = max( abs(infopeaks.peaklags), [], 'all' );
lagrange = max(lagrange, 1e-3);
lagrange = [ -lagrange, lagrange ];



%
% Render the plots.

thisfig = figure();
figure(thisfig);

for destidx = 1:pm.destcount

  % Figure out which sources were valid for this destination.

  srcmask = pm.pairmask(destidx,:);

  if ~any(srcmask)
    % Nothing to plot for this destination.
    continue;
  end


  % Get the peak data for this destination and mask it by source.

  ampslice = infopeaks.peakamps(destidx,:,:);
  lagslice = infopeaks.peaklags(destidx,:,:);

  % The slices are indexed by (source, time).
  ampslice = reshape( ampslice, pm.srccount, pm.timecount );
  lagslice = reshape( lagslice, pm.srccount, pm.timecount );

  % NaN out invalid data, rather than removing it, for consistent plot size.
  ampslice(~srcmask,:) = NaN;
  lagslice(~srcmask,:) = NaN;


  % Squash any peaks that weren't significantly above background.

  if ~isnan(sigthreshold)
    zdata = zeros(size(ampslice));

    for srcidx = 1:pm.srccount
      thismean = data_mean(destidx,srcidx);
      thisdev = data_dev(destidx,srcidx);
      % Indexed by (source, time).
      zdata(srcidx,:) = ( ampslice(srcidx,:) - thismean ) / thisdev;
    end

    % Check Z-scored peak values against the significance threshold.
    sigmask = ( abs(zdata) >= sigthreshold );

    % Squash any peaks that weren't significant.
    ampslice(~sigmask) = NaN;
    lagslice(~sigmask) = NaN;
  end


  % Tolerate nonuniform time series.

  [ ampslice, thistimeseries, scratch ] = ...
    nlProc_padHeatmapGaps( ampslice, pm.timelist_ms, 1:pm.srccount );
  [ lagslice, thistimeseries, scratch ] = ...
    nlProc_padHeatmapGaps( lagslice, pm.timelist_ms, 1:pm.srccount );


  %
  % Plot amplitude.

  clf('reset');
  colormap(thisfig, colmapamp);

  nlPlot_axesPlotSurface2D( gca, ampslice, ...
    thistimeseries, pm.srctitles, [], [], ...
    'linear', 'linear', 'linear', ...
    'Time (ms)', 'Source', ...
    [ titleprefix ' - Peak Amp to ' pm.desttitles{destidx} ] );

  clim(pm.zrange);

  thiscol = colorbar;
  if ~isempty(ampunits)
    thiscol.Label.String = ampunits;
  end

  % Make the figure taller if necessary.
  [ oldpos newpos ] = nlPlot_makeFigureTaller( thisfig, pm.srccount, 30 );
  thisfig.Position = newpos;

  saveas( thisfig, sprintf(outfilepat, 'amp', pm.destlabels{destidx}) );

  thisfig.Position = oldpos;


  %
  % Plot lag.

  clf('reset');
  colormap(thisfig, colmaplag);

  nlPlot_axesPlotSurface2D( gca, lagslice, ...
    thistimeseries, pm.srctitles, [], [], ...
    'linear', 'linear', 'linear', ...
    'Time (ms)', 'Source', ...
    [ titleprefix ' - Peak Lag to ' pm.desttitles{destidx} ] );

  clim(lagrange);

  thiscol = colorbar;
  thiscol.Label.String = 'Delay (ms)';

  % Make the figure taller if necessary.
  [ oldpos newpos ] = nlPlot_makeFigureTaller( thisfig, pm.srccount, 30 );
  thisfig.Position = newpos;

  saveas( thisfig, sprintf(outfilepat, 'lag', pm.destlabels{destidx}) );

  thisfig.Position = oldpos;

end

close(thisfig);



% Done.
end


%
% This is the end of the file.
