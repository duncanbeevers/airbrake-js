xhr = (url, fn) ->
  request = new global.XMLHttpRequest()
  request.open "GET", url, true
  request.send()
  request.onreadystatechange = ->
    if 4 == request.readyState
      fn request.responseText

# Extract the source maps url (if any) from a corpus of text
sourceMapUrl = (body) ->
  body_match = body.match(source_maps_matcher)
  body_match[1]  if body_match

# Convert a base64 data-uri to a (hopefully) JSON string
dataUri = (url) ->
  data_uri_match = url.match(data_uri_matcher)
  if data_uri_match
    decodeBase64 data_uri_match[1]

SourcemapsObtainer = ->
  scriptReceived = (body, obtained) ->
    url = sourceMapUrl(body)
    if url
      data_uri = dataUri(url)
      if data_uri
        obtained data_uri
      else
        xhr url, (json) ->
          obtained json

    else
      obtained null
  @obtain = (url, obtained) ->

    # Closure around `obtained`
    xhr url, (body) ->
      scriptReceived body, obtained

decodeBase64        = require("../util/base64_decode").decode
source_maps_matcher = /\/\/(?:@|#) sourceMappingURL=(.+)$/
data_uri_matcher    = /data:application\/json;base64,(.*)/

SourcemapsObtainer.sourceMapUrl = sourceMapUrl
SourcemapsObtainer.dataUri = dataUri
module.exports = SourcemapsObtainer
