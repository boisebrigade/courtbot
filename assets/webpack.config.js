const CopyWebpackPlugin = require('copy-webpack-plugin')

const path = require('path')

const outputDir = path.join(__dirname, "../priv/static/")
const isProd = process.env.NODE_ENV === 'production'

module.exports = {
  entry: './src/Index.bs.js',
  mode: isProd ? 'production' : 'development',
  output: {
    path: outputDir,
    publicPath: outputDir,
    filename: 'index.js',
  },
  plugins: [
    new CopyWebpackPlugin([
      { from: 'static/*', to: outputDir, flatten: true },
    ], {})
  ]
}
