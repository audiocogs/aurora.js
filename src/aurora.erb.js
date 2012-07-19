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
<%= Aurora.coffee 'filter.coffee' %>
