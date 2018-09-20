using BinDeps
using Compat

@BinDeps.setup

# e.g. ENV["MECABJL_LIBRARY_IGNORE_PATH"] = "/usr/lib:/usr/local/lib"
ignore_paths = split(strip(get(ENV, "MECABJL_LIBRARY_IGNORE_PATH", "")), ':')

validate = function(libpath, handle)
    for path in ignore_paths
        isempty(path) && continue
        ismatch(Regex("^$(path)"), libpath) && return false
    end
    return true
end

mecab = library_dependency("libmecab", validate=validate)

version = "0.996"

provides(Sources,
         URI("https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"),
         mecab,
         unpacked_dir="mecab-$(version)",
         filename="mecab-$(version).tar.gz")

prefix = joinpath(BinDeps.depsdir(mecab), "usr")
srcdir = joinpath(BinDeps.depsdir(mecab), "src", "mecab-$(version)")

provides(SimpleBuild,
          (@build_steps begin
              GetSources(mecab)
              @build_steps begin
                  ChangeDirectory(srcdir)
                  `./configure --prefix=$prefix --enable-utf8-only`
                  `make`
                  `make install`
              end
           end), mecab, os = :Unix)

@BinDeps.install @compat Dict(:libmecab => :libmecab)

# mecab-ipadic install

function install_ipadic()
    ipadic_version = "2.7.0-20070801"
    mecabconfig = joinpath(BinDeps.depsdir(mecab), "usr", "bin", "mecab-config")

    # download
    url = "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
    cd(BinDeps.downloadsdir(mecab))
    filename = "mecab-ipadic-$(ipadic_version).tar.gz"
    if !isfile(joinpath(BinDeps.downloadsdir(mecab), filename))
        run(download_cmd(url, filename))
    end

    # unpack
    unpack_dir = "mecab-ipadic-$(ipadic_version)"
    if !isdir(unpack_dir)
        run(`tar xzvf $(filename)`)
    end
    cd("$(unpack_dir)")

    # make & install
    run(`./configure --prefix=$prefix --with-charset=utf8 --with-mecab-config=$(mecabconfig)`)
    run(`make`)
    run(`make install`)
end

mecablib_dir = joinpath(BinDeps.depsdir(mecab), "usr", "lib")
ipadic_expected_dir = joinpath(mecablib_dir, "mecab", "dic", "ipadic")
if isdir(mecablib_dir) && !isdir(ipadic_expected_dir)
    @static if Sys.isunix()
      install_ipadic()
    end
end
