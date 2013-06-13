var match_message_file_line_column = /\s+([^\(]+)\s+\((.*):(\d+):(\d+)\)/;

function recognizeFrame(string) {
  var func,
      file,
      line,
      column;

  var match;

  match = string.match(match_message_file_line_column);
  if (match) {
    func   = match[1];
    file   = match[2];
    line   = match[3];
    column = match[4];
  }

  // Function falls back to entire string if
  // the function name can't be extracted
  func = func || string;

  return {
    file: file || "unsupported.js",
    line: line || 0,
    "function": func
  };
}

function FallbackProcessor() {}

FallbackProcessor.prototype = {
  process: function(error) {
    var backtrace = [], i,
        stack = (error.stack || "").split("\n");

    var error_type = stack[0].match(/\s*([^:]+)/)[1],
        error_message = error.message;

    for (i = stack.length - 1; i >= 0; i--) {
      backtrace[i] = recognizeFrame(stack[i]);
    }

    return {
      type: error_type,
      message: error_message,
      backtrace: backtrace
    };
  }
};

module.exports = FallbackProcessor;