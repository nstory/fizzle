describe 'Fizzle', ->
  describe 'find', ->
    examples = [
      ['*', '<div a><span b></span><span c></span></div>', 'abc']
      ['span', '<div><span b></span><span c></span></div>', 'bc']
      ['div span', '<div><span a><span b/></span></div>', 'ab']
    ]

    getCode = (e) ->
      letters = (attr.name for attr in e.attributes when /^[a-z]$/.test attr.name)
      if letters.length > 1
        throw new Error "#{e} has more than one single-letter attribute!"
      if letters.length == 1 then letters[0] else '.'

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
