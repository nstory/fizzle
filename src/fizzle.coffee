class Fizzle
  @find = (selector, element) ->
    ast = @_parse (@_lex selector)
    @_eval ast, [element]

  @pseudos =
    'first-child': (elem) ->
      elem.parentNode.firstChild == elem

  @_eval = (ast, context) ->
    [cmd, args...] = ast
    if 'tag' == cmd
      [tagName] = args
      ret = []
      for context_elem in context
        for elem in (context_elem.getElementsByTagName tagName)
          ret.push elem
      ret
    else if 'attribute_contains' == cmd
      [attr, value, sub_select] = args
      elements = (@_eval sub_select, context)
      ret = []
      for elem in elements
        if elem.hasAttribute(attr)
          if elem.getAttribute(attr).split(' ').indexOf(value) != -1
            ret.push elem
      ret
    else if 'attribute_equals' == cmd
      [attr, value, sub_select] = args
      elements = (@_eval sub_select, context)
      ret = []
      for elem in elements
        if elem.getAttribute(attr) == value
          ret.push elem
      ret
    else if 'has_attribute' == cmd
      [attr, sub_select] = args
      elements = (@_eval sub_select, context)
      (elem for elem in elements when elem.hasAttribute(attr))
    else if 'pseudo' == cmd
      [name, sub_select] = args
      elements = (@_eval sub_select, context)
      if !@pseudos[name]?
        throw new Error "unknown pseudo selector \"#{name}\""
      (elem for elem in elements when @pseudos[name](elem))
    else if 'descendant' == cmd
      [parent_query, desc_query] = args
      (@_eval desc_query, (@_eval parent_query, context))
    else if 'child' == cmd
      [parent_query, child_query] = args
      parent_elements = (@_eval parent_query, context)
      desc_elements = (@_eval child_query, parent_elements)
      elem for elem in desc_elements when parent_elements.indexOf(elem.parentNode) != -1
    else if 'adjacent' == cmd
      [left_query, right_query] = args
      left_elements = (@_eval left_query, context)
      right_elements = (@_eval right_query, context)
      elem for elem in right_elements when left_elements.indexOf(elem.previousSibling) != -1
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
