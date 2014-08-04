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

  @_parse = (tokens) ->
    selector = ->
      node = simple_selector()
      while hasNext()
        if /\s+/.test next()
          consume()
          operator = ' '
        else if /^(>|\+)$/.test next()
          operator = consume()
        else
          throw new Error "unexpected token #{next()}"
        node = [operator, node, simple_selector()]
      node

    simple_selector = ->
      node = ['*']
      while true
        switch
          when !hasNext()
            return node
          when /^[a-zA-Z]|^\*$/.test next()
            node = [consume()]
          when /^:first-child$/.test next()
            node = [consume(), node]
          when /^\[$/.test next()
            node = attribute_selector().concat [node]
          when /^\.|^#/.test next()
            node = [consume(), node]
          else
            return node

    attribute_selector = ->
      consume /^\[$/
      attribute = consume /^[a-zA-Z\-]+$/
      if ']' == next()
        consume()
        ['[]', attribute]
      else if /^(=|~=)$/.test next()
        operator = consume()
        value = consume()
        consume /^\]$/
        ['[' + operator + ']', attribute, value]
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

  @_lex = (selector) ->
    re = ///^(
      \*
     |[a-zA-Z0-9\-]+
     |:first-child
     |\[
     |\]
     |=
     |~=
     |"[^"]*"
     |\#[a-zA-Z\-]+
     |\.[a-zA-Z\-]+
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
