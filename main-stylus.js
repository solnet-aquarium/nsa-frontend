exports.files = function () {
    var base = process.cwd() + "/tmp/styles/";
    // include stylus styles here
    var files  = [
      base + 'boot'
    ];

    files = files.map(function (file) {
        return base + file + ".css";
    });

    return files;
}();
