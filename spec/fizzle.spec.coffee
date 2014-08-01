describe 'Fizzle', ->
  describe 'find', ->
    container = undefined

    beforeEach ->
      if container?
        container.parentNode.removeChild container
      container = document.createElement 'div'
      container.id = "fizzle-spec-container"
      document.body.appendChild container

    examples = [
      ['*', '<div a><span b></span><span c></span></div>', 'abc']
    ]

    # the single letter attribute of the passed-in element
    getCode = (e) ->
      letters = (attr.name for attr in e.attributes when /^[a-z]$/.test attr.name)
      if letters.length > 1
        throw new Error "#{e} has more than one single-letter attribute!"
      if letters.length == 1 then letters[0] else '.'

    for example in examples
      do (example) ->
        [selector, html, expected] = example
        it selector, ->
          container.innerHTML = html
          matched = Fizzle.find '*', container
          actual = (getCode e for e in matched)
          expect(actual.join '').toEqual expected
