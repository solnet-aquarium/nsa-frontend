gulp = require("gulp")
jade = require("gulp-jade")
gutil = require("gulp-util")
coffee = require("gulp-coffee")
concat = require("gulp-concat")
uglify = require("gulp-uglify")
plumber = require("gulp-plumber")
wrap = require("gulp-wrap")
rename = require("gulp-rename")
flatten = require('gulp-flatten')
gulpif = require('gulp-if')
minifyHTML = require("gulp-minify-html")
stylus = require('gulp-stylus')
nib = require('nib')
csslint = require("gulp-csslint")
minifyCSS = require("gulp-minify-css")
watch = require("gulp-watch")
notify = require("gulp-notify")
newer = require("gulp-newer")
cache = require("gulp-cached")
jadeInheritance = require('gulp-jade-inheritance')
sourcemaps = require('gulp-sourcemaps')
insert = require("gulp-insert")
runSequence = require('run-sequence')
lazypipe = require('lazypipe')
rimraf = require('rimraf')

mainStylus = require("./main-stylus").files

paths = {}
paths.app = "app/"
paths.dist = "../public/"
paths.tmp = "tmp/"
paths.tmpStyles = paths.tmp + "styles/"
paths.tmpStylesExtras = "#{paths.tmpStyles}/taiga-front-extras/**/*.css"
paths.extras = "extras/"

paths.jade = [
    paths.app + "index.jade",
    paths.app + "partials/**/*.jade",
    paths.app + "plugins/**/*.jade"
]

paths.images = paths.app + "images/**/*"
paths.svg = paths.app + "svg/**/*"
paths.css = paths.app + "styles/vendor/*.css"
paths.locales = paths.app + "locales/**/*.json"
paths.stylus = [
    "#{paths.app}/styles/**/*.stylus",
    "#{paths.app}/plugins/**/*.stylus"
  ]

paths.coffee = [
    paths.app + "coffee/app.coffee",
    paths.app + "coffee/*.coffee",
    paths.app + "coffee/modules/controllerMixins.coffee",
    paths.app + "plugins/**/*.coffee"
  ]

paths.js = []

isDeploy = process.argv[process.argv.length - 1] == 'deploy'

##############################################################################
# Layout/CSS Related tasks
##############################################################################

gulp.task "jade-deploy", ->
  gulp.src(paths.jade)
        .pipe(plumber())
        .pipe(cache("jade"))
        .pipe(jade({pretty: false}))
        .pipe(gulp.dest(paths.dist + "partials/"))

gulp.task "jade-watch", ->
  gulp.src(paths.jade)
        .pipe(plumber())
        .pipe(cache("jade"))
        .pipe(jadeInheritance({basedir: "./app"}))
        .pipe(jade({pretty: true}))
        .pipe(gulp.dest(paths.dist))

gulp.task "templates", ->
  gulp.src(paths.app + "index.jade")
        .pipe(plumber())
        .pipe(jade({pretty: true, locals:{v:(new Date()).getTime()}}))
        .pipe(gulp.dest(paths.dist))

##############################################################################
# CSS Related tasks
##############################################################################


gulp.task "stylus-compile", ->
  gulp.src(paths.stylus)
        .pipe(plumber())
        .pipe(cache("stylus"))
        .pipe(stylus({
  sourcemap: {
    inline: true,
    sourceRoot: '..',
    basePath: 'css'
  }
  use: nib(),
  import: ['./node_modules/fluidity/index.styl'],
  compress: true
  }))
  .pipe(gulp.dest(paths.tmpStyles))

csslintChannel = lazypipe()
  .pipe(csslint, "csslintrc.json")
  .pipe(csslint.reporter)

gulp.task "css-lint-app", ->
  gulp.src(mainStylus.concat([paths.tmpStylesExtras]))
        .pipe(cache("csslint"))
        .pipe(gulpif(!isDeploy, csslintChannel()))

gulp.task "css-join", ["css-lint-app"], ->
  gulp.src(mainStylus.concat([paths.tmpStylesExtras]))
        .pipe(concat("app.css"))
        .pipe(gulp.dest(paths.tmp))

gulp.task "css-app", (cb) ->
  runSequence("stylus-compile", "css-join", cb)

gulp.task "css-vendor", ->
  gulp.src(paths.css)
        .pipe(concat("vendor.css"))
        .pipe(gulp.dest(paths.tmp))

gulp.task "delete-tmp-styles", (cb) ->
  rimraf(paths.tmpStyles, cb)

gulp.task "styles-watch", ["css-app", "css-vendor"], ->
  _paths = [
        paths.tmp + "vendor.css",
        paths.tmp + "app.css"
    ]

  gulp.src(_paths)
        .pipe(concat("main.css"))
        .pipe(gulpif(isDeploy, minifyCSS()))
        .pipe(gulp.dest(paths.dist + "styles/"))

gulp.task "styles", ["delete-tmp-styles"], ->
  gulp.start("styles-watch")

##############################################################################
# JS Related tasks
##############################################################################

gulp.task "conf", ->
  gulp.src("conf/main.json")
        .pipe(wrap("angular.module('taigaBase').value('localconf', <%= contents %>);"))
        .pipe(concat("conf.js"))
        .pipe(gulp.dest(paths.tmp))

gulp.task "locales", ->
  gulp.src("app/locales/en/app.json")
        .pipe(wrap("angular.module('taigaBase').value('localesEn', <%= contents %>);"))
        .pipe(rename("locales.en.js"))
        .pipe(gulp.dest(paths.tmp))

gulp.task "coffee", ->
  gulp.src(paths.coffee)
        .pipe(plumber())
        .pipe(coffee())
        .pipe(concat("app.js"))
        .pipe(gulp.dest(paths.tmp))

gulp.task "jslibs-watch", ->
  gulp.src(paths.js)
        .pipe(plumber())
        .pipe(concat("libs.js"))
        .pipe(gulp.dest("dist/js/"))

gulp.task "jslibs-deploy", ->
  gulp.src(paths.js)
        .pipe(plumber())
        .pipe(sourcemaps.init())
        .pipe(concat("libs.js"))
        .pipe(uglify({mangle:false, preserveComments: false}))
        .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest("dist/js/"))

gulp.task "app-watch", ["coffee", "conf", "locales"], ->
  _paths = [
        paths.tmp + "app.js",
        paths.tmp + "conf.js",
        paths.tmp + "locales.en.js"
    ]

  gulp.src(_paths)
        .pipe(concat("app.js"))
        .pipe(gulp.dest(paths.dist + "js/"))

gulp.task "app-deploy", ["coffee", "conf", "locales"], ->
  _paths = [
        paths.tmp + "app.js",
        paths.tmp + "conf.js",
        paths.tmp + "locales.en.js"
  ]

  gulp.src(_paths)
        .pipe(sourcemaps.init())
            .pipe(concat("app.js"))
            .pipe(uglify({mangle:false, preserveComments: false}))
        .pipe(sourcemaps.write('./'))
        .pipe(gulp.dest(paths.dist + "js/"))

##############################################################################
# Common tasks
##############################################################################

# SVG
gulp.task "copy-svg",  ->
  gulp.src("#{paths.app}/svg/**/*")
        .pipe(gulp.dest("#{paths.dist}/svg/"))

gulp.task "copy-fonts",  ->
  gulp.src("#{paths.app}/fonts/*")
        .pipe(gulp.dest("#{paths.dist}/fonts/"))

gulp.task "copy-images",  ->
  gulp.src("#{paths.app}/images/**/*")
        .pipe(gulp.dest("#{paths.dist}/images/"))

  gulp.src("#{paths.app}/plugins/**/images/*")
        .pipe(flatten())
        .pipe(gulp.dest("#{paths.dist}/images/"))

gulp.task "copy-plugin-templates",  ->
  gulp.src("#{paths.app}/plugins/**/templates/*")
        .pipe(gulp.dest("#{paths.dist}/plugins/"))

gulp.task "copy-extras", ->
  gulp.src("#{paths.extras}/*")
        .pipe(gulp.dest("#{paths.dist}/"))


gulp.task "copy", ["copy-fonts", "copy-images", "copy-plugin-templates", "copy-svg", "copy-extras"]

gulp.task "express", ->
    express = require("express")
    app = express()

    app.use("/js", express.static("#{__dirname}/dist/js"))
    app.use("/styles", express.static("#{__dirname}/dist/styles"))
    app.use("/images", express.static("#{__dirname}/dist/images"))
    app.use("/svg", express.static("#{__dirname}/dist/svg"))
    app.use("/partials", express.static("#{__dirname}/dist/partials"))
    app.use("/fonts", express.static("#{__dirname}/dist/fonts"))
    app.use("/plugins", express.static("#{__dirname}/dist/plugins"))

    app.all "/*", (req, res, next) ->
        # Just send the index.html for other files to support HTML5Mode
        res.sendFile("index.html", {root: "#{__dirname}/dist/"})

    app.listen(9001)

# Rerun the task when a file changes
gulp.task "watch", ->
    gulp.watch(paths.jade, ["jade-watch"])
    gulp.watch(paths.app + "index.jade", ["templates"])
    gulp.watch(paths.sass, ["styles-watch"])
    gulp.watch(paths.svg, ["copy-svg"])
    gulp.watch(paths.coffee, ["app-watch"])
    gulp.watch(paths.js, ["jslibs-watch"])
    gulp.watch(paths.locales, ["app-watch"])
    gulp.watch(paths.images, ["copy-images"])
    gulp.watch(paths.fonts, ["copy-fonts"])


gulp.task "deploy", [
    "delete-tmp-styles",
    "templates",
    "copy",
    "jade-deploy",
    "app-deploy",
    "jslibs-deploy",
    "styles"
]

# The default task (called when you run gulp from cli)
gulp.task "default", [
    "delete-tmp-styles",
    "copy",
    "templates",
    "styles",
    "app-watch",
    "jslibs-watch",
    "jade-deploy",
    "express",
    "watch"
]
