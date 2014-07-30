#
# Heavily influenced by gettext and i18n-node{,-2}
#

path = require 'path'

fs = require 'fs-plus'
CSON = require 'season'

DEFAULT_LOCALE = 'C'
IS_DEBUG_MODE = atom.getLoadSettings().devMode

class Domain
  constructor: ({@name, @path, locale}) ->
    @locales = {}
    @setLocale locale

  setLocale: (locale) ->
    @locale = locale ? DEFAULT_LOCALE

  toMinimalApi: ->
    return {
      __: @__.bind @
      __p: @__p.bind @
      __n: @__n.bind @
    }

  # gettext
  __: (msgid) ->
    @__p '', msgid

  # pgettext
  __p: (msgctxt, msgid) ->
    unless @locale?
      return msgid

    dict = @_loadLocale()
    unless dict?
      console.error "Could not load dict for locale: #{@locale}"
      return msgid

    unless (ctxt = dict[msgctxt])?
      ctxt = dict[msgctxt] = {}

    if (val = ctxt[msgid])?
      return val

    # Save and write new keys when in debug mode
    if IS_DEBUG_MODE
      ctxt[msgid] = msgid
      @_saveLocale()

    return msgid

  # ngettext
  __n: (msgid1, msgid2, n) ->
    # TODO Implement pluralization


  #
  # private
  #

  # TODO Security?
  _loadLocale: ->
    localeId = @locale
    unless @locales[localeId]?
      try
        dictPath = path.normalize "#{@path}/#{localeId}.cson"
        @locales[localeId] = CSON.readFileSync dictPath
      catch e
        console.warn "Dict does not exist: #{dictPath}", e
        @locales[localeId] = '': {}
    @locales[localeId]

  # TODO Security?
  _saveLocale: ->
    localeId = @locale
    locale = @locales[localeId] ?= '': {}
    try
      dictPath = path.normalize "#{@path}/#{localeId}.cson"
      tmpPath = "#{dictPath}.tmp"
      CSON.writeFileSync tmpPath, locale
      if fs.statSync(tmpPath).isFile()
        fs.renameSync tmpPath, dictPath
      else
        console.error "Cannot save locale '#{localeId}' to '#{tmpPath}'"
    catch e
      console.error "Cannot save locale: '#{localeId}' '#{dictPath}'", e


module.exports =
class I18n
  constructor: (opts={}) ->
    @domains = {}
    @setLocale opts.locale

  registerDomain: (domainName, domainDirPath) ->
    # TODO handle re-registration of domain
    domain = @domains[domainName] = new Domain
      name: domainName
      path: domainDirPath
      locale: @locale
    domain

  unregisterDomain: (domainName) ->
    delete @domains[domainName]
    return

  setLocale: (locale) ->
    @locale = locale ? DEFAULT_LOCALE
    for domainName, domain of @domains
      domain.setLocale locale
    @locale
