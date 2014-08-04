describe 'Fizzle', ->
  describe 'lex', ->
    examples =
      # simple selectors
      '*': ['*']
      'p': ['p']
      'h1': ['h1']
      'p:first-child': ['p', ':', 'first-child']
      'p[data-xyzzy]': ['p', '[', 'data-xyzzy', ']']
      'p[foo="bar"]': ['p', '[', 'foo', '=', '"bar"', ']']
      'p[foo~="bar"]': ['p', '[', 'foo', '~=', '"bar"', ']']
      'p.foo': ['p', '.', 'foo']
      'p#foo': ['p', '#', 'foo']
      'p%': 'throws'

      # combining selectors
      'p span': ['p', ' ', 'span']
      'p > foo': ['p', '>', 'foo']
      'p + foo': ['p', '+', 'foo']

    for selector, tokens of examples
      do (tokens, selector) ->
        it selector, ->
          if tokens == 'throws'
            expect(-> (new Fizzle())._lex selector).toThrow()
          else
            expect((new Fizzle())._lex selector).toEqual tokens

  describe 'parse', ->
    examples = [
      # simple selectors
      [['*'], ['tag', '*']]
      [['span'], ['tag', 'span']]
      [['span', ':', 'first-child'], ['pseudo', 'first-child', ['tag', 'span']]]

      # attribute selectors
      [['span', '[', 'foo', ']'], ['has_attribute', 'foo', ['tag', 'span']]]
      [['span', '[', 'foo', '=', '"bar"', ']'], ['attribute_equals', 'foo', 'bar', ['tag', 'span']]]
      [['span', '[', 'foo', '~=', '"bar"', ']'], ['attribute_contains', 'foo', 'bar', ['tag', 'span']]]

      # attribute selector with unquoted value
      [['span', '[', 'foo', '=', 'bar', ']'], ['attribute_equals', 'foo', 'bar', ['tag', 'span']]]

      # class and ID selectors
      [['span', '.', 'foo'], ['attribute_contains', 'class', 'foo', ['tag', 'span']]]
      [['span', '#', 'foo'], ['attribute_equals', 'id', 'foo', ['tag', 'span']]]

      # class and ID selectors with implicit element selector
      [['.', 'foo'], ['attribute_contains', 'class', 'foo', ['tag', '*']]]
      [['#', 'foo'], ['attribute_equals', 'id', 'foo', ['tag', '*']]]

      # non-simple selectors
      [['p', ' ', 'span'], ['descendant', ['tag', 'p'], ['tag', 'span']]]
      [['p', ' ', 'span', ' ', 'i'], ['descendant', ['descendant', ['tag', 'p'], ['tag', 'span']], ['tag', 'i']]]
      [['p', '>', 'span'], ['child', ['tag', 'p'], ['tag', 'span']]]
      [['p', ' ', 'span', '>', 'i'], ['child', ['descendant', ['tag', 'p'], ['tag', 'span']], ['tag', 'i']]]
      [['p', '+', 'span'], ['adjacent', ['tag', 'p'], ['tag', 'span']]]
    ]

    for example in examples
      do (example) ->
        [tokens, tree] = example
        it JSON.stringify(tokens), ->
          expect((new Fizzle)._parse tokens).toEqual tree

  describe 'find', ->
    examples = [
      ['*', '<span b></span><span c></span>', 'bc']
      ['span', '<span b></span><span c></span>', 'bc']
      ['span.foo', '<span></span><span class="foo" c></span>', 'c']
      ['span#foo', '<span a id="foo"></span><span></span>', 'a']
      ['span:first-child', '<span a></span><span></span>', 'a']
      ['span[foo]', '<span foo a></span><span></span>', 'a']
      ['span[foo=bar]', '<span foo="bar" a></span><span foo="baz"></span>', 'a']
      ['span.foo.bar', '<span class="foo"></span><span class="bar foo" c></span>', 'c']
      ['span span', '<span a><span b></span></span>', 'b']
      ['span>i', '<span a><i b><i c></i></i></span>', 'b']
      ['span > i', '<span a><i b><i c></i></i></span>', 'b']
      ['span+i', '<span></span><i a></i><i></i>', 'a']
      ['span + i', '<span></span><i a></i><i></i>', 'a']
    ]

    # the single-letter attribute present on the passed-in element
    getCode = (e) ->
      letters = (attr.name for attr in e.attributes when /^[a-z]$/.test attr.name)
      if letters.length > 1
        throw new Error "#{e} has more than one single-letter attribute!"
      if letters.length == 1 then letters[0] else '.'

    # create a new <div> element containing the passed-in HTML
    elementFromHtml = (html) ->
      container = document.createElement 'div'
      container.innerHTML = html
      container

    for example in examples
      do (example) ->
        [selector, html, expected] = example
        it selector, ->
          element = elementFromHtml html
          matched = (new Fizzle).find selector, element
          actual = (getCode e for e in matched)
          expect(actual.join '').toEqual expected
