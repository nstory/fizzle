describe 'Fizzle', ->
  describe 'lex', ->
    examples =
      # simple selectors
      '*': ['*']
      'p': ['p']
      'h1': ['h1']
      'p:first-child': ['p', ':first-child']
      'p[data-xyzzy]': ['p', '[', 'data-xyzzy', ']']
      'p[foo="bar"]': ['p', '[', 'foo', '=', '"bar"', ']']
      'p[foo~="bar"]': ['p', '[', 'foo', '~=', '"bar"', ']']
      'p.foo': ['p', '.foo']
      'p#foo': ['p', '#foo']
      'p%': 'throws'

      # combining selectors
      'p span': ['p', ' ', 'span']
      'p > span': ['p', ' ', '>', ' ', 'span']
      'p + span': ['p', ' ', '+', ' ', 'span']

    for selector, tokens of examples
      do (tokens, selector) ->
        it selector, ->
          if tokens == 'throws'
            expect(-> Fizzle._lex selector).toThrow()
          else
            expect(Fizzle._lex selector).toEqual tokens

  describe 'parse', ->
    examples = [
      # simple selectors
      [['*'], ['*']]
      [['span'], ['span']]
      [['span', ':first-child'], [':first-child', ['span']]]

      # attribute selectors
      [['span', '[', 'foo', ']'], ['[]', 'foo', ['span']]]
      [['span', '[', 'foo', '=', '"bar"', ']'], ['[=]', 'foo', '"bar"', ['span']]]
      [['span', '[', 'foo', '~=', '"bar"', ']'], ['[~=]', 'foo', '"bar"', ['span']]]

      # attribute selector with unquoted value
      [['span', '[', 'foo', '=', 'bar', ']'], ['[=]', 'foo', 'bar', ['span']]]

      # class and ID selectors
      [['span', '.foo'], ['.foo', ['span']]]
      [['span', '#foo'], ['#foo', ['span']]]

      # class and ID selectors with implicit element selector
      [['.foo'], ['.foo', ['*']]]
      [['#foo'], ['#foo', ['*']]]

      # non-simple selectors
      [['p', ' ', 'span'], [' ', ['p'], ['span']]]
      [['p', ' ', 'span', ' ', 'i'], [' ', [' ', ['p'], ['span']], ['i']]]
      [['p', '>', 'span'], ['>', ['p'], ['span']]]
      [['p', ' ', 'span', '>', 'i'], ['>', [' ', ['p'], ['span']], ['i']]]
      [['p', '+', 'span'], ['+', ['p'], ['span']]]
    ]

    for example in examples
      do (example) ->
        [tokens, tree] = example
        it JSON.stringify(tokens), ->
          expect(Fizzle._parse tokens).toEqual tree

  describe 'find', ->
    examples = [
      ['*', '<div a><span b></span><span c></span></div>', 'abc']
      ['span', '<div><span b></span><span c></span></div>', 'bc']
      ['span.foo', '<div><span></span><span class="foo" c></span></div>', 'c']
      ['span#foo', '<div><span a id="foo"></span><span></span></div>', 'a']
      ['span:first-child', '<div><span a></span><span></span></div>', 'a']
      ['span[foo]', '<div><span foo a></span><span></span></div>', 'a']
      ['span[foo=bar]', '<div><span foo="bar" a></span><span foo="baz"></span></div>', 'a']
    ]

    # the single-letter attribute present on the passed-in element
    getCode = (e) ->
      letters = (attr.name for attr in e.attributes when /^[a-z]$/.test attr.name)
      if letters.length > 1
        throw new Error "#{e} has more than one single-letter attribute!"
      if letters.length == 1 then letters[0] else '.'

    # converts an HTML string into an element (and children); the HTML
    # string must contain a single parent element
    elementFromHtml = (html) ->
      container = document.createElement 'div'
      container.innerHTML = html
      if container.childNodes.length != 1
        throw new Error "unexpected number of child nodes"
      container.childNodes[0]

    for example in examples
      do (example) ->
        [selector, html, expected] = example
        it selector, ->
          element = elementFromHtml html
          matched = Fizzle.find selector, element
          actual = (getCode e for e in matched)
          expect(actual.join '').toEqual expected
