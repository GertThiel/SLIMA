{CompositeDisposable, Point, Range} = require 'atom'
Swank = require 'swank-client-js'
AtomSlimeView = require './atom-slime-view'
paredit = require 'paredit.js'
slime = require './slime-functions'
AtomSlimeEditor = require './atom-slime-editor'
SlimeAutocompleteProvider = require './slime-autocomplete'
SwankStarter = require './swank-starter'

module.exports = AtomSlime =
  views: null
  subs: null
  asts: {}
  pkgs: {}
  process: null
  maxConnectionAttempts: 5

  # Provide configuration options
  config:
    slimePath:
      title: 'Slime Path'
      description: 'Path to where SLIME resides on your computer.'
      type: 'string'
      default: '/home/username/Desktop/slime'

    lispName:
      title: 'Lisp Process'
      description: 'Name of Lisp to run'
      type: 'string'
      default: 'sbcl'

  activate: (state) ->
    # Setup a swank client instance
    @setupSwank()
    @views = new AtomSlimeView(state.viewsState, @swank)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subs = new CompositeDisposable
    @ases = new CompositeDisposable

    # Setup connections
    @subs.add atom.commands.add 'atom-workspace', 'slime:start': => @swankStart()
    @subs.add atom.commands.add 'atom-workspace', 'slime:connect': => @swankConnect()
    @subs.add atom.commands.add 'atom-workspace', 'slime:hide': => @views.repl.hide()
    @subs.add atom.commands.add 'atom-workspace', 'slime:show': => @views.repl.show()
    #@subs.add atom.commands.add 'atom-workspace', 'slime:show-debugger': => @views.repl.showDebugger true
    #@subs.add atom.commands.add 'atom-workspace', 'slime:hide-debugger': => @views.repl.showDebugger false

    @subs.add atom.commands.add 'atom-workspace', 'slime:testfn': =>
      utils = require "./utils"
      file = "/home/steve/Desktop/atom-slime/lib/utils.coffee"
      index = 5
      utils.openFileToIndex(file, index)

    # Keep track of all Lisp editors
    @subs.add atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name == "Lisp"
        ase = new AtomSlimeEditor(editor, @views.statusView, @swank)
        @ases.add ase
      else
        editor.onDidChangeGrammar =>
          if editor.getGrammar().name == "Lisp"
            ase = new AtomSlimeEditor(editor, @views.statusView, @swank)
            @ases.add ase


  # Sets up a swank client but does not connect
  setupSwank: () ->
    @swank = new Swank.Client("localhost", 4005);
    @swank.on 'disconnect', =>
      console.log "Disconnected!"

  # Start a swank server and then connect to it
  swankStart: () ->
    @process = new SwankStarter
    @process.start()

  # Connect the to a running swank client
  swankConnect: () ->
    @tryToConnect 0

  tryToConnect: (i) ->
    if i > @maxConnectionAttempts
      atom.notifications.addWarning("Couldn't connect to Lisp!", detail:"Did you start a Lisp swank server?")
      return false
    promise = @swank.connect()
    promise.then (=> @swankConnected()), ( => setTimeout ( => @tryToConnect(i + 1)), 200)

  swankConnected: () ->
    console.log "Slime Connected!!"
    return @swank.initialize().then =>
      atom.notifications.addSuccess('Connected to Lisp!', detail:'You can now code away!')
      @views.statusView.message("Slime connected")
      @views.showRepl()


  deactivate: ->
    @subs.dispose()
    @ases.dispose()
    @views.destroy()
    @process.destroy()

  serialize: ->
    viewsState: @views.serialize()

  consumeStatusBar: (statusBar) ->
    @views.setStatusBar(statusBar)

  provideSlimeAutocomplete: -> SlimeAutocompleteProvider
