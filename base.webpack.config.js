// Base webpack configuration that can be shared amongst packages.
//
// Provide the ability to bundle typescript and es-latest authored source code
// into es5 code. Also handles minification, when appropriate.
//
// Exports a function that can be called with more configuration options.
// Those options will be merged with `baseConfig`, and the result will be
// returned.

var path = require('path');
var webpack = require('webpack');
var webpackMerge = require('webpack-merge');
var MiniCssExtractPlugin = require('mini-css-extract-plugin');
var projectHome = path.resolve(__dirname, '../..');
var devtoolPathPrefixRe = new RegExp('^' + projectHome + '/');

/**
 * Creates a configuration function that is used by webpack. Takes a
 * configuration object, or an array of configuration objects, and merges them
 * with the base configuration object provided by WDK.
 *
 * For details, see https://webpack.js.org/configuration/.
 *
 * @param {object|object[]} additionalConfig
 */
exports.merge = function merge(additionConfig) {
  return function (env, argv) {
    var isDevelopment = argv.mode !== 'production';
    return webpackMerge.smart([{
      bail: true,
      context: process.cwd(),
      resolve: {
        extensions: [ ".js", ".jsx", ".ts", ".tsx" ],
        modules: [ path.join(process.cwd(), 'node_modules'), path.join(__dirname, 'node_modules') ]
      },
      output: {
        path: path.join(process.cwd(), 'dist'),
        filename: '[name].bundle.js',
        chunkFilename: '[name].bundle-[chunkhash].js',
        devtoolModuleFilenameTemplate: function(info) {
          // strip prefix from absolute path
          return 'webpack:///' + info.absoluteResourcePath.replace(devtoolPathPrefixRe, './');
        },
        hashDigestLength: 20
      },
      module: {
        rules: [

          // handle typescript source. reads `tsconfig.json` in cwd
          {
            test: /\.tsx?$/,
            exclude: /node_modules/,
            use: [
              { loader: 'babel-loader', options: { configFile: path.join(process.cwd(), '.babelrc') } },
              { loader: 'ts-loader' }
            ]
          },

          // handle es source. reads `.babelrc` in cwd
          {
            test: /\.jsx?$/,
            exclude: /node_modules/,
            use: [
              { loader: 'babel-loader', options: { configFile: path.join(process.cwd(), '.babelrc') } }
            ]
          },

          {
            test: /\.scss$/,
            use: [
              { loader: MiniCssExtractPlugin.loader },
              { loader: 'css-loader', options: { sourceMap: true } },
              { loader: 'sass-loader', options: { sourceMap: true } }
            ]
          },

          {
            test: /\.css$/,
            use: [
              { loader: MiniCssExtractPlugin.loader },
              { loader: 'css-loader', options: { sourceMap: true } }
            ]
          },

          // inlines images as base64
          {
            test: /\.(png|jpg|gif|svg|eot|ttf|woff|woff2)$/,
            loader: 'url-loader',
            options: { limit: 100000 }
          },

        ]
      },
      resolveLoader: {
        modules: [ 'node_modules', path.join(__dirname, 'node_modules') ]
      },
      devtool: 'source-map',
      plugins: [
        new webpack.optimize.ModuleConcatenationPlugin(),
        new webpack.LoaderOptionsPlugin({ debug: isDevelopment }),
        new webpack.DefinePlugin({
          __DEV__: JSON.stringify(isDevelopment),
          // "process.env": {
          //   NODE_ENV: JSON.stringify(isDevelopment ? "development" : "production")
          // }
        }),
        // isDevelopment ? noop : new webpack.optimize.UglifyJsPlugin({ sourceMap: true }),
        new MiniCssExtractPlugin({
          filename: '[name].bundle.css'
        })
      ],
      stats: {
        maxModules: Infinity,
        optimizationBailout: true
      }
    }].concat(additionConfig));
  }
}

// expose webpack in case consumers want to add more plugins
exports.webpack = webpack;

/** no nothing */
function noop(){}
