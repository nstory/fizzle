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

window.Fizzle = Fizzle
