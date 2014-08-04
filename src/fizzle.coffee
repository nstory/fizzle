class Fizzle
  @find = (selector, context) ->
    ast = @_parse (@_lex selector)
    @_eval ast, context

  @_eval = (ast, context) ->
    [cmd, args...] = ast
    if /^([a-zA-Z0-9\-]+|\*)$/.test cmd
      context.getElementsByTagName cmd
    else if /^\./.test cmd
      className = cmd.slice 1
      (elem for elem in (@_eval args[0], context) when elem.className.split(' ').indexOf(className) != -1)
    else if /^#/.test cmd
      id = cmd.slice 1
      (elem for elem in (@_eval args[0], context) when elem.id == id)
    else if /^:first-child$/.test cmd
      (elem for elem in (@_eval args[0], context) when elem.parentNode.firstChild == elem)
    else if /^\[\]$/.test cmd
      attribute = args[0]
      unfiltered = (@_eval args[1], context)
      (elem for elem in unfiltered when elem.hasAttribute(attribute))
    else
      throw new Error "unknown command #{cmd}"

  # creates an abstract syntax tree from the passed-in array of tokens
  @_parse = (tokens) ->
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
      consume /^\[$/
      attribute = consume /^[a-zA-Z\-]+$/
      if ']' == next()
        consume()
        ['has_attribute', attribute]
      else if '=' == next()
        consume()
        value = consume()
        consume /^\]$/
        ['attribute_equals', attribute, value]
      else if '~=' == next()
        consume()
        value = consume()
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
  @_lex = (selector) ->
    re = ///^(
      \*
     |[a-zA-Z0-9\-]+
     |:
     |\.
     |\#
     |\[
     |\]
     |=
     |~=
     |"[^"]*"
     |[\x20]+
     |>
     |\+
    )///
    tokens = []
    while matches = re.exec(selector)
      tokens.push matches[0]
      selector = selector.slice matches[0].length
    if selector != ''
      throw new Error "unexpected character when tokenizing #{selector}"
    tokens

window.Fizzle = Fizzle
