# Contains various useful Slime-related functions
module.exports =

  # Given an an abstract syntax tree,
  # parse out the package name!
  getPackage: (ast) ->
    if ast.errors?.length == 0
      for obj in ast.children
        if obj.errors?.length == 0 and obj?.type == "list" and
            obj?.children.length >= 2 and obj?.children[0]?.source?.toLowerCase() == "in-package"
          # Find the first children that's a symbol and return that
          for m in obj.children[1..]
            if m.type == "symbol"
              return m.source.replace(':', '')
    # If we didn't find anything, return default
    return "CL-USER"


  # Given an AST and the cursor index,
  # which top level form are we in?
  getTopLevelForm: (ast, index) ->
    node = (s for s in ast.children when index >= s.start and index <= s.end)[0] if ast.children
    return node
