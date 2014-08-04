class Fizzle
  @find = (selector, start) ->
    elements = []
    if selector == '*'
      elements.push start
      for child in start.childNodes when child.nodeType == Node.ELEMENT_NODE
        elements.push.apply elements, (@find selector, child)
    else if /^[a-zA-Z]+$/.test selector
      if start.tagName == selector.toUpperCase()
        elements.push start
      for child in start.childNodes when child.nodeType == Node.ELEMENT_NODE
        elements.push.apply elements, (@find selector, child)
    elements

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
