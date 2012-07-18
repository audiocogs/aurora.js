<%= Aurora.file 'LICENSE' %>

void function (global) {
	"use strict";

	global.Aurora = {}
}(this)

<%= Aurora.file 'core/object.js' %>

<%= Aurora.file 'core/buffer.js' %>
<%= Aurora.file 'core/buffer-list.js' %>

<%= Aurora.file 'core/stream.js' %>
<%= Aurora.file 'core/bit-stream.js' %>

<%= Aurora.file 'core/event-emitter.js' %>

<%= Aurora.file 'demuxer.js' %>
<%= Aurora.file 'decoder.js' %>

<%= Aurora.file 'queue.js' %>

<%= Aurora.coffee 'asset.coffee' %>
<%= Aurora.coffee 'player.coffee' %>

<%= Aurora.coffee 'device.coffee' %>
<%= Aurora.coffee 'devices/webkit.coffee' %>
<%= Aurora.coffee 'devices/mozilla.coffee' %>

<%= Aurora.coffee 'sources/http.coffee' %>
<%= Aurora.coffee 'sources/file.coffee' %>

<%= Aurora.coffee 'filter.coffee' %>
<%= Aurora.coffee 'filters/volume.coffee' %>
<%= Aurora.coffee 'filters/balance.coffee' %>
<%= Aurora.coffee 'filters/earwax.coffee' %>

<%= Aurora.coffee 'demuxers/caf.coffee' %>
<%= Aurora.coffee 'demuxers/m4a.coffee' %>
<%= Aurora.coffee 'demuxers/aiff.coffee' %>
<%= Aurora.coffee 'demuxers/wave.coffee' %>
<%= Aurora.coffee 'demuxers/au.coffee' %>

<%= Aurora.coffee 'decoders/lpcm.coffee' %>
<%= Aurora.coffee 'decoders/xlaw.coffee' %>
