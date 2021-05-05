const elements = require.context('.', true, /\.js$/)
elements.keys().forEach(elements)
