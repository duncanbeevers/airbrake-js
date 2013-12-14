# A Sourcemaps-aware processor
# This processor runs the error through an underlying processor,
# then translates the output to file/line pairs as indicated by
# the sourcemaps it obtains
obtainMany = (backtrace_files, obtainer, source_maps, allObtained) ->
  obtainOne = (url, obtainer) ->
    obtainer.obtain url, (json) ->
      consumer = undefined
      if json
        consumer = new SourceMapConsumer(json)

        # As each sourcemaps json payload is obtained,
        # generate a sourcemap consumer from it, and cache it
        source_maps[url] = consumer
      allObtained source_maps  unless --remaining

  remaining = backtrace_files.length
  for backtrace_file in backtrace_files
    obtainOne backtrace_file, obtainer

SourcemapsProcessor = (preprocessor, obtainer) ->
  preprocessorComplete = (name, preprocessor_result, source_maps, fn) ->

    # Process the error through the native error handler

    # Collect the filenames of each file mentioned in the backtrace

    # Use an object to track whether an item as already been added to
    # the list of backtrace files to avoid scanning the list for each
    # each file

    # There may be several sourcemaps to obtain. Once all are available,
    # the processed error can be further processed using the the sourcemaps
    allObtained = (source_maps) ->
      backtrace_entry = undefined
      consumer = undefined
      original_position = undefined

      # Go line-by-line through the backtrace, substituting
      # SourceMapConsumer-supplied file names and positions
      # when available
      for backtrace_entry in preprocessor_backtrace
        consumer = source_maps[backtrace_entry.file]
        if consumer
          original_position = consumer.originalPositionFor(
            line: backtrace_entry.line
            column: backtrace_entry.column
          )
          backtrace_entry.file = original_position.source
          backtrace_entry.line = original_position.line
          backtrace_entry.column = original_position.column

      fn name + "+sourcemaps", preprocessor_result

    preprocessor_backtrace = preprocessor_result.backtrace
    backtrace_files = []
    backtrace_file = undefined
    cache = {}

    for backtrace_line in preprocessor_backtrace
      backtrace_file = backtrace_line.file
      unless cache[backtrace_file]
        cache[backtrace_file] = true
        backtrace_files.push backtrace_file

    # Begin obtaining the source maps
    obtainMany backtrace_files, obtainer, source_maps, allObtained

  @_source_maps = {}

  @process = (error, fn) ->
    source_maps = @_source_maps
    preprocessor.process error, (name, result) ->
      preprocessorComplete name, result, source_maps, fn

SourceMapConsumer = require("../lib/source-map/source-map-consumer").SourceMapConsumer
module.exports = SourcemapsProcessor
