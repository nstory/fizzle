# Fizzle
A toy implementation of CSS selectors in [CoffeeScript](http://coffeescript.org). Written just for fun. Don't use this in any project. Use [Sizzle](http://sizzlejs.com/) if you want something like this, or [document.querySelectorAll](https://developer.mozilla.org/en-US/docs/Web/API/Document.querySelectorAll).

## Usage
```coffeescript
fizzle = new Fizzle()
links = fizzle.find 'ul.menu a'
```

## See Also
I used this spec to guide my implementation: [CSS 2.1 Selectors](http://www.w3.org/TR/CSS2/selector.html).
