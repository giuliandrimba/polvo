stylus = require 'stylus'
nib = require 'nib'
path = require 'path'

{log,debug,warn,error} = require './../utils/log-util'

module.exports = class Stylus

  @POLVO = null
  @NAME = 'stylus'
  @TYPE = 'style'
  @EXT = /(\.styl)$/m

  AMD_WRAPPER = """
  // Compiled by Polvo, using Stylus
  define(['require', 'exports', 'module'], function(require, exports, module){

    var head = document.getElementsByTagName('head')[0];
    var style = module.exports = document.createElement('style');
    var content = '~css'

    style.setAttribute('id', '~id');
    style.setAttribute('type', 'text/css');

    // MODERN BROWSERS?
    try
    { 
      style.appendChild(document.createTextNode(content));

    // IE8? (weird things happens without this on IEs)
    } catch( e )
    {
      style.styleSheet.cssText = content; // IE8
    }

    head.insertBefore(style, head.lastChild);
    return style;
  });"""

  @compile = ( file, after_compile, compile_dependents )->

    # files starting with a `_` is handled as partials and ignored by default,
    # so in this cases we search for files that imports this partial and compile
    # all of them it instead of the partial itself
    if /^_/m.test file.name
      if compile_dependents
        @compile_dependents file
      return

    # otherwise, if file is not a partial, goes on and compile it normally
    stylus( file.raw )
      .set( 'filename', file.absolute_path )
      .use( nib() )
      .import( 'nib' )
      .render (err, css)=>
        return error err if err?

        # remove line breaks and escapes double quotes
        clean = css.replace /\n|\r/g, ''
        style = clean.replace /"/g, '\\"'

        wrapped = AMD_WRAPPER.replace '~css', style
        wrapped = wrapped.replace /~id/g, file.id
        after_compile wrapped

  @translate_ext = ( filepath )->
    return filepath.replace @EXT, '.js'

  @strip_ext:( filepath )->
    return filepath.replace @EXT, ''

  @compile_dependents:( file )->

    # collect all files
    files = []
    for tentacle in @POLVO.tentacles
      for tree in tentacle.trees
        files = files.concat tree.files

    # loop through them
    has_import_reg = /^\s*(?!\/\/)@import\s/m

    for f in files

      # ignores also files that has different types
      continue if f.type isnt @TYPE

      # ignores also files that doesn't import anything
      continue unless has_import_reg.test f.raw

      # loop through all found imports on file
      all_import_reg = /^\s*(?!\/\/)@import\s+(?:"|')(\S+)(?:"|')/mg
      while (match = all_import_reg.exec f.raw)?

        # translate paths (relative -> absolute)
        import_path = match[1]
        import_dir = path.dirname import_path
        import_file = path.basename import_path

        parent_dir_parts = (path.dirname f.absolute_path).split '/'
        import_dir_parts = import_dir.split '/'

        while (part = import_dir_parts[0]) is '..'
          do import_dir_parts.shift
          do parent_dir_parts.pop

        abs_path = path.normalize [
          parent_dir_parts.join '/'
          import_dir_parts.join '/'
          import_file
        ].join '/'

        # compile current file (f) if it depends on changed file (file)
        if "#{abs_path}.styl" is file.absolute_path
          
          # if file in question is another partial, recursively walk it up
          # compiling everything from backwards passing compile_dependents=true,
          # otherwise if file isn't another partial (starting with '_', just
          # compiles it normally passing compile_dependents=false
          compile_dependents = /^_/m.test f.name
          f.compile_to_disk compile_dependents