###
  Scene Graph plugin v{!major!}.{!minor!}.{!maintenance!}.{!build!} for Phaser
###

"use strict"

{freeze, seal} = Object

{extend} = Phaser.Utils

Phaser.Plugin.SceneGraph = freeze class SceneGraph extends Phaser.Plugin

  {group, groupCollapsed, groupEnd, log} = console

  none = ->

  log            = log.bind console
  group          = if group          then group.bind(console)          else log
  groupEnd       = if group          then groupEnd.bind(console)       else none
  groupCollapsed = if groupCollapsed then groupCollapsed.bind(console) else group

  _join = []

  join = (arr, str) ->
    _join.length = 0
    for i in arr when i
      _join.push i
    _join.join str

  @config = freeze
    css: freeze
      dead:          "text-decoration: line-through"
      nonexisting:   "color: gray"
      nonrenderable: "background: rgba(127, 127, 127, 0.125)"
      invisible:     "background: rgba(0, 0, 0, 0.25)"
    quiet: no

  @types = types = { 0: "SPRITE", 1: "BUTTON", 2: "IMAGE", 3: "GRAPHICS", 4: "TEXT", 5: "TILESPRITE", 6: "BITMAPTEXT", 7: "GROUP", 8: "RENDERTEXTURE", 9: "TILEMAP", 10: "TILEMAPLAYER", 11: "EMITTER", 12: "POLYGON", 13: "BITMAPDATA", 14: "CANVAS_FILTER", 15: "WEBGL_FILTER", 16: "ELLIPSE", 17: "SPRITEBATCH", 18: "RETROFONT", 19: "POINTER", 20: "ROPE", 21: "CIRCLE", 22: "RECTANGLE", 23: "LINE", 24: "MATRIX", 25: "POINT", 26: "ROUNDEDRECTANGLE", 27: "CREATURE", 28: "VIDEO"}

  @VERSION = "{!major!}.{!minor!}.{!maintenance!}.{!build!}"

  @addTo = (game) ->
    game.plugins.add this

  name: "Scene Graph Plugin"

  # Hooks

  init: (settings) ->
    @config = extend yes, {}, @constructor.config
    seal @config
    extend yes, @config, settings if settings
    unless @config.quiet
      log "%s v%s 👾", @name, @constructor.VERSION
      log "Use `game.debug.graph()` or `game.debug.graph(obj)`"
      @printStyles()
    Phaser.Utils.Debug::graph = @graph.bind this
    return

  # Helpers

  css: (obj) ->
    {css} = @config
    [
       css.invisible     if obj.visible    is false
       css.nonexisting   if obj.exists     is false
       css.nonrenderable if obj.renderable is false
       css.dead          if obj.alive      is false
    ].join ";"

  getKey: getKey = (obj) ->
    {key} = obj
    switch
      when !key    then null
      when key.key then getKey key
      else key

  getName: getName = (obj) ->
    {frame, frameName, name} = obj
    key = getKey obj
    join [name, join [key, frame], "."], " "

  graph: (obj = @game.stage, options = {
    collapse:        yes
    filter:          null
    map:             null
    skipDead:        no,
    skipNonexisting: no
  }) ->
    {collapse, filter, map, skipDead, skipNonexisting} = options
    {alive, children, exists} = obj

    return if (skipDead        and not alive)  or
              (skipNonexisting and not exists) or
              (filter          and not filter obj)

    hasChildren = children?.length > 0
    method      = if hasChildren then (if collapse then groupCollapsed else group) else log
    description = (if map then map else @map).call null, obj, options

    method "%c#{description}", @css obj
    @graph child, options for child in children if hasChildren
    groupEnd() if hasChildren
    return

  map: (obj) ->
    {children, constructor, total, type} = obj

    longName    = getName obj
    length      = children?.length or 0 # Button, Group, Sprite, Text …
    hasLength   = obj.length?           # Group, Emitter, Line(!)
    hasLess     = total and total < length
    type        = types[type] or '?'
    count       = switch
                  when hasLess   then "(#{total}/#{length})"
                  when hasLength then "(#{length})"
                  else                ""

    "#{constructor?.name or type} #{longName} #{count}"

  printStyles: ->
    log "Objects are styled:"
    for name, style of @config.css
      log "%c#{name}", style
    return
