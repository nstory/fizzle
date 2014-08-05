class Fizzle
  constructor: ->
    @registerPseudoSelector 'first-child', (elem) ->
      elem.parentNode.firstChild == elem

  # evaluates the passed-in selector in the context of the passed-in element
  # (or against the document as a whole if no element is passed in)
  find: (selector, element=document) ->
    ast = @_parse (@_lex selector)
    @_eval ast, [element]

  # register a custom pseudo selector
  registerPseudoSelector: (name, fn) ->
    @_pseudos[name] = fn

  _pseudos: {}

  getParents = (e) ->
    if e.parentElement?
      return [e.parentElement].concat(getParents(e.parentElement))
    return []

  # evalulates the passed-in abstract syntax tree (as created by _parse)
  # in the context of the passed-in DOM elements; only elements which
  # descend from those in context will be found and returned
  _eval: (ast, context) ->
    self = this
    commands =
      # all descendant elements with this tag name
      tag: (context, tagName) ->
        ret = []
        for context_elem in context
          for elem in (context_elem.getElementsByTagName tagName)
            ret.push elem
        ret

      # filter elements to those where the specified attribute contains
      # the passed-in value; the attribute is assumed to contain a space-separated
      # list of values
      attribute_contains: (context, attr, value, elements) ->
        e for e in elements when e.hasAttribute(attr) and e.getAttribute(attr).split(' ').indexOf(value) != -1

      # filter elements to those where the specified attribute is
      # equal to the passed-in value
      attribute_equals: (context, attr, value, elements) ->
        e for e in elements when e.getAttribute(attr)==value

      # filter elements to those having the specified attribute
      has_attribute: (context, attr, elements) ->
        e for e in elements when e.hasAttribute attr

      # filter elements to those matching the pseudo selector
      pseudo: (context, pseudo_name, elements) ->
        e for e in elements when self._pseudos[pseudo_name](e)

      # filter elements to those which descend from ancestors
      descendant: (context, ancestors, elements) ->
        ret = []
        for elem in elements
          parents = getParents elem
          if (p for p in parents when ancestors.indexOf(p) != -1).length != 0
            ret.push elem
        ret

      # filter elements to those which are a child of an element
      # in parents
      child: (context, parents, elements) ->
        e for e in elements when parents.indexOf(e.parentElement) != -1

      # filter elements to those which are to the immediate right
      # of an element in lefties
      adjacent: (context, lefties, elements) ->
        e for e in elements when lefties.indexOf(e.previousSibling) != -1

    [cmd, args...] = ast
    if commands[cmd]?
      # eval any arguments to this command e.g.
      # [has_attribute foo [tag span]] -> [has_attribute foo [...list of elements...]]
      evaled_args = for arg in args
        if arg instanceof Array
          @_eval arg, context
        else
          arg
      # run the command, returning the list of elements it matches
      return commands[cmd].apply null, ([context].concat evaled_args)
    else
      throw new Error "unknown command #{cmd}"

  # creates an abstract syntax tree from the passed-in array of tokens; the tree
  # takes the form [CMD arg1 arg2] where each arg may itself be a node (array)
  # e.g. [descendant [tag H1] [tag A]] locates an A which descends from an H1
  _parse: (tokens) ->
    selector = ->
      node = simple_selector()
      while hasNext()
        if /\s+/.test next()
          consume()
          operator = 'descendant'
        else if '>' == next()
          consume()
          operator = 'child'
        else if '+' == next()
          consume()
          operator = 'adjacent'
        else
          throw new Error "unexpected token #{next()}"
        node = [operator, node, simple_selector()]
      node

    simple_selector = ->
      node = ['tag', '*']
      while true
        switch
          when !hasNext()
            return node
          when /^[a-zA-Z]|^\*$/.test next()
            node = ['tag', consume()]
          when /^:$/.test next()
            consume()
            name = consume()
            node = ['pseudo', name, node]
          when /^\.$/.test next()
            consume()
            className = consume()
            node = ['attribute_contains', 'class', className, node]
          when /^\#$/.test next()
            consume()
            id = consume()
            node = ['attribute_equals', 'id', id, node]
          when /^\[$/.test next()
            node = attribute_selector().concat [node]
          else
            return node

    attribute_selector = ->
      consumeValue = ->
        val = consume()
        val.replace /^"|"$/g, ''

      consume /^\[$/
      attribute = consume /^[a-zA-Z\-]+$/
      if ']' == next()
        consume()
        ['has_attribute', attribute]
      else if '=' == next()
        consume()
        value = consumeValue()
        consume /^\]$/
        ['attribute_equals', attribute, value]
      else if '~=' == next()
        consume()
        value = consumeValue()
        consume /^\]$/
        ['attribute_contains', attribute, value]
      else
        throw new Error "unexpected token #{tokens[idx]}"

    # helper functions
    idx = 0
    hasNext = ->
      idx < tokens.length
    next = ->
      tokens[idx]
    consume = (re) ->
      if re? and !re.test tokens[idx]
        throw new Error "unexpected token #{tokens[idx]}"
      tokens[idx++]

    selector()

  # breaks up the passed-in string into an array of "tokens" (really
  # just strings)
  _lex: (selector) ->
    re = ///^(
      \*
     |[a-zA-Z0-9\-_]+
     |:
     |\.
     |\#
     |\[
     |\]
     |=
     |~=
     |"[^"]*"
     |(\x20*(>|\+)\x20*)
     |[\x20]+
    )///
    tokens = []
    while matches = re.exec(selector)
      token = matches[0]
      # only trim the token if it contains at least some non-whitespace
      if /[^\x20]/.test token
        token = token.trim()
      tokens.push token
      selector = selector.slice matches[0].length
    if selector != ''
      throw new Error "unexpected character when tokenizing #{selector}"
    tokens

window.Fizzle = Fizzle
